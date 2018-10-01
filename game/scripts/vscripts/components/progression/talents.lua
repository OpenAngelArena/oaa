if Talents == nil then
    Talents = class({})
    Debug.EnabledModules['progression:*'] = false
end

GameEvents:OnPlayerLearnedAbility(function(keys)
  -- OnPlayerLearnedAbility event doesn't happen for abilities that are leveled up in Lua with: ability:SetLevel(level)
  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
  local playerID = keys.PlayerID
  if playerID and string.find(abilityname, "special_bonus") then
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local talentData = CustomNetTables:GetTableValue("talents", tostring(hero:entindex())) or {}
    talentData[abilityname] = true
    CustomNetTables:SetTableValue("talents", tostring(hero:entindex()), talentData)
  end
end)
