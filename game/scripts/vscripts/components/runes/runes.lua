
Runes = Runes or {}

function Runes:Init()
  Debug.EnableDebugging()
  DebugPrint('Init runes')

  local all_runes = Entities:FindAllByClassname("dota_item_rune")
  local hud_time = HudTimer:GetGameTime() -- it prints 0 at init

	-- Uncomment this if we are implementing custom runes
	--[[
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

	--]]

	-- Remove all runes
  for _,rune in pairs(all_runes) do
		UTIL_Remove(rune)
  end

	-- Start a timer after FIRST_BOUNTY_RUNE_SPAWN_TIME delay and repeat every BOUNTY_RUNE_SPAWN_INTERVAL seconds
	Timers:CreateTimer(FIRST_BOUNTY_RUNE_SPAWN_TIME, function()
		self:SpawnRunes("bounty")
		return BOUNTY_RUNE_SPAWN_INTERVAL
	end)

	-- Start a timer after FIRST_POWER_RUNE_SPAWN_TIME delay and repeat every POWER_RUNE_SPAWN_INTERVAL seconds
	Timers:CreateTimer(FIRST_POWER_RUNE_SPAWN_TIME, function()
		self:SpawnRunes("powerup")
		return POWER_RUNE_SPAWN_INTERVAL
	end)

  -- Check every 0.5 second if there is a rune spawned that is not supposed to spawn and hide it
  Timers:CreateTimer(function()
		self:CheckFindRunes()
		return 0.5
  end)

  Timers:CreateTimer(function()
		self:CheckFindRunes()
		return 0.5
  end)

  -- RuneSpawnFilter doesn't work, thanks Valve
  --FilterManager:AddFilter(FilterManager.RuneSpawn, self, Dynamic_Wrap(Runes, "RunesSpawnFilter"))
end

function Runes:HideRunes(runes)
	for _,rune in pairs(runes) do
		local origin = rune:GetOrigin()
		rune:SetOrigin(Vector(origin.x, origin.y, origin.z - 1000))
		rune.hidden = true
	end
end

function Runes:UnhideRunes(runes)
	for _,rune in pairs(runes) do
		if not rune:IsNull() then
			if rune.hidden == true then
				local origin = rune:GetOrigin()
				rune:SetOrigin(Vector(origin.x, origin.y, origin.z + 1000))
				rune.hidden = false
			end
		end
	end
end

--[[
function Runes:SortRunes(runes)
	if self.powerup_runes == nil then
		self.powerup_runes = {}
	end
	if self.bounty_runes == nil then
		self.bounty_runes = {}
	end
	for _,rune in pairs(runes) do
		local rune_model_name = rune:GetModelName()
		if string.find(rune_model_name, "rune_goldxp") then
			table.insert(self.bounty_runes, rune)
		else
			table.insert(self.powerup_runes, rune)
		end
	end
end
--]]

function Runes:FindUndergroundRune(runes)
	local rune_with_minimum_z = runes[1]
	local rune_origin_with_minimum_z = rune_with_minimum_z:GetOrigin()
	local minimum_z = rune_origin_with_minimum_z.z

	for i = 1, #runes do
		local rune_origin = runes[i]:GetOrigin()
		if rune_origin.z < minimum_z then
			minimum_z = rune_origin.z
			rune_with_minimum_z = runes[i]
		end
	end

	return rune_with_minimum_z
end

function Runes:CheckFindRunes()
	local all_runes = Entities:FindAllByClassname("dota_item_rune")
	local unhidden_runes = {}
	for _,rune in pairs(all_runes) do
		if not rune:IsNull() then
			if rune.hidden == nil then
				-- There is a new rune on the map that is not hidden and its not their time to spawn
				table.insert(unhidden_runes, rune)
			end
		end
	end
	if #unhidden_runes > 0 then
		self:HideRunes(unhidden_runes)
	end
end

function Runes:SpawnRunes(rune_type)
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
		if #all_runes_around_spawner > 1 then
			-- If there is more than 1 rune at the spawner, remove the underground one. If more runes are underground, remove one.
			UTIL_Remove(self:FindUndergroundRune(all_runes_around_spawner))
		else
			if all_runes_around_spawner == nil then
				print("Runes module: No runes found around the spawner!")
				return nil
			end
		end
		self:UnhideRunes(all_runes_around_spawner)
	end
end
