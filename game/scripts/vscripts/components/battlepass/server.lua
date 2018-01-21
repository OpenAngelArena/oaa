
Debug:EnableDebugging()
DebugPrint('Battlepass script loaded')

Battlepass = Battlepass or class({})
GameStartTime = GameStartTime or (GetSystemDate() .. GetSystemTime())

BATTLE_PASS_SERVER = 'http://chrisinajar.com:6969/'

function Battlepass:Init ()
  Debug:EnableDebugging()
  GameEvents:OnCustomGameSetup(partial(Battlepass.Ready, self))
  GameEvents:OnGameInProgress(partial(Battlepass.SendTeams, self))
end

function Battlepass:SendWinner (winner)
  if winner == DOTA_TEAM_GOODGUYS then
    winner = 'radiant'
  else
    winner = 'dire'
  end
  DebugPrint('Sending winner data')
  local endTime = GetSystemDate() .. GetSystemTime()
  local gameLength = HudTimer.gameTime
  local connectedPlayers = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)

    if player then
      table.insert(connectedPlayers, tostring(steamid))
    end
  end

  self:Request('match/complete', {
    winner = winner,
    endTime = endTime,
    gameLength = gameLength,
    players = connectedPlayers
  }, function (err, data)
    DebugPrintTable(data)
  end)
end

function Battlepass:SendTeams ()
  DebugPrint('Sending team data')
  local dire = {}
  local radiant = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    if steamid ~= 0 then
      steamid = tostring(steamid)
      if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
        table.insert(radiant, steamid)
      else
        table.insert(dire, steamid)
      end
    end
  end
  self:Request('match/send_teams', {
    dire = dire,
    radiant = radiant
  }, function (err, data)
    DebugPrintTable(data)
  end)
end

function Battlepass:Ready ()
  local userList = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    if steamid ~= 0 then
      table.insert(userList, steamid)
    end
  end

  DebugPrint('Sending auth request ' .. GameStartTime)

  self:Request('auth', {
    users = userList,
    gametime = GameStartTime
  }, function (err, data)
    if err then
      DebugPrint(err)
    end
    if data then
      DebugPrintTable(data)
      self.token = data.token
    end
  end)
end

function Battlepass:Request(api, data, cb)
  local req = CreateHTTPRequestScriptVM('POST', BATTLE_PASS_SERVER .. api)
  local encoded = json.encode(data)

  DebugPrint(encoded)

  req:SetHTTPRequestHeaderValue("Accept", "application/json")
  if self.token then
    req:SetHTTPRequestHeaderValue('X-Auth-Token', self.token)
  end

  -- Add the data
  req:SetHTTPRequestRawPostBody('application/json', encoded)

  -- Send the request
  req:Send(function(res)
    if res.StatusCode ~= 200 then
      DebugPrint("Failed to contact server")
      DebugPrint("Status Code", res.StatusCode or "nil")
      DebugPrint("Body", res.Body or "nil")
      return cb(res.Body or res.StatusCode)
    end

    if not res.Body then
      DebugPrint("So result returned from server")
      DebugPrint("Status Code", res.StatusCode or "nil")
      return cb('No content returned from server')
    end

    -- Try to decode the result
    local obj, pos, err = json.decode(res.Body, 1, nil)

    cb(err, obj)
  end)
end
