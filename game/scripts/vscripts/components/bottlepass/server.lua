Debug:EnableDebugging()
DebugPrint('Bottlepass script loaded')

Bottlepass = Bottlepass or class({})
GameStartTime = GameStartTime or (GetSystemDate() .. GetSystemTime())

BATTLE_PASS_SERVER = 'http://chrisinajar.com:2052/'
AUTH_KEY = GetDedicatedServerKeyV2('1')

if IsInToolsMode() then
  -- test server
  BATTLE_PASS_SERVER = 'http://10.0.0.111:6969/'
end

function Bottlepass:Init ()
  Debug:EnableDebugging()
  self.moduleName = "Bottlepass"
  GameEvents:OnCustomGameSetup(partial(Bottlepass.Ready, self))
  GameEvents:OnGameInProgress(partial(Bottlepass.SendTeams, self))
  self.keepSpamming = true
end

function Bottlepass:StateLoad (players, callback)
  self:Request('state/load', {
    players = players
  }, function (err, data)
    if data and data.state then
      callback(data)
    else
      callback(nil)
    end
  end)
end

function Bottlepass:StateSave (players, state)
  self:Request('state/save', {
    state = state,
    players = players
  }, function (err, data)
    -- state saved! cool!
  end)
end

function Bottlepass:SendWinner (winner)
  if self.winner then
    -- only send winner once
    return
  end

  if winner == DOTA_TEAM_GOODGUYS then
    winner = 'radiant'
  elseif winner == DOTA_TEAM_BADGUYS then
    winner = 'dire'
  end
  self.winner = winner
  DebugPrint('Sending winner data')
  local endTime = GetSystemDate() .. GetSystemTime()
  local gameLength = HudTimer.gameTime
  local connectedPlayers = {}
  local abandonedPlayers = {}

  local playerBySteamid = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) and not PlayerResource:IsBlackBoxPlayer(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      local player = PlayerResource:GetPlayer(playerID)
      playerBySteamid[tostring(steamid)] = playerID

      if player then
        table.insert(connectedPlayers, tostring(steamid))
      elseif PlayerConnection:IsAbandoned(playerID) then
        table.insert(abandonedPlayers, tostring(steamid))
      end
    end
  end

  local req = self:Request('match/complete', {
    winner = winner,
    endTime = endTime,
    gameLength = gameLength,
    players = connectedPlayers,
    abandoned = abandonedPlayers,
    -- let player connection decide if this game should count
    isValid = PlayerConnection:IsValid() and not Bottlepass:IsInvalidForTracking()
  }, function (err, data)
    if data and data.ok then
      local mmrDiffs = {}
      DebugPrintTable(data)
      for _, bottlePlayer in ipairs(data.playerDiffs) do
        local playerID = playerBySteamid[bottlePlayer.steamid]
        mmrDiffs[playerID] = {
          imr = bottlePlayer.mmr,
          imr_diff = bottlePlayer.mmrDiff,
        }
      end

      Bottlepass.mmrDiffs = mmrDiffs
      Bottlepass:SendEndGameStats()
    end
--[[
  ok: true
  playerDiffs:
      1:
      2:
          1:
              bottlepass:
                  levelUp: 0
                  xp: 0
              mmr: 0
              steamid: 7131038

    // player.result.imr_calibrating = false;
    // player.result.imr = 1594;
    // player.result.imr_diff = +9;
    // player.result.xp_diff = 600;
    // player.result.xp = 500;
    // player.result.max_xp = 1000;

    // player.xp = [];
    // player.xp.level = 2;
]]
  end)

  if not req then
    Bottlepass:SendEndGameStats()
  end
end

function Bottlepass:SendBans (data)
  DebugPrint('Sending pick screen ban data')
  local banChoices = {}
  local didBan = false

  for playerID, choice in pairs(data.banChoices) do
    if PlayerResource:IsValidPlayerID(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      if steamid ~= 0 then -- bots and black box players have 0 steamid
        steamid = tostring(steamid)
        didBan = true
        banChoices[steamid] = choice
      end
    end
  end
  if didBan and not self:IsInvalidForTracking() then
    self:Request('match/send_bans', {
      banChoices = banChoices,
      bans = data.bans
    }, function (err, response)
      DebugPrintTable(response)
    end)
  end
end

function Bottlepass:SendHeroPicks (data)
  Debug:EnableDebugging()
  DebugPrint('Sending pick screen hero pick data')
  local heroPicks = {}
  local didPick = false

  for playerID, choiceTable in pairs(data) do
    if PlayerResource:IsValidPlayerID(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      if steamid ~= 0 then -- bots and black box players have 0 steamid
        steamid = tostring(steamid)
        didPick = true
        heroPicks[steamid] = {
          hero = choiceTable.selectedhero,
          random = choiceTable.didRandom == "true" or choiceTable.didRandom == "rerandomed",
          rerandom = choiceTable.didRandom == "rerandomed"
        }
      end
    end
  end
  if didPick then
    self:Request('match/send_heroes', {
      picks = heroPicks
    }, function (err, response)
      DebugPrintTable(response)
    end)
  end
end

function Bottlepass:SendTeams ()
  DebugPrint('Sending team data')
  local dire = {}
  local radiant = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      if steamid ~= 0 then -- bots and black box players have 0 steamid
        steamid = tostring(steamid)
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
          table.insert(radiant, steamid)
        else
          table.insert(dire, steamid)
        end
      end
    end
  end
  self:Request('match/send_teams', {
    dire = dire,
    radiant = radiant
  }, function (err, response)
    DebugPrintTable(response)
  end)
end

function Bottlepass:GetUnpopularHeroes (callback)
  DebugPrint('Fetching unpopular hero pick list')

  local heroList = HeroSelection:GetHeroList()
  local heroes = {}
  for key,_ in pairs(heroList) do
    table.insert(heroes, key)
  end

  self:Request('match/unpopular_heroes', {
    heroes = heroes
  }, function (err, response)
    DebugPrintTable(response)
    callback(response)
  end)
end

function Bottlepass:Ready ()
  local userList = {}
  local hostId = 0
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      if steamid ~= 0 then -- bots and black box players have 0 steamid
        table.insert(userList, steamid)

        local player = PlayerResource:GetPlayer(playerID)
        if player and GameRules:PlayerHasCustomGameHostPrivileges(player) then
          hostId = steamid
        end
      end
    end
  end

  if hostId ~= 7131038 and IsInToolsMode() then
    -- Stop trying to contact the server in tools when I am working, Idk how other devs tolerated this
    -- bwahahahahahaha keepSpamming, best keyname xD
    self.keepSpamming = false
    return
  end

  DebugPrint('Sending auth request ' .. GameStartTime)
  DebugPrint(BATTLE_PASS_SERVER .. 'auth')

  self:Request('auth', {
    users = userList,
    gametime = GameStartTime,
    toolsMode = IsInToolsMode(),
    hostId = hostId,
    cheatsMode = GameRules:IsCheatMode(),
    isRanked = HeroSelection.isRanked,
    isCM = HeroSelection.isCM,
  }, function (err, data)
    if err then
      DebugPrint(err)
    end
    if data then
      DebugPrint('Authed with dev server!')
      self.token = data.token
      self.userData = data.userData
      CustomNetTables:SetTableValue( 'bottlepass', 'user_data', data.userData )
      MMRShuffle:UpdateAverageMMRs()
    end
  end)
end

function Bottlepass:Request(api, data, cb)
  if HeroSelection.isARDM then
    cb("No bottlepass in ARDM", {})
    return
  end
  if GameRules:IsCheatMode() and not IsInToolsMode() then
    cb("No Bottlepass while in cheats mode", {})
    return
  end

  local req = CreateHTTPRequestScriptVM('POST', BATTLE_PASS_SERVER .. api)
  local encoded = json.encode(data)

  local authToken = sha256(encoded .. AUTH_KEY)

  req:SetHTTPRequestHeaderValue("Auth-Checksum", authToken)
  req:SetHTTPRequestHeaderValue("Accept", "application/json")
  if self.token then
    req:SetHTTPRequestHeaderValue('X-Auth-Token', self.token)
  end

  -- Add the data
  req:SetHTTPRequestRawPostBody('application/json', encoded)

  -- Send the request
  req:Send(function(res)
    if res.StatusCode ~= 200 then
      if Bottlepass.keepSpamming == true then
        DebugPrint("Failed to contact server")
        DebugPrint("Status Code", res.StatusCode or "nil")
        DebugPrint("Body", res.Body or "nil")
      end
      return cb(res.Body or res.StatusCode)
    end

    if not res.Body then
      DebugPrint("So result returned from server")
      DebugPrint("Status Code", res.StatusCode or "nil")
      return cb('No content returned from server')
    end

    -- Try to decode the result
    local obj, pos, err = json.decode(res.Body, 1, nil) --luacheck: ignore pos

    cb(err, obj)
  end)
end

-- Dont track bans and mmr changes if conditions are met
function Bottlepass:IsInvalidForTracking()
  if HeroSelection.is10v10 then
    return true
  end
  if OAAOptions then
    if OAAOptions.settings then
      local s = OAAOptions.settings
      if s.HEROES_MODS ~= "HMN" or s.HEROES_MODS_2 ~= "HMN" or s.HEROES_MODS_BUNDLE ~= "HMBN" or s.BOSSES_MODS ~= "BMN" then
        return true
      end
    end
  end
  return false
end
