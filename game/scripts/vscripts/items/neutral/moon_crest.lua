LinkLuaModifier("modifier_item_moon_crest_passive", "items/neutral/moon_crest.lua", LUA_MODIFIER_MOTION_NONE)

item_moon_crest = class(ItemBaseClass)

function item_moon_crest:GetIntrinsicModifierName()
  return "modifier_item_moon_crest_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_moon_crest_passive = class(ModifierBaseClass)

function modifier_item_moon_crest_passive:IsHidden()
  return true
end
function modifier_item_moon_crest_passive:IsDebuff()
  return false
end
function modifier_item_moon_crest_passive:IsPurgable()
  return false
end

function modifier_item_moon_crest_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.evasion = ability:GetSpecialValueFor("bonus_evasion")
  end
end

modifier_item_moon_crest_passive.OnRefresh = modifier_item_moon_crest_passive.OnCreated

function modifier_item_moon_crest_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_item_moon_crest_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_moon_crest_passive:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_moon_crest_passive:GetModifierEvasion_Constant()
  return self.evasion or self:GetAbility():GetSpecialValueFor("bonus_evasion")
end
