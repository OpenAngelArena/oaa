LinkLuaModifier( "modifier_item_shroud_passive", "items/shroud.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_shroud = class(ItemBaseClass)

function item_shroud:GetIntrinsicModifierName()
  return "modifier_item_shroud_passive"
end

function item_shroud:OnSpellStart()
  local hTarget = self:GetCursorTarget()
  local shroud_duration = self:GetSpecialValueFor( "duration" )

  hTarget:EmitSound( "Item.GlimmerCape.Activate" )
  hTarget:AddNewModifier( hTarget, self, "modifier_ghost_state", { duration = shroud_duration } )
  hTarget:AddNewModifier( hTarget, self, "modifier_item_glimmer_cape_fade", { duration = shroud_duration } )
end

--------------------------------------------------------------------------------

item_shroud_2 = item_shroud
item_shroud_3 = item_shroud
item_shroud_4 = item_shroud

--------------------------------------------------------------------------------

modifier_item_shroud_passive = class(ModifierBaseClass)

function modifier_item_shroud_passive:IsHidden()
  return true
end

function modifier_item_shroud_passive:IsPurgable()
  return false
end

function modifier_item_shroud_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_shroud_passive:OnCreated()
  self.bonus_all_stats = self:GetAbility():GetSpecialValueFor( "bonus_all_stats" )
  self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )
  self.bonus_magical_armor = self:GetAbility():GetSpecialValueFor( "bonus_magical_armor" )
end

function modifier_item_shroud_passive:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_item_shroud_passive:GetModifierBonusStats_Strength()
  return self.bonus_all_stats
end

function modifier_item_shroud_passive:GetModifierBonusStats_Agility()
  return self.bonus_all_stats
end

function modifier_item_shroud_passive:GetModifierBonusStats_Intellect()
  return self.bonus_all_stats
end

function modifier_item_shroud_passive:GetModifierAttackSpeedBonus_Constant()
  return self.bonus_attack_speed
end

function modifier_item_shroud_passive:GetModifierMagicalResistanceBonus()
  return self.bonus_magical_armor
end

--------------------------------------------------------------------------------
