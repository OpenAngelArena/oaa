LinkLuaModifier("modifier_aeolus_wind_shield_passive", "abilities/aeolus/aeolus_wind_shield.lua", LUA_MODIFIER_MOTION_NONE)

aeolus_wind_shield = class({})

function aeolus_wind_shield:GetAOERadius()
  return self:GetSpecialValueFor("evasion_range_check")
end

function aeolus_wind_shield:GetIntrinsicModifierName()
	return "modifier_aeolus_wind_shield_passive"
end

function aeolus_wind_shield:OnSpellStart()
  local caster = self:GetCaster()

end

---------------------------------------------------------------------------------------------------

modifier_aeolus_wind_shield_passive = class({})

function modifier_aeolus_wind_shield_passive:IsHidden()
  return true
end

function modifier_aeolus_wind_shield_passive:IsDebuff()
  return false
end

function modifier_aeolus_wind_shield_passive:IsPurgable()
  return false
end

function modifier_aeolus_wind_shield_passive:DeclareFunctions()
    return {
      MODIFIER_PROPERTY_EVASION_CONSTANT,
    }
end

function modifier_aeolus_wind_shield_passive:GetModifierEvasion_Constant(params)
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
