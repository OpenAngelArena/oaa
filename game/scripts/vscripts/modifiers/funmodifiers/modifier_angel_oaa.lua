-- Angel's Wings

modifier_angel_oaa = class(ModifierBaseClass)

function modifier_angel_oaa:IsHidden()
  return false
end

function modifier_angel_oaa:IsDebuff()
  return false
end

function modifier_angel_oaa:IsPurgable()
  return false
end

function modifier_angel_oaa:RemoveOnDeath()
  return false
end

function modifier_angel_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_angel_oaa:GetBonusDayVision()
  return 200
end

function modifier_angel_oaa:GetBonusNightVision()
  return 200
end

function modifier_angel_oaa:GetModifierMoveSpeedBonus_Percentage()
  return 30
end

function modifier_angel_oaa:GetModifierStatusResistanceStacking()
  return -30
end

function modifier_angel_oaa:CheckState()
  return {
    [MODIFIER_STATE_FLYING] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FORCED_FLYING_VISION] = true,
  }
end

function modifier_angel_oaa:GetTexture()
  return "keeper_of_the_light_illuminate"
end
