---
--- Created by Zarnotox.
--- DateTime: 03-Dec-17 21:32
---
item_dagger_of_moriah_1 = class(ItemBaseClass)

LinkLuaModifier("modifier_item_dagger_of_moriah_passive", "items/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_aura_effect", "items/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_sangromancy", "items/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_dagger_of_moriah_frostbite", "items/dagger_of_moriah.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

function item_dagger_of_moriah_1:GetIntrinsicModifierName()
  return "modifier_item_dagger_of_moriah_passive"
end

function item_dagger_of_moriah_1:OnSpellStart()
  local caster = self:GetCaster()

  caster:AddNewModifier(caster, self, "modifier_item_dagger_of_moriah_sangromancy", {duration = self:GetSpecialValueFor("duration")})
end

item_dagger_of_moriah_2 = item_dagger_of_moriah_1

---------------------------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_passive = class(ModifierBaseClass)

function modifier_item_dagger_of_moriah_passive:IsHidden()
  return true
end

function modifier_item_dagger_of_moriah_passive:IsDebuff()
  return false
end

function modifier_item_dagger_of_moriah_passive:IsPurgable()
  return false
end

function modifier_item_dagger_of_moriah_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_dagger_of_moriah_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    local parent = self:GetParent()

    -- Remove aura effect modifier from units in radius to force refresh
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self:GetAuraRadius(),
      self:GetAuraSearchTeam(),
      self:GetAuraSearchType(),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function RemoveAuraEffect(unit)
      unit:RemoveModifierByName(self:GetModifierAura())
    end

    foreach(RemoveAuraEffect, units)
  end
end

function modifier_item_dagger_of_moriah_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.stats = ability:GetSpecialValueFor("bonus_all_stats")
    self.armor = ability:GetSpecialValueFor("bonus_armor")
    self.hp_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.mp_regen = ability:GetSpecialValueFor("bonus_mana_regen")
    self.aura_radius = ability:GetSpecialValueFor("aura_radius")
  end
end

function modifier_item_dagger_of_moriah_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
  }
end

function modifier_item_dagger_of_moriah_passive:GetModifierBonusStats_Strength()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_passive:GetModifierBonusStats_Agility()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_passive:GetModifierBonusStats_Intellect()
  return self.stats or self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end

function modifier_item_dagger_of_moriah_passive:GetModifierPhysicalArmorBonus()
  return self.armor or self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_dagger_of_moriah_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_dagger_of_moriah_passive:GetModifierConstantManaRegen()
  return self.mp_regen or self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_dagger_of_moriah_passive:IsAura()
  return true
end

function modifier_item_dagger_of_moriah_passive:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_item_dagger_of_moriah_passive:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_dagger_of_moriah_passive:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_dagger_of_moriah_passive:GetAuraRadius()
  return self.aura_radius or self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_dagger_of_moriah_passive:GetModifierAura()
  return "modifier_item_dagger_of_moriah_aura_effect"
end

--------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_aura_effect = class({})

function modifier_item_dagger_of_moriah_aura_effect:IsHidden()
  return false
end

function modifier_item_dagger_of_moriah_aura_effect:IsDebuff()
  return true
end

function modifier_item_dagger_of_moriah_aura_effect:IsPurgable()
  return false
end

function modifier_item_dagger_of_moriah_aura_effect:OnCreated()
  self:OnRefresh()
end

function modifier_item_dagger_of_moriah_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.magic_resistance = ability:GetSpecialValueFor("aura_magic_resistance")
  end
end

function modifier_item_dagger_of_moriah_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_item_dagger_of_moriah_aura_effect:GetModifierMagicalResistanceBonus()
  if self.magic_resistance then
    return 0 - math.abs(self.magic_resistance)
  end
  return -15
end

function modifier_item_dagger_of_moriah_aura_effect:GetTexture()
  return "custom/dagger_of_moriah_2"
end

---------------------------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_sangromancy = class({})

function modifier_item_dagger_of_moriah_sangromancy:IsHidden()
  return false
end

function modifier_item_dagger_of_moriah_sangromancy:IsDebuff()
  return false
end

function modifier_item_dagger_of_moriah_sangromancy:IsPurgable()
  return true
end

function modifier_item_dagger_of_moriah_sangromancy:OnCreated()
  if IsServer() and self.particle == nil then
    local parent = self:GetParent()
    self.particle = ParticleManager:CreateParticle("particles/items/dagger_of_moriah/dagger_of_moriah_ambient_smoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.particle, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
  end
end

function modifier_item_dagger_of_moriah_sangromancy:OnRefresh()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
  self:OnCreated()
end

function modifier_item_dagger_of_moriah_sangromancy:OnDestroy()
  if IsServer() and self.particle then
    ParticleManager:DestroyParticle(self.particle, false)
    ParticleManager:ReleaseParticleIndex(self.particle)
    self.particle = nil
  end
end

function modifier_item_dagger_of_moriah_sangromancy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

if IsServer() then
  function modifier_item_dagger_of_moriah_sangromancy:GetModifierTotalDamageOutgoing_Percentage(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local inflictor = event.inflictor
    local dmg_flags = event.damage_flags
    local damaged_unit = event.target

    -- Check if parent is dead
    if not parent:IsAlive() then
      return 0
    end

    if not ability or ability:IsNull() then
      return 0
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return 0
    end

    -- Ignore damage that has hp removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return 0
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return 0
    end

    -- Check if damaged entity is an item, rune or something weird
    -- if damaged_unit.HasModifier == nil then
      -- return 0
    -- end

    -- Prevent stacking with Veil of Discord and Shiva's Guard
    -- if damaged_unit:HasModifier("modifier_item_veil_of_discord_debuff") then
      -- return 0
    -- end

    if inflictor and event.damage_category == DOTA_DAMAGE_CATEGORY_SPELL and event.damage_type == DAMAGE_TYPE_MAGICAL then
      -- Ignore item damage
      if inflictor:IsItem() then
        return 0
      end

      return ability:GetSpecialValueFor("magic_dmg_amp")
    end
    return 0
  end

  function modifier_item_dagger_of_moriah_sangromancy:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local inflictor = event.inflictor

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

    -- Ignore self damage and allies
    if damaged_unit == attacker or damaged_unit:GetTeamNumber() == attacker:GetTeamNumber() then
      return
    end

    -- Check if attacker is dead
    if not attacker:IsAlive() then
      return
    end

    -- Check if damaged entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    -- Check if inflictor exists (if it doesn't, it's not a spell) and damage category
    if not inflictor or event.damage_category ~= DOTA_DAMAGE_CATEGORY_SPELL then
      return
    end

    -- If inflictor is an item (radiance e.g.), don't continue
    if inflictor and inflictor:IsItem() then
      return
    end

    -- Ignore damage that has the no-reflect flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage that has hp removal flag
    if bit.band(event.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage that is <= 0
    if event.damage <= 0 then
      return
    end

    -- Apply Heal reduction debuff
    local debuff_duration = ability:GetSpecialValueFor("heal_reduction_duration")
    damaged_unit:AddNewModifier(parent, ability, "modifier_item_dagger_of_moriah_frostbite", {duration = debuff_duration})
    damaged_unit:ApplyNonStackableBuff(parent, ability, "modifier_item_enhancement_crude", debuff_duration)
  end
end

function modifier_item_dagger_of_moriah_sangromancy:OnTooltip()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    return ability:GetSpecialValueFor("magic_dmg_amp")
  end
  return 0
end

function modifier_item_dagger_of_moriah_sangromancy:GetTexture()
  return "custom/dagger_of_moriah_2_active"
end

---------------------------------------------------------------------------------------------------

modifier_item_dagger_of_moriah_frostbite = class({})

function modifier_item_dagger_of_moriah_frostbite:IsHidden()
  return false
end

function modifier_item_dagger_of_moriah_frostbite:IsDebuff()
  return true
end

function modifier_item_dagger_of_moriah_frostbite:IsPurgable()
  return true
end

function modifier_item_dagger_of_moriah_frostbite:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.heal_reduction = ability:GetSpecialValueFor("heal_reduction_percent")
  else
    self.heal_reduction = -40
  end
end

modifier_item_dagger_of_moriah_frostbite.OnRefresh = modifier_item_dagger_of_moriah_frostbite.OnCreated

function modifier_item_dagger_of_moriah_frostbite:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_item_dagger_of_moriah_frostbite:GetModifierHealAmplify_PercentageTarget()
  return 0 - math.abs(self.heal_reduction)
end

function modifier_item_dagger_of_moriah_frostbite:GetModifierHPRegenAmplify_Percentage()
  return 0 - math.abs(self.heal_reduction)
end

-- Doesn't work, Thanks Valve!
-- function modifier_item_dagger_of_moriah_frostbite:GetModifierLifestealRegenAmplify_Percentage()
  -- return 0 - math.abs(self.heal_reduction)
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_item_dagger_of_moriah_frostbite:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return 0 - math.abs(self.heal_reduction)
-- end

function modifier_item_dagger_of_moriah_frostbite:GetEffectName()
  return "particles/items/dagger_of_moriah/dagger_of_moriah_frostbite.vpcf" --"particles/items4_fx/spirit_vessel_damage.vpcf"
end

function modifier_item_dagger_of_moriah_frostbite:GetTexture()
  return "custom/dagger_of_moriah_2"
end
