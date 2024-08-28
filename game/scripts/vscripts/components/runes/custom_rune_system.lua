-- For inspiration look here: https://github.com/EarthSalamander42/dota_imba/blob/master/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/runes.lua

CustomRuneSystem = CustomRuneSystem or class({})

function CustomRuneSystem:Init()
  --Debug.EnableDebugging()
  DebugPrint('Init Custom Rune System module')

  self.moduleName = "CustomRuneSystem"

  if USE_DEFAULT_RUNE_SYSTEM == true then
    return
  end

  local hidden_point = Vector(-10000, -10000, -10000)

  -- Power-up Runes
  local powerup_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_powerup") -- vanilla power-up spawners
  --local powerup_rune_spawners = Entities:FindAllByName("custom_powerup_rune_spot") -- Map needs an entity with this name
  self.powerup_rune_locations = {}

  -- Remove power-up rune spawner entities
  for i = 1, #powerup_rune_spawners do
    self.powerup_rune_locations[i] = powerup_rune_spawners[i]:GetAbsOrigin()
    -- Hide the vanilla spawner
    powerup_rune_spawners[i]:SetOrigin(hidden_point)
    --powerup_rune_spawners[i]:RemoveSelf() -- crashes, don't use it
  end

  if HudTimer then
    HudTimer:At(FIRST_POWER_RUNE_SPAWN_TIME, function()
      CustomRuneSystem:SpawnRunes("powerup")
    end)
  else
    Timers:CreateTimer(FIRST_POWER_RUNE_SPAWN_TIME + PREGAME_TIME, function()
      CustomRuneSystem:SpawnRunes("powerup")
    end)
  end

  self.power_runes_enums = {
    DOTA_RUNE_DOUBLEDAMAGE,
    DOTA_RUNE_HASTE,
    DOTA_RUNE_ILLUSION,
    DOTA_RUNE_INVISIBILITY,
    DOTA_RUNE_REGENERATION,
    DOTA_RUNE_ARCANE,
    DOTA_RUNE_SHIELD,
    --DOTA_RUNE_WATER,
  }

  -- Bounty Runes
  local bounty_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_bounty") -- vanilla bounty rune spawners
  --local bounty_rune_spawners = Entities:FindAllByName("custom_bounty_rune_spot") -- Map needs an entity with this name
  self.bounty_rune_locations = {}

  -- Remove bounty rune spawner entities
  for i = 1, #bounty_rune_spawners do
    self.bounty_rune_locations[i] = bounty_rune_spawners[i]:GetAbsOrigin()
    -- Hide the vanilla spawner
    bounty_rune_spawners[i]:SetOrigin(hidden_point)
  end

  if HudTimer then
    HudTimer:At(FIRST_BOUNTY_RUNE_SPAWN_TIME, function()
      CustomRuneSystem:SpawnRunes("bounty")
    end)
  else
    Timers:CreateTimer(FIRST_BOUNTY_RUNE_SPAWN_TIME + PREGAME_TIME, function()
      CustomRuneSystem:SpawnRunes("bounty")
    end)
  end
end

function CustomRuneSystem:SpawnRunes(rune_type)
  local rune_locations = {}
  local spawn_interval = 60
  if rune_type == "bounty" then
    rune_locations = self.bounty_rune_locations
    spawn_interval = BOUNTY_RUNE_SPAWN_INTERVAL
  elseif rune_type == "powerup" then
    rune_locations = self.powerup_rune_locations
    spawn_interval = POWER_RUNE_SPAWN_INTERVAL
  else
    DebugPrint("CustomRuneSystem: Invalid rune_type for spawning.")
    return
  end

  if rune_locations == nil or rune_locations == {} then
    DebugPrint("CustomRuneSystem: Invalid rune locations.")
    return
  end

  -- Remove all DotA runes around the spawners first
  for i = 1, #rune_locations do
    self:RemoveRuneAroundLocation(rune_locations[i])
  end

  -- Actually Spawn Rune at rune locations
  Timers:CreateTimer(0.03, function()
    for i = 1, #rune_locations do
      if rune_type == "bounty" then
        CreateRune(rune_locations[i], DOTA_RUNE_BOUNTY)
      else
        local random_int = RandomInt(1, #CustomRuneSystem.power_runes_enums)
        local rune_to_spawn = CustomRuneSystem.power_runes_enums[random_int]
        CreateRune(rune_locations[i], rune_to_spawn)
        if not CustomRuneSystem.rune_protector or CustomRuneSystem.rune_protector:IsNull() or not CustomRuneSystem.rune_protector:IsAlive() then
          CustomRuneSystem.rune_protector = CreateUnitByName("npc_dota_neutral_custom_rune_protector", rune_locations[i] + Vector(0, 200, 0), true, nil, nil, DOTA_TEAM_NEUTRALS)
        end
      end
    end
  end)

  -- Repeat all this after spawn_interval
  if HudTimer then
    local current_time = HudTimer:GetGameTime()
    HudTimer:At(current_time + spawn_interval, function()
      CustomRuneSystem:SpawnRunes(rune_type)
    end)
  else
    Timers:CreateTimer(spawn_interval, function()
      CustomRuneSystem:SpawnRunes(rune_type)
    end)
  end
end

function CustomRuneSystem:RemoveRuneAroundLocation(location)
  if not location then
    DebugPrint("CustomRuneSystem: location in RemoveRuneAroundLocation is nil!")
    return
  end
  local all_runes_around_location = Entities:FindAllByClassnameWithin("dota_item_rune", location, 1200)
  if all_runes_around_location == nil then
    --DebugPrint("CustomRuneSystem: No runes found around the specified location!")
    return
  end
  -- Remove all DotA runes near the location
  for _, rune in pairs(all_runes_around_location) do
    if rune and not rune:IsNull() then
      UTIL_Remove(rune)
    end
  end
end
