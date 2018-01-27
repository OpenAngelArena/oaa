modifier_item_devastator_corruption_armor = class(ModifierBaseClass)

-- modifier_item_devastator_corruption_armor.OnRefresh = modifier_item_devastator_corruption_armor.OnCreated

function modifier_item_devastator_corruption_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end
function modifier_item_devastator_corruption_armor:IsHidden()
	return false
end
function modifier_item_devastator_corruption_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("corruption_armor")
end

function modifier_item_devastator_corruption_armor:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end