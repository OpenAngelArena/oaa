--[[ Extension functions for GameRules

-GameRules:GetMaxTeamPlayers()
  Returns the total number of non-spectator players the map allows
]]

function CDOTAGameRules:GetMaxTeamPlayers()
  return sum(map(partial(self.GetCustomGameTeamMaxPlayers, self), range(DOTA_TEAM_FIRST, DOTA_TEAM_CUSTOM_MAX)))
end

function CDOTAGameRules:GetMatchID()
  return self:Script_GetMatchID()
end
