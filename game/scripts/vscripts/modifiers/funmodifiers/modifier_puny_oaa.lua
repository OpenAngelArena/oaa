modifier_puny_oaa = class(ModifierBaseClass)

function modifier_puny_oaa:IsHidden()
  return false
end

function modifier_puny_oaa:IsDebuff()
  return false
end

function modifier_puny_oaa:IsPurgable()
  return false
end

function modifier_puny_oaa:RemoveOnDeath()
  return false
end

function modifier_puny_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
  }
end

function modifier_puny_oaa:GetModifierBonusStats_Strength()
  return -999
end

function modifier_puny_oaa:GetModifierEvasion_Constant()
  return 75
end

function modifier_puny_oaa:GetModifierMoveSpeedBonus_Percentage()
  return 75
end

function modifier_puny_oaa:GetModifierPercentageManacostStacking()
  return 75
end

function modifier_puny_oaa:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

function modifier_puny_oaa:GetTexture()
  return "item_boots_of_elves"
end
