-- Taken from bb template
if Duels == nil then
  DebugPrint ( 'Creating new Duels object.' )
  Duels = class({})

  -- debugging lines, enable logging and enable chat commands to start/stop duels

  Debug.EnabledModules['duels:*'] = true
  Debug.EnabledModules['zonecontrol:*'] = true

  ChatCommand:LinkCommand("-duel", "QueueDuels", Duels)
  ChatCommand:LinkCommand("-end_duel", "EndDuels", Duels)
end

function Duels:Init ()
  DebugPrint('Init duels')

  self.zone1 = ZoneControl:CreateZone('duel_1', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {
    }
  })

  self.zone2 = ZoneControl:CreateZone('duel_2', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {
    }
  })
  self.teams = Duels:GetTeams()

  Timers:CreateTimer(1, function ()
    Duels:QueueDuels()
  end)

end

function Duels:QueueDuels()
  Notifications:TopToAll({text="A duel will start in 10 seconds!", duration=5.0})
  for index = 1,5 do
    Timers:CreateTimer(4 + index, function ()
      Notifications:TopToAll({text=(6 - index), duration=1.0})
    end)
  end

  Timers:CreateTimer(10, function ()
    Notifications:TopToAll({text="DUEL!", duration=3.0, style={color="red", ["font-size"]="110px"}})
    Duels:CreateDuels()
  end)
end

function Duels:GetTeams()
  local teams = {{},{}}

  for playerId = 0,19 do
    local player = PlayerResource:GetPlayer(playerId)
	  if player:GetTeam() == 3 then
	    table.insert(teams[1], player)
	  elseif player:GetTeam() == 2 then
	    table.insert(teams[2], player)
	  end
  end
  return teams
end

function Duels:ShuffleTeams()
  for _,t in self.teams do
    local n = #t
    while n > 2 do
      local k = math.random(n)
      t[n], t[k] = t[k], t[n]
      n = n - 1
    end
  end
end

function Duels:GetSpawns(zone)
  local spawnLocations = math.random(0, 1) == 1
  local spawn1 = Entities:FindByName(nil, 'duel_'..zone..'_spawn_1'):GetAbsOrigin()
  local spawn2 = Entities:FindByName(nil, 'duel_'..zone..'_spawn_2'):GetAbsOrigin()

  if spawnLocations then
    local tmp = spawn1
    spawn1 = spawn2
    spawn2 = tmp
  end

  return {spawn1, spawn2}
end

function Duels:CreateDuels()
  local maxPlayers = 20
  for _, team in self.teams do
    if #team < maxPlayers then
	    maxPlayers = #team
	  end
  end

  DebugPrint('Max players per team for this duel ' .. maxPlayers)

  if maxPlayers < 1 then
    DebugPrint('There aren\'t enough players to start the duel')
    Notifications:TopToAll({text="There aren\'t enough players to start the duel", duration=2.0})
    return
  end

  local playerSplitOffset = math.random(0, maxPlayers)

  Duels:ShuffleTeams()

  local duelists = {{},{}}
  for playerNumber = 1,playerSplitOffset do
    for index, team in pairs(self.teams) do
	    table.insert(duelists[index], team[playerNumber])
	  end
  end

  local spawns = Duels:GetSpawns(1)
  self.duel1 = duelLib.Duel(duelists, spawns, self.zone1)

  local duelists2 = {{},{}}
  for playerNumber = playerSplitOffset+1, maxPlayers do
    for index, team in pairs(self.teams) do
	    table.insert(duelists[index], team[playerNumber])
	  end
  end

  local spawns2 = Duels.GetSpawns(2)
  self.duel2 = duelLib.Duel(duelists2, spawns2, self.zone2)

  Timers:CreateTimer(90, Dynamic_Wrap(Duels, 'EndDuels'))
end

function Duels:EndDuels ()
  local nextDuelIn = 300
  -- why dont these run?
  Timers:CreateTimer(nextDuelIn, Dynamic_Wrap(Duels, 'Warn'))
  Timers:CreateTimer(nextDuelIn - 50, function ()
    Notifications:TopToAll({text="A duel will start in 1 minute!", duration=10.0})
  end)

  if not self.duel1.over then
    self.duel1.EndDuel()
  end
  if not self.duel2.over then
    self.duel2.EndDuel()
  end
  DebugPrint('Duel has ended')
end

