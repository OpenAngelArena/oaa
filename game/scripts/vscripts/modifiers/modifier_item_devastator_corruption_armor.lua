
modifier_item_devastator_corruption_armor = class(ModifierBaseClass)

function modifier_item_devastator_corruption_armor:IsHidden()
  return false
end

function modifier_item_devastator_corruption_armor:IsDebuff()
  return true
end

function modifier_item_devastator_corruption_armor:IsPurgable()
  return true
end

function modifier_item_devastator_corruption_armor:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_devastator_corruption_armor:OnIntervalThink()
  local parent = self:GetParent()

  if parent:HasModifier("modifier_desolator_buff") then
    parent:RemoveModifierByName("modifier_desolator_buff")
    --self:StartIntervalThink(-1)
    --self:SetDuration(0.01, false)
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
  --local ability = self:GetAbility()
  --if ability and not ability:IsNull() then
    --local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    --return baseIconName
  --end
  return "item_desolator"
end
