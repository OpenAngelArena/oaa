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
  local parent = self:GetParent()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.spell_lifesteal = ability:GetSpecialValueFor("bonus_spell_lifesteal")
    self.hp_cost_multiplier = ability:GetSpecialValueFor("hp_cost_multiplier")
  end
  self.bonus_hp = parent:GetMaxMana()
  self.bonus_hp_regen = parent:GetManaRegen()
  if IsServer() and parent:IsHero() then
    parent:CalculateStatBonus(true)
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
    MODIFIER_EVENT_ON_TAKEDAMAGE,
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

function modifier_item_stonework_pendant_passive:OnTakeDamage(event)
  if not IsServer() then
    return
  end

  local attacker = event.attacker
  local damaged_unit = event.unit
  local damaging_ability = event.inflictor

  -- Check if attacker exists
  if not attacker or attacker:IsNull() then
    return
  end

  -- Check if attacker has this modifier
  if attacker ~= self:GetParent() then
    return
  end

  -- Check if damaged entity exists
  if not damaged_unit or damaged_unit:IsNull() then
    return
  end

  -- Ignore self damage
  if damaged_unit == attacker then
    return
  end

  -- Check if entity is an item, rune or something weird
  if damaged_unit.GetUnitName == nil then
    return
  end

  -- Don't affect buildings, wards and invulnerable units.
  if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
    return
  end

  -- If there is no inflictor, damage is not dealt by a spell or item
  if not damaging_ability or damaging_ability:IsNull() then
    return
  end

  -- Ignore damage that has the no-reflect flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
    return
  end

  -- Ignore damage that has the no-spell-lifesteal flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
    return
  end

  -- Ignore damage that has the no-spell-amplification flag
  if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
    return
  end

  local damage = event.damage
  local spell_lifesteal_percent = self.spell_lifesteal

  -- Check for spell lifesteal amplification
  local kaya_modifiers = {
    "modifier_item_kaya",
    "modifier_item_yasha_and_kaya",
    "modifier_item_kaya_and_sange",
  }

  -- local custom_modifiers = {
    -- "modifier_item_stoneskin",
  -- }

  local spell_lifesteal_amp = 0

  for _, mod_name in pairs(kaya_modifiers) do
    local modifier = attacker:FindModifierByName(mod_name)
    if modifier then
      local item = modifier:GetAbility()
      if item then
        -- Spell Lifesteal Amp from Kaya upgrades doesn't stack
        spell_lifesteal_amp = item:GetSpecialValueFor("spell_lifesteal_amp")
      end
    end
  end

  -- for _, mod_name in pairs(custom_modifiers) do
    -- local modifier = attacker:FindModifierByName(mod_name)
    -- if modifier then
      -- local ability = modifier:GetAbility()
      -- if ability then
        -- -- Spell Lifesteal Amp stacks multiplicatively
        -- spell_lifesteal_amp = 1-(1-spell_lifesteal_amp)*(1-ability:GetSpecialValueFor("spell_lifesteal_amp"))
      -- end
    -- end
  -- end

  spell_lifesteal_percent = spell_lifesteal_percent * (1 + spell_lifesteal_amp/100)

  -- Calculate the spell lifesteal (heal) amount
  local heal_amount = damage * spell_lifesteal_percent / 100

  if heal_amount > 0 then
    attacker:Heal(heal_amount, self:GetAbility())
    -- Particle
    local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
    ParticleManager:SetParticleControl(particle, 0, attacker:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(particle)
  end
end

function modifier_item_stonework_pendant_passive:GetModifierSpellsRequireHP()
	return self.hp_cost_multiplier or self:GetAbility():GetSpecialValueFor("hp_cost_multiplier")
end
