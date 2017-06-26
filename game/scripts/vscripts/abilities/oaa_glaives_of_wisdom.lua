LinkLuaModifier("modifier_oaa_glaives_of_wisdom", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)

oaa_glaives_of_wisdom = class(AbilityBaseClass)

function oaa_glaives_of_wisdom:GetIntrinsicModifierName()
  return "modifier_oaa_glaives_of_wisdom"
end

function oaa_glaives_of_wisdom:GetAbilityTargetFlags()
  local defaultFlags = self.BaseClass.GetAbilityTargetFlags(self)
  local caster = self:GetCaster()
  if caster:HasScepter() then
    return bit.bor(defaultFlags, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
  else
    return defaultFlags
  end
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom:IsPurgable()
  return false
end

function modifier_oaa_glaives_of_wisdom:RemoveOnDeath()
  return false
end

function modifier_oaa_glaives_of_wisdom:OnCreated()
  if IsServer() then
    if not self.procRecords then
      self.procRecords = {}
    end
    self.parentOriginalProjectile = self:GetParent():GetRangedProjectileName()
    Debug.EnabledModules["abilities:oaa_glaives_of_wisdom"] = true
  end
end

modifier_oaa_glaives_of_wisdom.OnRefresh = modifier_oaa_glaives_of_wisdom.OnCreated

function modifier_oaa_glaives_of_wisdom:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK_FINISHED
  }
end

function modifier_oaa_glaives_of_wisdom:OnAttackStart(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if keys.attacker == parent and (keys.gain == 0 or ability:GetAutoCastState()) and ability:IsOwnersManaEnough() then
    -- Set projectile
    parent:SetRangedProjectileName("particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf")
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFinished(keys)
  local parent = self:GetParent()
  if keys.attacker == parent then
    parent:SetRangedProjectileName(self.parentOriginalProjectile)
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttack(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  -- keys.gain ~= keys.gain is to check if it is NaN which seems to always be the case when
  -- an attack modifier ability is cast manually
  if keys.attacker == parent and (keys.gain ~= keys.gain or ability:GetAutoCastState()) and ability:IsOwnersManaEnough() then
    -- Enable proc for this attack record number
    self.procRecords[keys.record] = true
    -- Using attack modifier abilities doesn't actually fire any cast events so we have to spend the mana here
    ability:PayManaCost()
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackLanded(keys)
  local parent = self:GetParent()
  if keys.attacker == parent and self.procRecords[keys.record] then
    local ability = self:GetAbility()
    local bonusDamage = parent:GetIntellect() * ability:GetSpecialValueFor("intellect_damage_pct") / 100
    local player = parent:GetPlayerOwner()

    if parent:HasScepter() and keys.target:IsSilenced() then
      bonusDamage = bonusDamage * ability:GetSpecialValueFor("scepter_damage_multiplier")
    end

    local damageTable = {
      victim = keys.target,
      attacker = parent,
      damage = bonusDamage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability
    }
    ApplyDamage(damageTable)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, bonusDamage, player)
    EmitSoundOn("Hero_Silencer.GlaivesOfWisdom.Damage", keys.target)
    self.procRecords[keys.record] = nil
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFail(keys)
  local parent = self:GetParent()
  if keys.attacker == parent and self.procRecords[keys.record] then
    self.procRecords[keys.record] = nil
  end
end
