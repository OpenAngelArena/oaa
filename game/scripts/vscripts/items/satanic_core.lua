LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_spell_lifesteal_oaa", "modifiers/modifier_item_spell_lifesteal_oaa.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_satanic_core", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_satanic_core_unholy", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_satanic_core = class(ItemBaseClass)

function item_satanic_core:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_satanic_core:GetIntrinsicModifierNames()
  return {
    "modifier_item_satanic_core",
    "modifier_item_spell_lifesteal_oaa",
  }
end

function item_satanic_core:OnSpellStart()
  local hCaster = self:GetCaster()
  local unholy_duration = self:GetSpecialValueFor("duration")

  hCaster:EmitSound( "DOTA_Item.Satanic.Activate" )
  hCaster:AddNewModifier( hCaster, self, "modifier_satanic_core_unholy", { duration = unholy_duration } )
end

item_satanic_core_2 = item_satanic_core
item_satanic_core_3 = item_satanic_core
item_satanic_core_4 = item_satanic_core
item_satanic_core_5 = item_satanic_core

---------------------------------------------------------------------------------------------------

modifier_item_satanic_core = class(ModifierBaseClass)

function modifier_item_satanic_core:IsHidden()
  return true
end

function modifier_item_satanic_core:IsDebuff()
  return false
end

function modifier_item_satanic_core:IsPurgable()
  return false
end

function modifier_item_satanic_core:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_satanic_core:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    --self.bonus_int = ability:GetSpecialValueFor("bonus_intelligence")
    self.bonus_hp = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    --self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resist")
    --self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
    --self.hp_regen_amp = ability:GetSpecialValueFor("hp_regen_amp")
  end
end

modifier_item_satanic_core.OnRefresh = modifier_item_satanic_core.OnCreated

function modifier_item_satanic_core:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    --MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_satanic_core:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_satanic_core:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intelligence")
end

function modifier_item_satanic_core:GetModifierHealthBonus()
  return self.bonus_hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_satanic_core:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_satanic_core:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resist")
end

function modifier_item_satanic_core:GetModifierStatusResistanceStacking()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items
  -- if parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
end

function modifier_item_satanic_core:GetModifierHPRegenAmplify_Percentage()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items
  -- if parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

function modifier_item_satanic_core:GetModifierLifestealRegenAmplify_Percentage()
  -- local parent = self:GetParent()
  -- Prevent stacking with Sange items
  -- if parent:HasModifier("modifier_item_sange") or parent:HasModifier("modifier_item_sange_and_yasha") or parent:HasModifier("modifier_item_kaya_and_sange") or parent:HasModifier("item_heavens_halberd") then
    -- return 0
  -- end
  return self.hp_regen_amp or self:GetAbility():GetSpecialValueFor("hp_regen_amp")
end

---------------------------------------------------------------------------------------------------

modifier_satanic_core_unholy = class(ModifierBaseClass)

function modifier_satanic_core_unholy:IsHidden()
  return false
end

function modifier_satanic_core_unholy:IsDebuff()
  return false
end

function modifier_satanic_core_unholy:IsPurgable()
  return true
end

function modifier_satanic_core_unholy:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.tooltip = ability:GetSpecialValueFor("unholy_hero_spell_lifesteal")
  end
end

modifier_satanic_core_unholy.OnRefresh = modifier_satanic_core_unholy.OnCreated

function modifier_satanic_core_unholy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_satanic_core_unholy:OnTooltip()
  return self.tooltip
end

function modifier_satanic_core_unholy:GetEffectName()
  return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_satanic_core_unholy:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_satanic_core_unholy:GetStatusEffectName()
  return "particles/status_fx/status_effect_life_stealer_rage.vpcf"
end

function modifier_satanic_core_unholy:StatusEffectPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_satanic_core_unholy:GetTexture()
  return "custom/satanic_core"
end
