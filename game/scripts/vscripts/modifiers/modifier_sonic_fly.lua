modifier_sonic_fly = class(ModifierBaseClass)

function modifier_sonic_fly:DeclareFunctions()
  return {
      MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
      MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
      MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
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

function modifier_sonic_fly:GetModifierStatusResistanceStacking()
  return self:GetAbility():GetSpecialValueFor("status_resist")
end
