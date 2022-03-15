
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
  self.bonus_range = 400
end

function modifier_range_increase_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_CAST_RANGE_BONUS,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
  }
end

function modifier_range_increase_oaa:GetModifierCastRangeBonus()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetModifierAttackRangeBonus()
  return self.bonus_range
end

function modifier_range_increase_oaa:GetTexture()
  return "item_spy_gadget"
end
