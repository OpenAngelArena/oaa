
SaveLoadState = SaveLoadState or class({})

local SaveLoadModules = {
  creeps = CreepCamps,
  time = HudTimer,
  points = PointsManager,
  bosses = BossSpawner,
  gold = Gold,
  heroes = SaveLoadStateHero,
  capturePoints = CapturePoints,
  corePoints = CorePointsManager,
  wandererStatus = Wanderer,
  grendelStatus = Grendel,
}

function SaveLoadState:Init ()
  -- don't ever do or trigger anything before this point
  if not SAVE_STATE_ENABLED then
    return
  end

  self.moduleName = "SaveLoadState"

  -- check if we can resume state
  Bottlepass:StateLoad(self:GetPlayerList(), function (data)
    if not data or not data.state then
      return
    end
    PauseGame(true)
    self:LoadState(data.state)
  end)

  ChatCommand:LinkDevCommand("-state", function ()
    local data = self:GetState()
    DebugPrintTable(data)
    DebugPrint(json.encode(data))
  end)

  Timers:CreateTimer(BOSS_RESPAWN_START, function ()
  -- ChatCommand:LinkCommand("-save", function ()
    -- start auto-saving after beasts have spawned
    if not Duels:IsActive() and not PlayerConnection:IsAnyDisconnected() then
      local data = SaveLoadState:GetState()
      Bottlepass:StateSave(SaveLoadState:GetPlayerList(), data)
    end

    return SAVE_STATE_INTERVAL
  end)
end

function SaveLoadState:GetState ()
  local state = {}
  for name, Module in pairs(SaveLoadModules) do
    state[name] = Module:GetState()
  end

  return state
end

function SaveLoadState:LoadState (state)
  DebugPrintTable(state)
  for name, Module in pairs(SaveLoadModules) do
    DebugPrint(name .. ' loading state')
    DebugPrintTable(state[name])
    Module:LoadState(state[name])
  end
end

function SaveLoadState:GetPlayerList ()
  local players = {
    radiant = {},
    dire = {}
  }

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:IsValidPlayer(playerID) then
      local hero = PlayerResource:GetSelectedHeroName(playerID)
      local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))

      if steamid ~= '0' then
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
          table.insert(players.radiant, {
            hero = hero,
            steamid = tostring(steamid)
          })
        elseif PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
          table.insert(players.dire, {
            hero = hero,
            steamid = tostring(steamid)
          })
        end
      end
    end
  end

  return players
end
