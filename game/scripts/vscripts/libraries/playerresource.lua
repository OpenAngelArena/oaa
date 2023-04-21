--[[ Extension functions for PlayerResource

-PlayerResource:GetAllPlayerIDs()
  Returns an iterator for all the player IDs (inludes players and spectators, doesn't ignore black boxes and bots)

-PlayerResource:GetAllTeamPlayerIDs()
  Returns an iterator for all the valid non-spectator player IDs (ignores black boxes but not bots)

-PlayerResource:GetConnectedTeamPlayerIDs()
  Returns an iterator for all connected, non-spectator player IDs

-PlayerResource:GetPlayerIDsForTeam(int team)
  Returns an iterator for all player IDs in the given team

-PlayerResource:GetConnectedPlayerIDsForTeam(int team)
  Returns an iterator for all connected player IDs in the given team

-PlayerResource:RandomHeroForPlayersWithoutHero()
  Forcibly randoms a hero for any player that has not yet picked a hero

-PlayerResource:IsBotOrPlayerConnected(int id)
  Returns true if the given player ID is a connected bot or player
]]
function CDOTA_PlayerResource:GetAllPlayerIDs()
  return filter(partial(self.IsValidPlayerID, self), range(0, DOTA_MAX_PLAYERS))
end

function CDOTA_PlayerResource:GetAllTeamPlayerIDs()
  return filter(function(id) return self:IsValidPlayerID(id) and self:IsValidPlayer(id) end, range(0, DOTA_MAX_TEAM_PLAYERS))
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDs()
  return filter(partial(self.IsBotOrPlayerConnected, self), self:GetAllTeamPlayerIDs())
end

function CDOTA_PlayerResource:GetPlayerIDsForTeam(team)
  return filter(function(id) return self:GetTeam(id) == team end, self:GetAllTeamPlayerIDs())
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDsForTeam(team)
  return filter(partial(self.IsBotOrPlayerConnected, self), self:GetPlayerIDsForTeam(team))
end

function CDOTA_PlayerResource:RandomHeroForPlayersWithoutHero()
  local function HasNotSelectedHero(playerID)
    return not self:HasSelectedHero(playerID)
  end
  local function ForceRandomHero(playerID)
    self:GetPlayer(playerID):MakeRandomHeroSelection()
  end
  local playerIDsWithoutHero = filter(HasNotSelectedHero, self:GetConnectedTeamPlayerIDs())
  foreach(ForceRandomHero, playerIDsWithoutHero)
end

function CDOTA_PlayerResource:IsBotOrPlayerConnected(id)
  local connectionState = self:GetConnectionState(id)
  return connectionState == DOTA_CONNECTION_STATE_CONNECTED or connectionState == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED
end

function CDOTA_PlayerResource:SafeGetTeamPlayerCount()
  return length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_GOODGUYS)) + length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_BADGUYS))
end

function CDOTA_PlayerResource:FindFirstValidPlayer()
  local player
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
    if self:IsValidPlayerID(playerID) and self:IsValidPlayer(playerID) then
      player = self:GetPlayer(playerID)
      if player then
        break
      end
    end
  end
  return player
end

function CDOTA_PlayerResource:IsBlackBoxPlayer(id)
  local connectionState = self:GetConnectionState(id)
  local steamID = self:GetSteamAccountID(id)
  return connectionState == DOTA_CONNECTION_STATE_NOT_YET_CONNECTED and steamID == 0 and self:IsValidPlayer(id) == false
end
