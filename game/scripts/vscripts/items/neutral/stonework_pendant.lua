LinkLuaModifier("modifier_item_stonework_pendant_passive", "items/neutral/stonework_pendant.lua", LUA_MODIFIER_MOTION_NONE)

item_stonework_pendant = class(ItemBaseClass)

function item_stonework_pendant:GetIntrinsicModifierName()
  return "modifier_item_stonework_pendant_passive"
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
    MODIFIER_PROPERTY_SPELLS_REQUIRE_HP, -- doesnt work properly, thx Valve
    MODIFIER_EVENT_ON_ABILITY_EXECUTED, -- reinventing Health Cost
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
  -- On Client: it shows mana cost x this number as health cost
  -- On Server: it doesnt spend health for most spells, but at least it turns mana cost per second into health per second x this number for some spells
  return self.hp_cost_multiplier or self:GetAbility():GetSpecialValueFor("hp_cost_multiplier")
end

-- Reinventing Amplified Health Cost that is not affected by magic resist
if IsServer() then
  function modifier_item_stonework_pendant_passive:OnAbilityExecuted(event)
    local parent = self:GetParent()

    local cast_ability = event.ability
    local caster = event.unit

    -- Check if caster has this modifier
    if caster ~= parent then
      return
    end

    if not cast_ability then
      return
    end

    local mana_cost = cast_ability:GetManaCost(-1)
    local self_damage = mana_cost * self.hp_cost_multiplier
    local damage_table = {
      attacker = parent,
      victim = parent,
      damage = self_damage,
      damage_type = DAMAGE_TYPE_PURE,
      damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
      ability = cast_ability
    }
    ApplyDamage(damage_table)
  end
end
