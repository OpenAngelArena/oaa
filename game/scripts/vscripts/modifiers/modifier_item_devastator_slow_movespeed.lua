modifier_item_devastator_slow_movespeed = class(ModifierBaseClass)

function modifier_item_devastator_slow_movespeed:OnCreated()
  if self:GetAbility() then
    self.movespeedBonus = self:GetAbility():GetSpecialValueFor("devastator_movespeed_reduction")
  else
    self.movespeedBonus = 0
  end
end

modifier_item_devastator_slow_movespeed.OnRefresh = modifier_item_devastator_slow_movespeed.OnCreated

function modifier_item_devastator_slow_movespeed:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
end

function modifier_item_devastator_slow_movespeed:GetModifierMoveSpeedBonus_Percentage()
  return self.movespeedBonus
end

function modifier_item_devastator_slow_movespeed:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end

function modifier_item_devastator_slow_movespeed:IsPurgable()
  return true
end
