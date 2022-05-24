LinkLuaModifier("modifier_item_ancient_relic_passive", "items/neutral/ancient_relic.lua", LUA_MODIFIER_MOTION_NONE)

item_ancient_relic = class(ItemBaseClass)

function item_ancient_relic:GetIntrinsicModifierName()
  return "modifier_item_ancient_relic_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_ancient_relic_passive = class(ModifierBaseClass)

function modifier_item_ancient_relic_passive:IsHidden()
  return true
end

function modifier_item_ancient_relic_passive:IsDebuff()
  return false
end

function modifier_item_ancient_relic_passive:IsPurgable()
  return false
end

function modifier_item_ancient_relic_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_ms = ability:GetSpecialValueFor("bonus_move_speed")
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
  end
end

function modifier_item_ancient_relic_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage = ability:GetSpecialValueFor("bonus_damage")
    self.bonus_ms = ability:GetSpecialValueFor("bonus_move_speed")
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp")
    self.mana_regen = ability:GetSpecialValueFor("bonus_mana_regen")
  end
end

function modifier_item_ancient_relic_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_item_ancient_relic_passive:GetModifierPreAttack_BonusDamage()
  return self.damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_ancient_relic_passive:GetModifierMoveSpeedBonus_Constant()
  return self.bonus_ms or self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_item_ancient_relic_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_ancient_relic_passive:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

function modifier_item_ancient_relic_passive:GetModifierConstantManaRegen()
  return self.mana_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

