
Custom_Rune_System = Custom_Rune_System or {}

function Custom_Rune_System:Init()
  Debug.EnableDebugging()
  DebugPrint('Init Custom Rune System module')
  local powerup_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_powerup")
  local bounty_rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_bounty")
  local powerup_rune_locations = {}
  local bounty_rune_locations = {}
  for i = 1, #powerup_rune_spawners do
    powerup_rune_locations[i] = powerup_rune_spawners[i]:GetAbsOrigin()
    powerup_rune_spawners[i]:RemoveSelf()
  end
  for i = 1, #bounty_rune_spawners do
    bounty_rune_locations[i] = bounty_rune_spawners[i]:GetAbsOrigin()
    bounty_rune_spawners[i]:RemoveSelf()
  end
  -- Remove all DoTA runes
  for _,rune in pairs(all_runes) do
    UTIL_Remove(rune)
  end
  -- Start a timer after FIRST_BOUNTY_RUNE_SPAWN_TIME delay and repeat every BOUNTY_RUNE_SPAWN_INTERVAL seconds
  Timers:CreateTimer(FIRST_BOUNTY_RUNE_SPAWN_TIME, function()
    --self:SpawnRunes("bounty")
    return BOUNTY_RUNE_SPAWN_INTERVAL
  end)
  -- Start a timer after FIRST_POWER_RUNE_SPAWN_TIME delay and repeat every POWER_RUNE_SPAWN_INTERVAL seconds
  Timers:CreateTimer(FIRST_POWER_RUNE_SPAWN_TIME, function()
    --self:SpawnRunes("powerup")
    return POWER_RUNE_SPAWN_INTERVAL
  end)
end

function Custom_Rune_System:SpawnRunes(rune_type)
	local rune_spawners = {}
	if rune_type == "bounty" then
		rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_bounty")
	elseif rune_type == "powerup" then
		rune_spawners = Entities:FindAllByClassname("dota_item_rune_spawner_powerup")
	else
		print("Runes module: Invalid rune_type for spawning.")
		return nil
	end

	if rune_spawners == nil or rune_spawners == {} then
		print("Runes module: There are no rune spawners entities on the map.")
		return nil
	end

	for i = 1, #rune_spawners do
		local rune_location = rune_spawners[i]:GetAbsOrigin()
		local all_runes_around_spawner = Entities:FindAllByClassnameWithin("dota_item_rune", rune_location, 1200)
		if all_runes_around_spawner == nil then
			print("Runes module: No runes found around the spawner!")
			return nil
		end
		-- Remove all DotA runes around the spawner first
		for _,rune in pairs(all_runes_around_spawner) do
			UTIL_Remove(rune)
		end

		-- Actually Spawn Rune at rune_location
	end
end
