LinkLuaModifier("modifier_eul_wind_shield_passive", "abilities/eul/eul_wind_shield.lua", LUA_MODIFIER_MOTION_NONE)

eul_wind_shield_oaa = class(AbilityBaseClass)

function eul_wind_shield_oaa:GetAOERadius()
  return self:GetSpecialValueFor("evasion_range_check")
end

function eul_wind_shield_oaa:GetIntrinsicModifierName()
	return "modifier_eul_wind_shield_passive"
end

function eul_wind_shield_oaa:OnSpellStart()
  local caster = self:GetCaster()

end

---------------------------------------------------------------------------------------------------

modifier_eul_wind_shield_passive = class(ModifierBaseClass)

function modifier_eul_wind_shield_passive:IsHidden()
  return true
end

function modifier_eul_wind_shield_passive:IsDebuff()
  return false
end

function modifier_eul_wind_shield_passive:IsPurgable()
  return false
end

function modifier_eul_wind_shield_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed = ability:GetSpecialValueFor("bonus_move_speed")
  end
end

modifier_eul_wind_shield_passive.OnRefresh = modifier_eul_wind_shield_passive.OnCreated

function modifier_eul_wind_shield_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_eul_wind_shield_passive:GetModifierEvasion_Constant(params)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local attacker = params.attacker
  local attacked_unit = params.unit

  if not attacker:IsRangedAttacker() then
    return 0
  end

  -- if parent ~= attacked_unit then
    -- print("Attacked unit:")
    -- print(attacked_unit)
  -- end

  -- if parent ~= attacker:GetAttackTarget() then
    -- print("GetAttackTarget")
    -- print(attacker:GetAttackTarget())
  -- end

  local distance = (parent:GetAbsOrigin() - attacker:GetAbsOrigin()):Length2D()
  if distance > ability:GetSpecialValueFor("evasion_range_check") then
    return ability:GetSpecialValueFor("evasion")
  end

  return 0
end

function modifier_eul_wind_shield_passive:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed or 4
end

---------------------------------------------------------------------------------------------------
