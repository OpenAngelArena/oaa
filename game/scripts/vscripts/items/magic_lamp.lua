LinkLuaModifier("modifier_item_magic_lamp_oaa_passive", "items/magic_lamp.lua", LUA_MODIFIER_MOTION_NONE)

item_magic_lamp_1 = class(ItemBaseClass)

function item_magic_lamp_1:GetIntrinsicModifierName()
  return "modifier_item_magic_lamp_oaa_passive"
end

function item_magic_lamp_1:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_item_magic_lamp_oaa_passive = class(ModifierBaseClass)

function modifier_item_magic_lamp_oaa_passive:IsHidden()
  return true
end

function modifier_item_magic_lamp_oaa_passive:IsDebuff()
  return false
end

function modifier_item_magic_lamp_oaa_passive:IsPurgable()
  return false
end

function modifier_item_magic_lamp_oaa_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_magic_lamp_oaa_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
  end
end

modifier_item_magic_lamp_oaa_passive.OnRefresh = modifier_item_magic_lamp_oaa_passive.OnCreated

function modifier_item_magic_lamp_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
  }
end

function modifier_item_magic_lamp_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_magic_lamp_oaa_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

