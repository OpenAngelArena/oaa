item_sonic = class(TransformationBaseClass)

LinkLuaModifier("modifier_sonic_fly", "items/transformation/sonic.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

function item_sonic:GetIntrinsicModifierName()
  return "modifier_item_phase_boots"--"modifier_generic_bonus"
end

function item_sonic:GetTransformationModifierName()
  return "modifier_sonic_fly"
end

item_sonic_2 = item_sonic
item_sonic_3 = item_sonic

---------------------------------------------------------------------------------------------------

modifier_sonic_fly = class(ModifierBaseClass)

function modifier_sonic_fly:IsHidden()
  return false
end

function modifier_sonic_fly:IsDebuff()
  return false
end

function modifier_sonic_fly:IsPurgable()
  return true
end

function modifier_sonic_fly:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
    MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
  }
end

function modifier_sonic_fly:CheckState()
  local state = {
    [MODIFIER_STATE_FLYING] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSLOWABLE] = true,
  }
  return state
end

function modifier_sonic_fly:GetBonusVisionPercentage()
  return self:GetAbility():GetSpecialValueFor("vision_bonus")
end

function modifier_sonic_fly:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_sonic_fly:GetModifierIgnoreMovespeedLimit()
  return 1
end

--function modifier_sonic_fly:GetModifierStatusResistanceStacking()
  --return self:GetAbility():GetSpecialValueFor("status_resist")
--end
