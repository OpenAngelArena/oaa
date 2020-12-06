boss_geostrike = class(AbilityBaseClass)

LinkLuaModifier("modifier_boss_geostrike", "abilities/boss_geostrike.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_geostrike_debuff", "abilities/boss_geostrike.lua", LUA_MODIFIER_MOTION_NONE)

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

function modifier_boss_geostrike:OnAttackLanded(event)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local target = event.target

  -- Don't proc on units that dont have this modifier, don't proc on illusion or if broken
  if parent ~= event.attacker or parent:IsIllusion() or parent:PassivesDisabled() then
    return
  end

  -- To prevent crashes:
  if not target then
    return
  end

  if target:IsNull() then
    return
  end

  if not IsServer() then
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
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
  return funcs
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
