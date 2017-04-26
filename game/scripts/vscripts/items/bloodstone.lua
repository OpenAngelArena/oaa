LinkLuaModifier("modifier_item_bloodstone_oaa", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_bloodstone_charge_collector", "items/bloodstone.lua", LUA_MODIFIER_MOTION_NONE)

item_bloodstone_1 = class({})

function item_bloodstone_1:GetIntrinsicModifierName()
  return "modifier_item_bloodstone_oaa"
end

function item_bloodstone_1:OnSpellStart()
  self:GetCaster():Kill(self, self:GetCaster())
end

-- upgrades
item_bloodstone_2 = item_bloodstone_1
item_bloodstone_3 = item_bloodstone_1
item_bloodstone_4 = item_bloodstone_1
item_bloodstone_5 = item_bloodstone_1

--------------------------------------------------------------------------
-- base modifier, is an aura

modifier_item_bloodstone_oaa = class({})

function modifier_item_bloodstone_oaa:OnCreated()
end
function modifier_item_bloodstone_oaa:OnRefreshed()
end

function modifier_item_bloodstone_oaa:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bloodstone_oaa:IsHidden()
  return true
end
function modifier_item_bloodstone_oaa:IsDebuff()
  return false
end
function modifier_item_bloodstone_oaa:IsPurgable()
  return false
end

function modifier_item_bloodstone_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_BONUS, -- GetModifierHealthBonus
    MODIFIER_PROPERTY_MANA_BONUS, -- GetModifierManaBonus
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, -- GetModifierConstantHealthRegen
    MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE, -- GetModifierPercentageManaRegen
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
  }
end

--------------------------------------------------------------------------
-- bloodstone stats

function modifier_item_bloodstone_oaa:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_bloodstone_oaa:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_bloodstone_oaa:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_bloodstone_oaa:GetModifierPercentageManaRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_item_bloodstone_oaa:GetModifierConstantManaRegen()
  return self:GetAbility():GetCurrentCharges()
end

--------------------------------------------------------------------------
-- charge loss

function modifier_item_bloodstone_oaa:OnDeath(keys)
  local dead = self:GetCaster()

  if dead ~= keys.unit then
    -- someone else died
    return
  end

  local stone = self:GetAbility()
  local oldCharges = stone:GetCurrentCharges()
  local newCharges = math.max(1, math.ceil(oldCharges * stone:GetSpecialValueFor("on_death_removal")))

  stone:SetCurrentCharges(newCharges)

  if not dead:IsRealHero() or dead:IsTempestDouble() then
    return
  end

  local healAmount = stone:GetSpecialValueFor("heal_on_death_base") + (stone:GetSpecialValueFor("heal_on_death_per_charge") * oldCharges)
  local heroes = FindUnitsInRadius(
    dead:GetTeamNumber(),
    dead:GetAbsOrigin(),
    nil,
    stone:GetSpecialValueFor("heal_on_death_range"),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  heroes = iter(heroes)
  heroes:each(function (hero)
    hero:Heal(healAmount, stone)
  end)
end

--------------------------------------------------------------------------
-- aura stuff

function modifier_item_bloodstone_oaa:IsAura()
  return true
end

function modifier_item_bloodstone_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_item_bloodstone_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_bloodstone_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("charge_range")
end

function modifier_item_bloodstone_oaa:GetModifierAura()
  return "modifier_item_bloodstone_charge_collector"
end

--------------------------------------------------------------------------
-- charge collector, stacking modifiers that gives stacks
-- stacking auras don't get applied more than once no matter what

modifier_item_bloodstone_charge_collector = class({})

function modifier_item_bloodstone_charge_collector:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_item_bloodstone_charge_collector:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

-- charge gain
function modifier_item_bloodstone_charge_collector:OnDeath(keys)
  local dead = self:GetParent()

  if dead ~= keys.unit then
    -- someone else died
    return
  end

  local caster = self:GetCaster()

  -- Find the first bloodstone we can
  local found = false
  for i = 0, 5 do
    local item = caster:GetItemInSlot(i)
    if not found and item and string.sub(item:GetAbilityName(), 0, 15) == "item_bloodstone" then
      found = true
      item:SetCurrentCharges( item:GetCurrentCharges() + 1 )
    end
  end
end
