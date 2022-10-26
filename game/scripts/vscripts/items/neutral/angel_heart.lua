LinkLuaModifier("modifier_item_angel_heart_passive", "items/neutral/angel_heart.lua", LUA_MODIFIER_MOTION_NONE)

item_angel_heart = class(ItemBaseClass)

function item_angel_heart:GetIntrinsicModifierName()
  return "modifier_item_angel_heart_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_angel_heart_passive = class(ModifierBaseClass)

function modifier_item_angel_heart_passive:IsHidden()
  return true
end
function modifier_item_angel_heart_passive:IsDebuff()
  return false
end
function modifier_item_angel_heart_passive:IsPurgable()
  return false
end

function modifier_item_angel_heart_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.mana_cost_reduction = ability:GetSpecialValueFor("mana_cost_reduction_pct")
  end
end

modifier_item_angel_heart_passive.OnRefresh = modifier_item_angel_heart_passive.OnCreated

function modifier_item_angel_heart_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
  }
end

function modifier_item_angel_heart_passive:GetModifierBonusStats_Strength()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_angel_heart_passive:GetModifierBonusStats_Agility()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_angel_heart_passive:GetModifierBonusStats_Intellect()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_angel_heart_passive:GetModifierConstantHealthRegen()
  return self.regen or self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_angel_heart_passive:GetModifierPercentageManacostStacking()
  return self.mana_cost_reduction or self:GetAbility():GetSpecialValueFor("mana_cost_reduction_pct")
end
