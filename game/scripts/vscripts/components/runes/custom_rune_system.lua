-- For inspiration look here: https://github.com/EarthSalamander42/dota_imba/blob/master/game/dota_addons/dota_imba_reborn/scripts/vscripts/components/runes.lua

Custom_Rune_System = Custom_Rune_System or {}

function Custom_Rune_System:Init()
  Debug.EnableDebugging()
  DebugPrint('Init Custom Rune System module')
  -- Power-up Runes
  local powerup_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_powerup")
  self.powerup_rune_locations = {}

  -- Remove power-up rune spawner entities
  for i = 1, #powerup_rune_spawners do
    self.powerup_rune_locations[i] = powerup_rune_spawners[i]:GetAbsOrigin()
    powerup_rune_spawners[i]:RemoveSelf()
  end

  -- Start a timer after FIRST_POWER_RUNE_SPAWN_TIME delay and repeat every POWER_RUNE_SPAWN_INTERVAL seconds
  Timers:CreateTimer(FIRST_POWER_RUNE_SPAWN_TIME, function()
    Custom_Rune_System:SpawnRunes("powerup")
    return POWER_RUNE_SPAWN_INTERVAL
  end)

  self.power_runes_enums = {
    DOTA_RUNE_DOUBLEDAMAGE,
    DOTA_RUNE_HASTE,
    DOTA_RUNE_ILLUSION,
    DOTA_RUNE_INVISIBILITY,
    DOTA_RUNE_REGENERATION,
    DOTA_RUNE_ARCANE,
    DOTA_RUNE_WATER,
  }

  -- Bounty Runes (we will use vanilla for now)
  --local bounty_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_bounty")
  --self.bounty_rune_locations = {}
  -- Remove bounty rune spawner entities
  --for i = 1, #bounty_rune_spawners do
    --self.bounty_rune_locations[i] = bounty_rune_spawners[i]:GetAbsOrigin()
    --bounty_rune_spawners[i]:RemoveSelf()
  --end

  -- Start a timer after FIRST_BOUNTY_RUNE_SPAWN_TIME delay and repeat every BOUNTY_RUNE_SPAWN_INTERVAL seconds
  --Timers:CreateTimer(FIRST_BOUNTY_RUNE_SPAWN_TIME, function()
    --Custom_Rune_System:SpawnRunes("bounty")
    --return BOUNTY_RUNE_SPAWN_INTERVAL
  --end)
end

function Custom_Rune_System:SpawnRunes(rune_type)
	local rune_locations = {}
	if rune_type == "bounty" then
		rune_locations = self.bounty_rune_locations
	elseif rune_type == "powerup" then
		rune_locations = self.powerup_rune_locations
	else
		DebugPrint("Custom_Rune_System: Invalid rune_type for spawning.")
		return
	end

	if rune_locations == nil or rune_locations == {} then
		DebugPrint("Custom_Rune_System: Invalid rune locations.")
		return
	end

	for i = 1, #rune_locations do
    -- Remove all DotA runes around the spawner first
    self:RemoveRuneAroundLocation(rune_locations[i])
    -- Actually Spawn Rune at rune location
    if rune_type == "bounty" then
      CreateRune(rune_locations[i], DOTA_RUNE_BOUNTY)
    else
      local random_int = RandomInt(1, #self.power_runes_enums)
      local rune_to_spawn = self.power_runes_enums[random_int]
      CreateRune(rune_locations[i], rune_to_spawn)
    end
	end
end

function Custom_Rune_System:RemoveRuneAroundLocation(location)
  if not location then
    DebugPrint("Custom_Rune_System: location in RemoveRuneAroundLocation is nil!")
    return
  end
  local all_runes_around_location = Entities:FindAllByClassnameWithin("dota_item_rune", location, 1200)
  if all_runes_around_location == nil then
    DebugPrint("Custom_Rune_System: No runes found around the specified location!")
    return
  end
  -- Remove all DotA runes near the location
  for _, rune in pairs(all_runes_around_location) do
    if rune and not rune:IsNull() then
      UTIL_Remove(rune)
    end
  end
end
