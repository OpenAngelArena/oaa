LinkLuaModifier("modifier_item_sacred_skull_passives", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_sacred_skull_active", "items/sacred_skull.lua", LUA_MODIFIER_MOTION_NONE)

item_sacred_skull = class(ItemBaseClass)

function item_sacred_skull:GetIntrinsicModifierName()
  return "modifier_item_sacred_skull_passives"
end

function item_sacred_skull:GetHealthCost()
  return self:GetCaster():GetMaxHealth() * self:GetSpecialValueFor("health_cost") * 0.01
end

function item_sacred_skull:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, "modifier_item_sacred_skull_active", {duration = self:GetSpecialValueFor("duration")})
end

item_sacred_skull_2 = item_sacred_skull
item_sacred_skull_3 = item_sacred_skull
item_sacred_skull_4 = item_sacred_skull
item_sacred_skull_5 = item_sacred_skull

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_passives = class(ModifierBaseClass)

function modifier_item_sacred_skull_passives:IsHidden()
  return true
end

function modifier_item_sacred_skull_passives:IsDebuff()
  return false
end

function modifier_item_sacred_skull_passives:IsPurgable()
  return false
end

function modifier_item_sacred_skull_passives:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_sacred_skull_passives:OnCreated()
  self:OnRefresh()
end

function modifier_item_sacred_skull_passives:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  end
end

function modifier_item_sacred_skull_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, -- GetModifierBonusStats_Strength
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, -- GetModifierPhysicalArmorBonus
  }
end

function modifier_item_sacred_skull_passives:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_sacred_skull_passives:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_sacred_skull_passives:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_sacred_skull_passives:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

---------------------------------------------------------------------------------------------------

modifier_item_sacred_skull_active = class(ModifierBaseClass)

function modifier_item_sacred_skull_active:IsHidden()
  return false
end

function modifier_item_sacred_skull_active:IsDebuff()
  return false
end

function modifier_item_sacred_skull_active:IsPurgable()
  return false
end

function modifier_item_sacred_skull_active:OnCreated(event)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_amp = ability:GetSpecialValueFor("spell_amp")
    self.bonus_mana = ability:GetSpecialValueFor("min_mana_gain")
  end
end

function modifier_item_sacred_skull_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, -- GetModifierTotalDamageOutgoing_Percentage
  }
end

function modifier_item_sacred_skull_active:GetModifierManaBonus()
  return self.bonus_mana
end

function modifier_item_sacred_skull_active:GetModifierSpellAmplify_Percentage()
  return self.spell_amp
end

function modifier_item_sacred_skull_active:GetModifierTotalDamageOutgoing_Percentage(event)
  if event.damage_type ~= DAMAGE_TYPE_PHYSICAL and event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
    local damage_table = {
      attacker = self:GetParent(),
      victim = event.target,
      damage = math.max(event.damage, event.original_damage),
      damage_type = DAMAGE_TYPE_PHYSICAL,
      damage_flags = bit.bor(event.damage_flags, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK),
      ability = event.inflictor or self:GetAbility(),
    }
    ApplyDamage(damage_table)
    return -200
  end
  return 0
end
