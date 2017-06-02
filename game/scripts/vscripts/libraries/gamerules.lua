--[[ Extension functions for GameRules

-GameRules:GetMaxTeamPlayers()
  Returns the total number of non-spectator players the map allows
]]

function CDOTAGamerules:GetMaxTeamPlayers()
  return sum(map(partial(self.GetCustomGameTeamMaxPlayers, self), range(DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX)))
end
