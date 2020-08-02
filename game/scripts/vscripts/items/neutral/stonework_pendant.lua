LinkLuaModifier("modifier_item_stonework_pendant_passive", "items/neutral/stonework_pendant.lua", LUA_MODIFIER_MOTION_NONE)

item_stonework_pendant = class(ItemBaseClass)

function item_stonework_pendant:GetIntrinsicModifierName()
  return "modifier_item_stonework_pendant_passive"
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
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_lifesteal = ability:GetSpecialValueFor("bonus_spell_lifesteal")
    self.hp_cost_multiplier = ability:GetSpecialValueFor("hp_cost_multiplier")
  end
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() then
    parent:CalculateStatBonus()
  end
  self:StartIntervalThink(0.5)
end

function modifier_item_stonework_pendant_passive:OnRefresh()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_lifesteal = ability:GetSpecialValueFor("bonus_spell_lifesteal")
    self.hp_cost_multiplier = ability:GetSpecialValueFor("hp_cost_multiplier")
  end
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() then
    parent:CalculateStatBonus()
  end
end

function modifier_item_stonework_pendant_passive:OnIntervalThink()
  local parent = self:GetParent()
  self.bonus_hp = self.bonus_hp + parent:GetMaxMana()
  self.bonus_hp_regen = self.bonus_hp_regen + parent:GetManaRegen()
  if IsServer() then
    parent:CalculateStatBonus()
  end
end

function modifier_item_stonework_pendant_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP,
  }
end

function modifier_item_stonework_pendant:GetModifierHealthBonus()
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

function modifier_item_stonework_pendant_passive:GetModifierConstantManaRegen()
	if self.bonus_hp_regen then
    return -self.bonus_hp_regen
  end

  return 0
end

function modifier_item_stonework_pendant_passive:OnTakeDamage(event)
  if IsServer() then
    local attacker = event.attacker
    local target = event.unit
    local damaging_ability = event.inflictor
    local damage = event.damage

    if attacker ~= self:GetParent() or damaging_ability == nil or target == nil then
      return 0
    end

    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      return 0
    end
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) == DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL then
      return 0
    end

    local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:ReleaseParticleIndex(particle)

    local lifesteal_percent = self.spell_lifesteal
    local ability = self:GetAbility()
    if ability and not ability:IsNull() then
      lifesteal_percent = ability:GetSpecialValueFor("bonus_spell_lifesteal")
    end
    local lifesteal = damage * lifesteal_percent / 100
    attacker:Heal(lifesteal, ability)
  end
  return 0
end

function modifier_item_stonework_pendant_passive:GetModifierSpellsRequireHP()
	return self.hp_cost_multiplier or self:GetAbility():GetSpecialValueFor("hp_cost_multiplier")
end
