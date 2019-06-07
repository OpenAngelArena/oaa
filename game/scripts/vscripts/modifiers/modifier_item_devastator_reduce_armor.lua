-- modifier_item_devastator_reduce_armor

modifier_item_devastator_reduce_armor = class(ModifierBaseClass)

function modifier_item_devastator_reduce_armor:IsHidden()
  return false
end

function modifier_item_devastator_reduce_armor:IsPurgable()
  return true
end

if IsServer() then
  function modifier_item_devastator_reduce_armor:OnCreated()
    self:StartIntervalThink(0.1)
  end

  function modifier_item_devastator_reduce_armor:OnIntervalThink()
    local parent = self:GetParent()
    -- We assume that devastator active has a better armor reduction than the desolator armor reduction
    -- Remove the desolator debuff to prevent stacking armor reductions
    if parent:HasModifier("modifier_desolator_buff") then
      parent:RemoveModifierByName("modifier_desolator_buff")
    end
  end
end

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
