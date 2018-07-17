if PlayerConnection == nil then
  Debug:EnableDebugging()
  DebugPrint("Creating PlayerConnection Object")
  PlayerConnection = class({})
end

local OnPlayerAbandonEvent = CreateGameEvent('OnPlayerAbandon')

function PlayerConnection:Init()
  self.disconnectedPlayers = {}
  self.disconnectedTime = {}
  self.disconnectTime = {}
  self.abandonedPlayers = {}

  GameEvents:OnPlayerDisconnect(function(keys)
-- [VScript] [components\duels\duels:48] PlayerID: 1
-- [VScript] [components\duels\duels:48] splitscreenplayer: -1
    if HeroSelection.isCM then
      PauseGame(true)
    end
    self.disconnectedPlayers[keys.PlayerID] = true
    self.disconnectedTime[keys.PlayerID] = HudTimer:GetGameTime()
  end)
  GameEvents:OnPlayerReconnect(function (keys)
-- [VScript] [components\duels\duels:64] PlayerID: 1
-- [VScript] [components\duels\duels:64] name: Minnakht
-- [VScript] [components\duels\duels:64] networkid: [U:1:53917791]
-- [VScript] [components\duels\duels:64] reason: 2
-- [VScript] [components\duels\duels:64] splitscreenplayer: -1
-- [VScript] [components\duels\duels:64] userid: 3
-- [VScript] [components\duels\duels:64] xuid: 76561198014183519
    self.disconnectedPlayers[keys.PlayerID] = nil
    local timeOff = HudTimer:GetGameTime() - self.disconnectedTime[keys.PlayerID]
    self.disconnectTime[keys.playerID] = self.disconnectTime[keys.playerID] + timeOff;
    self.disconnectedTime[keys.PlayerID] = nil
  end)
  Timers:CreateTimer(function()
    return self:Think()
  end)
  self.countdown = nil

  self.isValid = true

  GameEvents:OnPlayerAbandon(function (keys)
    DebugPrint('A player just abandoned!')
    if HudTimer:GetGameTime() < MIN_MATCH_TIME then
      self.isValid = false
    end
  end)
end

function PlayerConnection:IsValid ()
  return self.isValid
end

function PlayerConnection:IsAbandoned (playerID)
  if self.abandonedPlayers[playerID] then
    return true
  end
  local isAbandon = PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_ABANDONED
  if isAbandon then
    self:ForceAbandon(playerID)
    return true
  end

  return false
end

function PlayerConnection:ForceAbandon (playerID)
  if not self.abandonedPlayers[playerID] then
    self.abandonedPlayers[playerID] = true
    OnPlayerAbandonEvent({
      playerID = playerID
    })
  end
end

function PlayerConnection:IsAnyDisconnected ()
  for _,dc in pairs(self.disconnectedPlayers) do
    if dc then
      return true
    end
  end

  return false
end

function PlayerConnection:IsConnected (playerID)
  return not self.disconnectedPlayers[playerID]
end

function PlayerConnection:Think()
  local goodTeamPlayerCount = length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))
  local badTeamPlayerCount = length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_BADGUYS))

  local emptyTeam = self:CheckAbandons()
  local otherTeam = nil

  if emptyTeam == DOTA_TEAM_GOODGUYS then
    otherTeam = DOTA_TEAM_BADGUYS
  elseif emptyTeam == DOTA_TEAM_BADGUYS then
    otherTeam = DOTA_TEAM_GOODGUYS
  end

  -- First check that players exist on both teams and don't start countdown if either team has no players
  if PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) == 0 or PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) == 0 then
    return 1-- Don't do anything
  elseif goodTeamPlayerCount == 0 and badTeamPlayerCount == 0 then
    PointsManager:SetWinner(DOTA_TEAM_NEUTRALS)
  elseif goodTeamPlayerCount == 0 then
    emptyTeam = DOTA_TEAM_GOODGUYS
    otherTeam = DOTA_TEAM_BADGUYS
  elseif badTeamPlayerCount == 0 then
    emptyTeam = DOTA_TEAM_BADGUYS
    otherTeam = DOTA_TEAM_GOODGUYS
  end

  if not emptyTeam then
    self.countdown = nil
  elseif not self.countdown then
    self.countdown = GAME_ABANDON_TIME
    Notifications:TopToAll({
      text="#abandon_detected",
      duration=3,
      style={
        color="red"
      }
    })
    return 1
  end

  if self.countdown and self.countdown > 0 then
    -- TODO: Show Nice Message
    if otherTeam == DOTA_TEAM_GOODGUYS then
      Notifications:TopToAll({
        text="#abandon_good_auto_win",
        duration=1,
        replacement_map={
          seconds_remaining = self.countdown
        }
      })
    elseif otherTeam == DOTA_TEAM_BADGUYS then
      Notifications:TopToAll({
        text="#abandon_bad_auto_win",
        duration=1,
        replacement_map={
          seconds_remaining = self.countdown
        }
      })
    end
    self.countdown = self.countdown - 1
  elseif self.countdown == 0 then
    PointsManager:SetWinner(otherTeam)
    return -- don't loop again
  end

  return 1
end

function PlayerConnection:CheckAbandons ()
  if not HeroSelection.isCM or AUTO_ABANDON_IN_CM then
    for playerID,time in self.disconnectedTime do
      if not self:IsAbandoned(playerID) and time and self.disconnectTime[playerID] + (HudTimer:GetGameTime() - self.disconnectedTime[keys.PlayerID]) > TIME_TO_ABANDON then
        self:ForceAbandon(playerID)
      end
    end
  end

  local direAbandons = 0
  local radiantAbandons = 0

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local team = PlayerResource:GetTeam(playerID)
    if team == DOTA_TEAM_BADGUYS then
      if self:IsAbandoned(playerID) then
        direAbandons = direAbandons + 1
      end
    elseif team == DOTA_TEAM_GOODGUYS then
      if self:IsAbandoned(playerID) then
        radiantAbandons = radiantAbandons + 1
      end
    end
  end

  -- return the "empty" team
  if direAbandons - radiantAbandons >= ABANDON_DIFF_NEEDED then
    return DOTA_TEAM_BADGUYS
  end
  if radiantAbandons - direAbandons >= ABANDON_DIFF_NEEDED then
    return DOTA_TEAM_GOODGUYS
  end
end
