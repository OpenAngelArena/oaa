LinkLuaModifier("modifier_oaa_glaives_of_wisdom", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_of_wisdom_fx", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)

silencer_glaives_of_wisdom_oaa = class(AbilityBaseClass)

function silencer_glaives_of_wisdom_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_glaives_of_wisdom"
end

function silencer_glaives_of_wisdom_oaa:CastFilterResultTarget(target)
  local defaultResult = self.BaseClass.CastFilterResultTarget(self, target)
  local caster = self:GetCaster()
  if caster:HasScepter() and defaultResult == UF_FAIL_MAGIC_IMMUNE_ENEMY then
    return UF_SUCCESS
  else
    return defaultResult
  end
end

function silencer_glaives_of_wisdom_oaa:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
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
    Debug.EnabledModules["abilities:oaa_glaives_of_wisdom"] = false
  end
end

modifier_oaa_glaives_of_wisdom.OnRefresh = modifier_oaa_glaives_of_wisdom.OnCreated

function modifier_oaa_glaives_of_wisdom:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_FINISHED,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL
  }
end

-- Only AttackStart is early enough to override the projectile
function modifier_oaa_glaives_of_wisdom:OnAttackStart(keys)
  local parent = self:GetParent()

  if keys.attacker ~= parent then
    return
  end

  local ability = self:GetAbility()
  local target = keys.target

  -- Wrap in function to defer evaluation
  local function autocast()
    return (
      target.GetUnitName and -- Check for existence of GetUnitName method to determine if target is a unit
      ability:GetAutoCastState() and
      not parent:IsSilenced() and
      ability:IsOwnersManaEnough() and
      ability:IsOwnersGoldEnough(parent:GetPlayerOwnerID()) and
      ability:IsCooldownReady() and
      ability:CastFilterResultTarget(target) == UF_SUCCESS
    )
  end

  if parent:GetCurrentActiveAbility() ~= ability and not autocast() then
    return
  end

  -- Add modifier to change attack sound
  parent:AddNewModifier( parent, ability, "modifier_oaa_glaives_of_wisdom_fx", {} )
  -- Set projectile
  parent:SetRangedProjectileName("particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf")
end

function modifier_oaa_glaives_of_wisdom:OnAttack(keys)
  local parent = self:GetParent()

  if keys.attacker ~= parent then
    return
  end

  local ability = self:GetAbility()
  local target = keys.target

  -- Wrap in function to defer evaluation
  local function autocast()
    return (
      target.GetUnitName and -- Check for existence of GetUnitName method to determine if target is a unit
      ability:GetAutoCastState() and
      not parent:IsSilenced() and
      ability:IsOwnersManaEnough() and
      ability:IsOwnersGoldEnough(parent:GetPlayerOwnerID()) and
      ability:IsCooldownReady() and
      ability:CastFilterResultTarget(target) == UF_SUCCESS
    )
  end

  if parent:GetCurrentActiveAbility() ~= ability and not autocast() then
    return
  end

  -- Enable proc for this attack record number
  self.procRecords[keys.record] = true
  -- Using attack modifier abilities doesn't actually fire any cast events so we need to use resources here
  ability:UseResources(true, true, true)
end

function modifier_oaa_glaives_of_wisdom:OnAttackFinished(keys)
  local parent = self:GetParent()
  if keys.attacker == parent then
    parent:RemoveModifierByName("modifier_oaa_glaives_of_wisdom_fx")
    parent:SetRangedProjectileName(self.parentOriginalProjectile)
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackLanded(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = keys.target

  if keys.attacker == parent and self.procRecords[keys.record] and ability:CastFilterResultTarget(target) == UF_SUCCESS then

    local bonusDamagePct = ability:GetSpecialValueFor("intellect_damage_pct") / 100
    local player = parent:GetPlayerOwner()

    -- Check for +20% Glaive damage Talent
    if parent:HasLearnedAbility("special_bonus_unique_silencer_3") then
      bonusDamagePct = bonusDamagePct + parent:FindAbilityByName("special_bonus_unique_silencer_3"):GetSpecialValueFor("value") / 100
    end

    if parent:HasScepter() and target:IsSilenced() then
      bonusDamagePct = bonusDamagePct * ability:GetSpecialValueFor("scepter_damage_multiplier")
    end

    local bonusDamage = parent:GetIntellect() * bonusDamagePct

    local damageTable = {
      victim = target,
      attacker = parent,
      damage = bonusDamage,
      damage_type = ability:GetAbilityDamageType(),
      ability = ability
    }
    ApplyDamage(damageTable)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)
    target:EmitSound("Hero_Silencer.GlaivesOfWisdom.Damage")
    self.procRecords[keys.record] = nil
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFail(keys)
  local parent = self:GetParent()

  if keys.attacker == parent and self.procRecords[keys.record] then
    self.procRecords[keys.record] = nil
  end
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom_fx = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom_fx:IsPurgable()
  return false
end

function modifier_oaa_glaives_of_wisdom_fx:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom_fx:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TRANSLATE_ATTACK_SOUND
  }
end

function modifier_oaa_glaives_of_wisdom_fx:GetAttackSound()
  return "Hero_Silencer.GlaivesOfWisdom"
end
