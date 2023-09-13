-- This module contains functions for teleporting heroes including their summons
-- and with handling for special cases where heroes might be in an exiled state

local export = {}

local function SafeTeleport(unit, location, maxDistance)
  unit:Stop()
  if unit:FindModifierByName("modifier_life_stealer_infest") then
    DebugPrint("Found Lifestealer infesting")
    local ability = unit:FindAbilityByName("life_stealer_consume")
    if ability and ability:IsActivated() then
      unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
    else
      print("Error: Tried to teleport an Infesting unit, but could not find Consume ability on that unit, or ability was not castable")
    end
  end
  if unit:FindModifierByName("modifier_life_stealer_assimilate_effect") then
    DebugPrint("Found Lifestealer with assimilated unit")
    local ability = unit:FindAbilityByName("life_stealer_assimilate_eject")
    if ability and ability:IsActivated() then
      unit:CastAbilityNoTarget(ability, unit:GetPlayerOwnerID())
    else
      print("Error: Tried to teleport an Assimilating unit, but could not find Eject ability on that unit, or ability was not castable")
    end
  end
  local exileModifiers = {
    "modifier_obsidian_destroyer_astral_imprisonment_prison",
    --"modifier_riki_tricks_of_the_trade_phase", -- Should be removed by stop order
    --"modifier_puck_phase_shift", -- Should be removed by stop order
    "modifier_phoenix_supernova_hiding",
    "modifier_shadow_demon_disruption",
    -- Removing Snowball movement modifiers just seems to cause glitches instead of helping
    -- "modifier_tusk_snowball_movement",
    -- "modifier_tusk_snowball_movement_friendly",
    "modifier_tusk_snowball_visible", -- Gets applied to snowball targets; grants vision of target
    "modifier_tusk_snowball_target", -- Gets applied to snowball targets; places indicator above target(?)
  }
  iter(exileModifiers):foreach(partial(unit.RemoveModifierByName, unit))

  location = GetGroundPosition(location, unit)
  FindClearSpaceForUnit(unit, location, true)
  Timers:CreateTimer(0.1, function()
    if not unit or unit:IsNull() then
      return
    end
    local distance = (location - unit:GetAbsOrigin()):Length2D()
    if distance > maxDistance then
      SafeTeleport(unit, location, maxDistance+50)
      -- Increase the maxDistance by 50 to eventually stop and not cause the infinite loop
      -- This should stop the infinite glitching of the hero
    end
  end)
end

local function CheckIfUnitIsValidForTeleport(unit)
  if not unit or unit:IsNull() then
    print("Duel Teleport: CheckIfUnitIsValidForTeleport is called for the entity that doesn't exist.")
    return false
  end
  if unit.IsBaseNPC == nil or unit.HasModifier == nil or unit.GetUnitName == nil then
    print("Duel Teleport: CheckIfUnitIsValidForTeleport is called for the invalid entity.")
    return false
  end
  local name = unit:GetUnitName()
  local valid_name = name ~= "npc_dota_custom_dummy_unit" and name ~= "npc_dota_elder_titan_ancestral_spirit" and name ~= "aghsfort_mars_bulwark_soldier"
  local not_thinker = not unit:HasModifier("modifier_oaa_thinker") and not unit:IsPhantomBlocker()

  return not unit:IsCourier() and not unit:IsZombie() and unit:HasMovementCapability() and not_thinker and valid_name
end

local function SafeTeleportAll(mainUnit, location, maxDistance)
  -- Teleport the main hero first
  SafeTeleport(mainUnit, location, maxDistance)

  local playerAdditionalUnits = {} -- mainUnit:GetAdditionalOwnedUnits() or {}
  -- GetAdditionalOwnedUnits is unsuitable here as it apparently only returns hero-like units, like Lone Druid's Bear and such.
  -- It definitely does not return most normal unit summons, including Necronomicon and Broodmother Spiderlings.

  playerAdditionalUnits = FindUnitsInRadius(
    mainUnit:GetTeam(),
    mainUnit:GetAbsOrigin(),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    bit.bor(DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  iter(playerAdditionalUnits)
    :filter(function (unit)
      return unit ~= mainUnit and CheckIfUnitIsValidForTeleport(unit) and unit:GetPlayerOwnerID() == mainUnit:GetPlayerOwnerID()
    end)
    :foreach(function (unit)
      SafeTeleport(unit, location, maxDistance)

      -- Restore hp and mana
      unit:SetHealth(unit:GetMaxHealth())
      unit:SetMana(unit:GetMaxMana())

      -- Disjoint disjointable projectiles
      ProjectileManager:ProjectileDodge(unit)

      -- Absolute Purge (Strong Dispel + removing most undispellable buffs and debuffs)
      unit:AbsolutePurge()
    end)
end

-- Test SafeTeleport function
local function TestSafeTeleport(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  SafeTeleportAll(hero, Vector(0, 0, 0), 150)
end

ChatCommand:LinkDevCommand("-test_tp", TestSafeTeleport, nil)
export.SafeTeleport = SafeTeleport
export.SafeTeleportAll = SafeTeleportAll

return export
