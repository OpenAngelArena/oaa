modifier_item_spell_lifesteal_oaa = class(ModifierBaseClass)

function modifier_item_spell_lifesteal_oaa:IsHidden()
  return true
end

function modifier_item_spell_lifesteal_oaa:IsPurgable()
  return false
end

function modifier_item_spell_lifesteal_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_spell_lifesteal_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_item_spell_lifesteal_oaa:OnCreated(kv)
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hero_spell_lifesteal = ability:GetSpecialValueFor("hero_spell_lifesteal")
    self.creep_spell_lifesteal = ability:GetSpecialValueFor("creep_spell_lifesteal")
    self.unholy_hero_spell_lifesteal = ability:GetSpecialValueFor("unholy_hero_spell_lifesteal") or 0
    self.unholy_creep_spell_lifesteal = ability:GetSpecialValueFor("unholy_creep_spell_lifesteal") or 0
    self.multiplier = ability:GetSpecialValueFor("lifesteal_multiplier") or 0
  end
end

modifier_item_spell_lifesteal_oaa.OnRefresh = modifier_item_spell_lifesteal_oaa.OnCreated

if IsServer() then
  function modifier_item_spell_lifesteal_oaa:OnTakeDamage(params)
    local parent = self:GetParent()
    local attacker = params.attacker
    local damaged_unit = params.unit
    local inflictor = params.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
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
    if not inflictor or inflictor:IsNull() then
      return
    end

    local succubus = attacker:FindAbilityByName("queenofpain_succubus")
    local isSuccubus = succubus and succubus:GetLevel() > 0
    local spellLifestealReflected = false
    if isSuccubus then
      spellLifestealReflected = succubus:GetSpecialValueFor("lifesteal_reflected") == 1
    end

    -- Ignore pure damage
    if params.damage_type == DAMAGE_TYPE_PURE then
      if not isSuccubus then
        return
      end
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      if not spellLifestealReflected then
        return
      end
    end

    -- Ignore damage that has the no-spell-lifesteal flag
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      if not spellLifestealReflected then
        return
      end
    end

    -- Ignore damage that has the no-spell-amplification flag
    if bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      if not spellLifestealReflected then
        return
      end
    end

    -- Don't heal while dead
    if not attacker:IsAlive() then
      return
    end

    local damage = params.damage

    -- Check damage if 0 or negative
    if damage <= 0 then
      return
    end

    local nHeroHeal = self.hero_spell_lifesteal
    local nCreepHeal = self.creep_spell_lifesteal

    -- Check for Satanic Core active spell lifesteal
    if self.unholy_hero_spell_lifesteal > 0 and self.unholy_creep_spell_lifesteal > 0 and attacker:HasModifier("modifier_satanic_core_unholy") and attacker:HasModifier("modifier_item_satanic_core") then
      local mod = attacker:FindModifierByName("modifier_satanic_core_unholy")
      local ab = self:GetAbility()
      if ab and mod then
        if ab == mod:GetAbility() then
          nHeroHeal = self.unholy_hero_spell_lifesteal
          nCreepHeal = self.unholy_creep_spell_lifesteal
        end
      end
    end

    -- Check for Bloodstone active
    if self.multiplier > 0 and attacker:HasModifier("modifier_item_bloodstone_active") and attacker:HasModifier("modifier_item_bloodstone") then
      local mod = attacker:FindModifierByName("modifier_item_bloodstone_active")
      local ab = self:GetAbility()
      if ab and mod then
        if ab == mod:GetAbility() then
          nHeroHeal = self.hero_spell_lifesteal * self.multiplier
          nCreepHeal = self.creep_spell_lifesteal * self.multiplier
        end
      end
    end

    -- Most optimal fix for spell lifesteal stacking from sources that are effectively the same
    local n = self:NumberOfSameItemInstances()
    if n == 0 then
      -- Prevent division by 0
      return 0
    end
    nHeroHeal = nHeroHeal / n
    nCreepHeal = nCreepHeal / n

    -- Check for spell lifesteal amplification (sort from worst to best)
    -- local kaya_modifiers = {
      -- "modifier_item_kaya",
      -- "modifier_item_ethereal_blade",
      -- "modifier_item_kaya_and_sange",
      -- "modifier_item_yasha_and_kaya",
    -- }

    -- local custom_modifiers = {
      -- "modifier_item_stoneskin",
    -- }

    -- local spell_lifesteal_amp = 0

    -- for _, mod_name in pairs(kaya_modifiers) do
      -- local modifier = attacker:FindModifierByName(mod_name)
      -- if modifier then
        -- local item = modifier:GetAbility()
        -- if item then
          -- -- Spell Lifesteal Amp from Kaya upgrades doesn't stack
          -- spell_lifesteal_amp = item:GetSpecialValueFor("spell_lifesteal_amp")
        -- end
      -- end
    -- end

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

    -- local paladin_sword_modifier = attacker:FindModifierByName("modifier_item_paladin_sword")
    -- if paladin_sword_modifier then
      -- local paladin_sword = paladin_sword_modifier:GetAbility()
      -- if paladin_sword then
        -- local bonus = paladin_sword:GetSpecialValueFor("bonus_amp")
        -- if bonus then
          -- -- Spell Lifesteal Amp stacks multiplicatively
          -- spell_lifesteal_amp = 1-(1-spell_lifesteal_amp)*(1-bonus)
        -- end
      -- end
    -- end

    -- nHeroHeal = nHeroHeal * (1 + spell_lifesteal_amp/100)
    -- nCreepHeal = nCreepHeal * (1 + spell_lifesteal_amp/100)

    -- Calculate the spell lifesteal (heal) amount
    local heal_amount = 0
    if damaged_unit:IsRealHero() or damaged_unit:IsStrongIllusionOAA() then
      heal_amount = damage * nHeroHeal / 100
    else
      -- Illusions are treated as creeps too
      heal_amount = damage * nCreepHeal / 100
    end

    if heal_amount > 0 then
      attacker:HealWithParams(heal_amount, self:GetAbility(), false, true, attacker, true)
      -- Particle
      local particle = ParticleManager:CreateParticle("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
      ParticleManager:SetParticleControl(particle, 0, attacker:GetAbsOrigin())
      ParticleManager:ReleaseParticleIndex(particle)
    end
  end
end

function modifier_item_spell_lifesteal_oaa:NumberOfSameItemInstances()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  if parent:IsNull() or ability:IsNull() then
    return 0
  end

  if not IsServer() then
    print("NumberOfSameItemInstances will not return the correct result on the client!")
    return 0
  end

  local ability_name = ability:GetAbilityName()
  local same_items = 0 -- not the same as parent:FindAllModifiersByName(self:GetName())
  local max_slot = DOTA_ITEM_SLOT_6
  if parent:HasModifier("modifier_techies_spoons_stash") then
    max_slot = DOTA_ITEM_SLOT_9
  end
  for item_slot = DOTA_ITEM_SLOT_1, max_slot do
    local item = parent:GetItemInSlot(item_slot)
    if item then
      local item_name = item:GetAbilityName()
      if string.sub(item_name, 0, string.len(item_name)-2) == string.sub(ability_name, 0, string.len(ability_name)-2) then
        same_items = same_items + 1
      end
    end
  end

  -- Returns the number of Blood Cores in the inventory, number of Dagons in the inventory etc.
  return same_items
end
