-- Telescope

modifier_range_increase_oaa = class(ModifierBaseClass)

function modifier_range_increase_oaa:IsHidden()
  return false
end

function modifier_range_increase_oaa:IsDebuff()
  return false
end

function modifier_range_increase_oaa:IsPurgable()
  return false
end

function modifier_range_increase_oaa:RemoveOnDeath()
  return false
end

function modifier_range_increase_oaa:OnCreated()
  self.bonus_range = 350
end

function modifier_range_increase_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_range_increase_oaa:GetModifierCastRangeBonusStacking()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetModifierAttackRangeBonus()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetBonusDayVision()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetBonusNightVision()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetTexture()
  return "item_spy_gadget"
end
