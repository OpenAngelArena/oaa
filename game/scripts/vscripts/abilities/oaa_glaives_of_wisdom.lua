LinkLuaModifier("modifier_oaa_glaives_of_wisdom", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_glaives_of_wisdom_fx", "abilities/oaa_glaives_of_wisdom.lua", LUA_MODIFIER_MOTION_NONE)

silencer_glaives_of_wisdom_oaa = class(AbilityBaseClass)

function silencer_glaives_of_wisdom_oaa:GetIntrinsicModifierName()
  return "modifier_oaa_glaives_of_wisdom"
end

--[[
function silencer_glaives_of_wisdom_oaa:CastFilterResultTarget(target)
  local defaultResult = self.BaseClass.CastFilterResultTarget(self, target)
  local caster = self:GetCaster()
  if caster:HasScepter() and defaultResult == UF_FAIL_MAGIC_IMMUNE_ENEMY then
    return UF_SUCCESS
  else
    return defaultResult
  end
end
]]

function silencer_glaives_of_wisdom_oaa:GetCastRange(location, target)
  return self:GetCaster():GetAttackRange()
end

function silencer_glaives_of_wisdom_oaa:ShouldUseResources()
  return true
end

--------------------------------------------------------------------------------

modifier_oaa_glaives_of_wisdom = class(ModifierBaseClass)

function modifier_oaa_glaives_of_wisdom:IsHidden()
  return true
end

function modifier_oaa_glaives_of_wisdom:IsDebuff()
  return false
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
  end
end

modifier_oaa_glaives_of_wisdom.OnRefresh = modifier_oaa_glaives_of_wisdom.OnCreated

function modifier_oaa_glaives_of_wisdom:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_START,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
    MODIFIER_EVENT_ON_ATTACK_FINISHED
  }
end

function modifier_oaa_glaives_of_wisdom:OnAttackStart(event)
  -- OnAttackStart event is triggering before OnAttack event
  -- Only AttackStart is early enough to override the projectile
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  if parent:IsIllusion() then
    return
  end

  local target
  if event.target == nil then
    return
  else
    target = event.target
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
    if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
      --The Attack while Autocast is ON or manually casted (current active ability)

      -- Add modifier to change attack sound
      parent:AddNewModifier(parent, ability, "modifier_oaa_glaives_of_wisdom_fx", {})

      -- Change Attack Projectile
      parent:ChangeAttackProjectile()
    end
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttack(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if event.attacker ~= parent then
    return
  end

  local target
  if event.target == nil then
    return
  else
    target = event.target
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  if ability:IsOwnersManaEnough() and ability:IsCooldownReady() and (not parent:IsSilenced()) and (ability:CastFilterResultTarget(target) == UF_SUCCESS) then
    if ability:GetAutoCastState() == true or parent:GetCurrentActiveAbility() == ability then
      --The Attack while Autocast is ON or or manually casted (current active ability)
      -- Enable proc for this attack record number (event.record is the same for OnAttackLanded)
      self.procRecords[event.record] = true

      -- Use mana and trigger cd while respecting reductions
      -- Using attack modifier abilities doesn't actually fire any cast events so we need to use resources here
      ability:UseResources(true, false, true)

      -- Changing projectile back is too early during OnAttack,
      -- Changing projectile back is done by removing modifier_oaa_glaives_of_wisdom_fx from the parent
      -- it should be done during OnAttackFinished;
    end
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFinished(event)
  local parent = self:GetParent()
  if event.attacker == parent then
    -- Remove modifier on every finished attack even if its a normal attack
    parent:RemoveModifierByName("modifier_oaa_glaives_of_wisdom_fx")

    -- Change the projectile (if a parent doesn't have modifier_oaa_glaives_of_wisdom_fx)
    parent:ChangeAttackProjectile()
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackLanded(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = event.target

  if event.attacker ~= parent then
    return
  end

  if parent:IsIllusion() then
    return
  end

  -- if target is nothing (nil), don't continue
  if target == nil then
    return
  end

  -- Check if the target is going to be deleted soon by C++ garbage collector, if true don't continue
  if target:IsNull() then
    return
  end

  if self.procRecords[event.record] and ability:CastFilterResultTarget(target) == UF_SUCCESS then

    local bonusDamagePct = ability:GetSpecialValueFor("intellect_damage_pct") / 100
    local player = parent:GetPlayerOwner()

    -- Check for +20% Glaive damage Talent
    if parent:HasLearnedAbility("special_bonus_unique_silencer_3") then
      bonusDamagePct = bonusDamagePct + parent:FindAbilityByName("special_bonus_unique_silencer_3"):GetSpecialValueFor("value") / 100
    end

    --if parent:HasScepter() and target:IsSilenced() then
      --bonusDamagePct = bonusDamagePct * ability:GetSpecialValueFor("scepter_damage_multiplier")
    --end

    local bonusDamage = parent:GetIntellect() * bonusDamagePct

    local damageTable = {}
    damageTable.victim = target
    damageTable.attacker = parent
    damageTable.damage = bonusDamage
    damageTable.damage_type = ability:GetAbilityDamageType()
    damageTable.ability = ability

    --if parent:HasScepter() and target:IsMagicImmune() then
      --damageTable.damage_type = DAMAGE_TYPE_PHYSICAL
      --damageTable.damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK
    --end

    ApplyDamage(damageTable)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, bonusDamage, player)
    target:EmitSound("Hero_Silencer.GlaivesOfWisdom.Damage")
    self.procRecords[event.record] = nil
  end
end

function modifier_oaa_glaives_of_wisdom:OnAttackFail(event)
  local parent = self:GetParent()

  if event.attacker == parent and self.procRecords[event.record] then
    self.procRecords[event.record] = nil
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
