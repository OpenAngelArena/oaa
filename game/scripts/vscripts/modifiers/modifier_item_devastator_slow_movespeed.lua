modifier_item_devastator_slow_movespeed = class(ModifierBaseClass)

function modifier_item_devastator_slow_movespeed:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local move_speed_slow = 0

  if ability then
    move_speed_slow = ability:GetSpecialValueFor("devastator_movespeed_reduction")
  end
  if IsServer() then
    self.slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
  else
    self.slow = move_speed_slow
  end
end

modifier_item_devastator_slow_movespeed.OnRefresh = modifier_item_devastator_slow_movespeed.OnCreated

function modifier_item_devastator_slow_movespeed:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
  }
end

function modifier_item_devastator_slow_movespeed:GetModifierMoveSpeedBonus_Percentage()
  return self.slow
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
