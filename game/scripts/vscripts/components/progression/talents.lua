if Talents == nil then
    Talents = class({})
    Debug.EnabledModules['progression:*'] = false
end

GameEvents:OnPlayerLearnedAbility(function(keys)
  -- OnPlayerLearnedAbility event doesn't happen for abilities that are leveled up in Lua with: ability:SetLevel(level)
  local playerID = keys.PlayerID or keys.player_id -- just in case Valve randomly changes it again
  local abilityname = keys.abilityname

  if playerID and string.find(abilityname, "special_bonus") then
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local talentData = CustomNetTables:GetTableValue("talents", tostring(hero:entindex())) or {}
    talentData[abilityname] = true
    CustomNetTables:SetTableValue("talents", tostring(hero:entindex()), talentData)
  end
end)
