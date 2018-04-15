modifier_sonic_fly = class(ModifierBaseClass)

function modifier_sonic_fly:DeclareFunctions()
  return {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
      MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
      MODIFIER_PROPERTY_STATUS_RESISTANCE
  }
end

function modifier_sonic_fly:CheckState()
  local state = {
    [MODIFIER_STATE_FLYING] = true,
  }
  return state
end

function modifier_sonic_fly:GetBonusVisionPercentage()
  return self.GetAbility():GetSpecialValueFor("vision_bonus")
end

function modifier_sonic_fly:GetModifierMoveSpeedBonus_Constant()
  return self.GetAbility():GetSpecialValueFor("speed_bonus")
end