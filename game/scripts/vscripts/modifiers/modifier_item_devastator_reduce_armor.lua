-- modifier_item_devastator_reduce_armor

modifier_item_devastator_reduce_armor = class(ModifierBaseClass)

function modifier_item_devastator_reduce_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_devastator_reduce_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("devastator_armor_reduction")
end

function modifier_item_devastator_reduce_armor:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end
