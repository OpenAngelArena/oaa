
SaveLoadState = SaveLoadState or class({})

Debug:EnableDebugging()

local SaveLoadModules = {
  creeps = CreepCamps,
  time = HudTimer,
  points = PointsManager,
  bosses = BossSpawner,
  gold = Gold,
  heroes = SaveLoadStateHero,
  capturePoints = CapturePoints
}

function SaveLoadState:Init ()
  -- don't ever do or trigger anything before this point
  if not SAVE_STATE_ENABLED then
    return
  end

  -- once this is tested just remove the linkcommands

  ChatCommand:LinkCommand("-load", function ()
    -- check if we can resume state
    Bottlepass:StateLoad(self:GetPlayerList(), function (data)
      if not data then
        return
      end
      PauseGame(true)
      self:LoadState(data.state)
    end)
  end)

  ChatCommand:LinkCommand("-state", function ()
    local data = self:GetState()
    DebugPrintTable(data)
    DebugPrint(json.encode(data))
  end)

  -- Timers:CreateTimer(BOSS_RESPAWN_START, function ()
  ChatCommand:LinkCommand("-save", function ()
    -- start auto-saving after beasts have spawned
    if not Duels:IsActive() then
      local data = self:GetState()
      Bottlepass:StateSave(self:GetPlayerList(), data)
    end

    return SAVE_STATE_INTERVAL
  end)
end

function SaveLoadState:GetState ()
  local state = {}
  for name,Module in pairs(SaveLoadModules) do
    state[name] = Module:GetState()
  end

  return state
end

function SaveLoadState:LoadState (state)
  for name,Module in pairs(SaveLoadModules) do
    Module:LoadState(state[name])
  end
end

function SaveLoadState:GetPlayerList ()
  local players = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local hero = PlayerResource:GetSelectedHeroName(playerID)
    local steamid = PlayerResource:GetSteamAccountID(playerID)

    table.insert(players, {
      hero = hero,
      steamid = steamid
    })
  end

  return players
end
