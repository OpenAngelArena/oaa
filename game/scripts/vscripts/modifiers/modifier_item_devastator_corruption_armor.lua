modifier_item_devastator_corruption_armor = class(ModifierBaseClass)

function modifier_item_devastator_corruption_armor:IsHidden()
  return false
end

function modifier_item_devastator_corruption_armor:IsPurgable()
  return true
end

function modifier_item_devastator_corruption_armor:OnCreated()
  self:StartIntervalThink(0.1)
end

function modifier_item_devastator_corruption_armor:OnIntervalThink()
  local parent = self:GetParent()
  -- We assume that desolator has a better (or the same) armor reduction than devastator passive
  -- We remove this debuff safely to prevent stacking armor reductions
  if parent:HasModifier("modifier_desolator_buff") then
    self:StartIntervalThink(-1)
    self:SetDuration(0.01, false)
  end
end

function modifier_item_devastator_corruption_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
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
