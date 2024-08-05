LinkLuaModifier("modifier_item_stonework_pendant_passive", "items/neutral/stonework_pendant.lua", LUA_MODIFIER_MOTION_NONE)

item_stonework_pendant = class(ItemBaseClass)

function item_stonework_pendant:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_stonework_pendant:GetIntrinsicModifierNames()
  return {
    "modifier_item_stonework_pendant_passive",
    "modifier_item_spell_lifesteal_oaa",
  }
end

function item_stonework_pendant:IsMuted()
  local caster = self:GetCaster()
  if not caster:IsHero() then
    return true
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_stonework_pendant_passive = class(ModifierBaseClass)

function modifier_item_stonework_pendant_passive:IsHidden()
  return true
end
function modifier_item_stonework_pendant_passive:IsDebuff()
  return false
end
function modifier_item_stonework_pendant_passive:IsPurgable()
  return false
end

function modifier_item_stonework_pendant_passive:OnCreated()
  self:OnRefresh()
  self:StartIntervalThink(0.5)
end

function modifier_item_stonework_pendant_passive:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_cost_multiplier = ability:GetSpecialValueFor("hp_cost_multiplier")
  end
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_item_stonework_pendant_passive:OnIntervalThink()
  local parent = self:GetParent()
  self.bonus_hp = self.bonus_hp + parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
  end
end

function modifier_item_stonework_pendant_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP,
  }
end

function modifier_item_stonework_pendant_passive:GetModifierHealthBonus()
  if self.bonus_hp then
    return self.bonus_hp
  end

  return 0
end

function modifier_item_stonework_pendant_passive:GetModifierConstantHealthRegen()
  if self.bonus_hp_regen then
    return self.bonus_hp_regen
  end

  return 0
end

function modifier_item_stonework_pendant_passive:GetModifierManaBonus()
  if self.bonus_hp then
    return -self.bonus_hp
  end

  return 0
end

function modifier_item_stonework_pendant_passive:GetModifierSpellsRequireHP()
  return self.hp_cost_multiplier or self:GetAbility():GetSpecialValueFor("hp_cost_multiplier")
end
