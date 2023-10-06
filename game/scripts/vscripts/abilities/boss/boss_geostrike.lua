boss_geostrike = class(AbilityBaseClass)

LinkLuaModifier("modifier_boss_geostrike", "abilities/boss/boss_geostrike.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_geostrike_debuff", "abilities/boss/boss_geostrike.lua", LUA_MODIFIER_MOTION_NONE)

function boss_geostrike:GetIntrinsicModifierName()
  return "modifier_boss_geostrike"
end

---------------------------------------------------------------------------------------------------

modifier_boss_geostrike = class(ModifierBaseClass)

function modifier_boss_geostrike:IsHidden()
  return true
end

function modifier_boss_geostrike:IsDebuff()
  return false
end

function modifier_boss_geostrike:IsPurgable()
  return false
end

function modifier_boss_geostrike:RemoveOnDeath()
  return true
end

function modifier_boss_geostrike:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

if IsServer() then
  function modifier_boss_geostrike:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Don't proc on units that dont have this modifier or if broken
    if attacker ~= parent or parent:PassivesDisabled() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Don't affect buildings, wards, spell immune units and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:IsInvulnerable() then
      return
    end

    -- Get duration
    local duration = ability:GetSpecialValueFor("duration")

    -- Apply slow debuff
    target:AddNewModifier(parent, ability, "modifier_boss_geostrike_debuff", {duration = duration})
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_geostrike_debuff = class(ModifierBaseClass)

function modifier_boss_geostrike_debuff:IsHidden()
	return false
end

function modifier_boss_geostrike_debuff:IsDebuff()
	return true
end

function modifier_boss_geostrike_debuff:IsPurgable()
	return true
end

function modifier_boss_geostrike_debuff:RemoveOnDeath()
	return true
end

function modifier_boss_geostrike_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.movement_slow = ability:GetSpecialValueFor("move_speed_slow")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  end
end

function modifier_boss_geostrike_debuff:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.movement_slow = ability:GetSpecialValueFor("move_speed_slow")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
  end
end

function modifier_boss_geostrike_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_boss_geostrike_debuff:GetModifierMoveSpeedBonus_Percentage()
  if self.movement_slow or self:GetAbility() then
    return self.movement_slow or self:GetAbility():GetSpecialValueFor("move_speed_slow")
  end

  return -50
end

function modifier_boss_geostrike_debuff:GetModifierAttackSpeedBonus_Constant()
  if self.attack_slow or self:GetAbility() then
    return self.attack_slow or self:GetAbility():GetSpecialValueFor("attack_speed_slow")
  end

  return -50
end

function modifier_boss_geostrike_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end
