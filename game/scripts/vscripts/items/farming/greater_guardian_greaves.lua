LinkLuaModifier( "modifier_item_greater_guardian_greaves", "items/farming/greater_guardian_greaves.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_greater_guardian_greaves_aura", "items/farming/greater_guardian_greaves.lua", LUA_MODIFIER_MOTION_NONE )

--LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )

item_greater_guardian_greaves = class(ItemBaseClass)

function item_greater_guardian_greaves:OnSpellStart()
  local caster = self:GetCaster()

  if caster:IsClone() then
    return false
  end

  local heroes = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster:GetAbsOrigin(),
    nil,
    self:GetSpecialValueFor("replenish_radius"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
    FIND_ANY_ORDER,
    false
  )

  -- Apply basic dispel to caster
  caster:Purge(false, true, false, false, false)

  local function HasNoHealCooldown(hero)
    return not hero:HasModifier("modifier_item_mekansm_noheal")
  end

  local function ReplenishMana(hero)
    local manaReplenishAmount = self:GetSpecialValueFor("replenish_mana")
    hero:GiveMana(manaReplenishAmount)

    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, hero, manaReplenishAmount, caster:GetPlayerOwner())

    if hero ~= caster then
      SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, hero, manaReplenishAmount, caster:GetPlayerOwner())
    end
  end

  local function ReplenishHealth(hero)
    local healAmount = self:GetSpecialValueFor("replenish_health")
    hero:Heal(healAmount, self)
    hero:AddNewModifier(caster, self, "modifier_item_mekansm_noheal", {duration = self:GetCooldownTime() - 2})

    local particleHealName = "particles/items3_fx/warmage_recipient.vpcf"
    local particleHealNonHeroName = "particles/items3_fx/warmage_recipient_nonhero.vpcf"

    SendOverheadEventMessage(caster:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, hero, healAmount, caster:GetPlayerOwner())

    if hero ~= caster then
      SendOverheadEventMessage(hero:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, hero, healAmount, caster:GetPlayerOwner())
    end

    if hero:IsHero() then
      local particleHeal = ParticleManager:CreateParticle(particleHealName, PATTACH_ABSORIGIN_FOLLOW, hero)
      ParticleManager:ReleaseParticleIndex(particleHeal)
    else
      local particleHealNonHero = ParticleManager:CreateParticle(particleHealNonHeroName, PATTACH_ABSORIGIN_FOLLOW, hero)
      ParticleManager:ReleaseParticleIndex(particleHealNonHero)
    end

    hero:EmitSound("Item.GuardianGreaves.Target")
  end

  heroes = iter(heroes)
  -- Give Mana to all heroes
  foreach(ReplenishMana, heroes)
  -- Only Heal heroes without the Heal Cooldown modifier
  foreach(ReplenishHealth, filter(HasNoHealCooldown, heroes))

  local particleCastName = "particles/items3_fx/warmage.vpcf"
  local particleCast = ParticleManager:CreateParticle(particleCastName, PATTACH_ABSORIGIN, caster)
  ParticleManager:ReleaseParticleIndex(particleCast)
  caster:EmitSound("Item.GuardianGreaves.Activate")
end

function item_greater_guardian_greaves:GetIntrinsicModifierName()
  return "modifier_item_greater_guardian_greaves" -- "modifier_intrinsic_multiplexer"
end
-- uncomment this if we plan to add more effects to Guardian Greaves
--[[
function item_greater_guardian_greaves:GetIntrinsicModifierNames()
  return {
    "modifier_item_greater_guardian_greaves",
  }
end
]]

item_greater_guardian_greaves_2 = item_greater_guardian_greaves
item_greater_guardian_greaves_3 = item_greater_guardian_greaves
item_greater_guardian_greaves_4 = item_greater_guardian_greaves
item_greater_guardian_greaves_5 = item_greater_guardian_greaves

------------------------------------------------------------------------------

modifier_item_greater_guardian_greaves = class(ModifierBaseClass)

function modifier_item_greater_guardian_greaves:IsHidden()
  return true
end

function modifier_item_greater_guardian_greaves:IsPurgable()
  return false
end

function modifier_item_greater_guardian_greaves:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_greater_guardian_greaves:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    -- Remove effect modifiers from units in radius to force refresh
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      parent:GetAbsOrigin(),
      nil,
      self:GetAbility():GetSpecialValueFor("aura_radius"),
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function RemoveGuardianAuraEffect(unit)
      unit:RemoveModifierByName("modifier_item_guardian_greaves_aura")
    end

    foreach(RemoveGuardianAuraEffect, units)
  end
end

modifier_item_greater_guardian_greaves.OnRefresh = modifier_item_greater_guardian_greaves.OnCreated

function modifier_item_greater_guardian_greaves:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_all_stats")
end
function modifier_item_greater_guardian_greaves:GetModifierMoveSpeedBonus_Percentage_Unique()
  return self:GetAbility():GetSpecialValueFor("bonus_movement")
end
function modifier_item_greater_guardian_greaves:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end
function modifier_item_greater_guardian_greaves:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_item_greater_guardian_greaves:IsAura()
  return true
end

function modifier_item_greater_guardian_greaves:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_item_greater_guardian_greaves:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_greater_guardian_greaves:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_greater_guardian_greaves:GetModifierAura()
  return "modifier_item_guardian_greaves_aura" -- modifier_item_greater_guardian_greaves_aura ?
end

------------------------------------------------------------------------------

modifier_item_greater_guardian_greaves_aura = class({})

function modifier_item_greater_guardian_greaves_aura:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
  }
end

function modifier_item_greater_guardian_greaves_aura:GetModifierConstantHealthRegen()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_health_regen_bonus")
  else
    return self:GetAbility():GetSpecialValueFor("aura_health_regen")
  end
end

function modifier_item_greater_guardian_greaves_aura:GetModifierPhysicalArmorBonus()
  local hero = self:GetParent()
  if not hero or not hero.GetHealth then
    return
  end
  local hpPercent = (hero:GetHealth() / hero:GetMaxHealth()) * 100
  if hpPercent < self:GetAbility():GetSpecialValueFor("aura_bonus_threshold") then
    return self:GetAbility():GetSpecialValueFor("aura_armor_bonus")
  else
    return 0
  end
end
