--[[ Extension functions for PlayerResource

-PlayerResource:GetAllTeamPlayerIDs()
  Returns an iterator for all the player IDs assigned to a valid team (radiant, dire, or custom)

-PlayerResource:GetConnectedTeamPlayerIDs()
  Returns an iterator for all connected, non-spectator player IDs

-PlayerResource:GetPlayerIDsForTeam(int team)
  Returns an iterator for all player IDs in the given team

-PlayerResource:GetConnectedPlayerIDsForTeam(int team)
  Returns an iterator for all connected player IDs in the given team

-PlayerResource:RandomHeroForPlayersWithoutHero()
  Forcibly randoms a hero for any player that has not yet picked a hero
]]
function CDOTA_PlayerResource:GetAllTeamPlayerIDs()
  return filter(partial(self.IsValidPlayerID, self), range(0, self:GetPlayerCount()))
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDs()
  return filter(function(id) return self:GetConnectionState(id) == 2 end, self:GetAllTeamPlayerIDs())
end

function CDOTA_PlayerResource:GetPlayerIDsForTeam(team)
  return filter(function(id) return self:GetTeam(id) == team end, range(0, self:GetPlayerCount()))
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDsForTeam(team)
  return filter(function(id) return self:GetConnectionState(id) == 2 end, self:GetPlayerIDsForTeam(team))
end

function CDOTA_PlayerResource:RandomHeroForPlayersWithoutHero()
  function HasNotSelectedHero(playerID)
    return not self:HasSelectedHero(playerID)
  end
  function ForceRandomHero(playerID)
    self:GetPlayer(playerID):MakeRandomHeroSelection()
  end
  local playerIDsWithoutHero = filter(HasNotSelectedHero, self:GetConnectedTeamPlayerIDs())
  foreach(ForceRandomHero, playerIDsWithoutHero)
end
