if Talents == nil then
    Talents = class({})
    Debug.EnabledModules['progression:*'] = false
end

GameEvents:OnPlayerLearnedAbility(function(keys)
  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
  local pID = keys.PlayerID
  if pID and string.match(abilityname, "special_bonus") then
    local hero = PlayerResource:GetSelectedHeroEntity( pID )
    local talentData = CustomNetTables:GetTableValue("talents", tostring(hero:entindex())) or {}
    talentData[abilityname] = true
    CustomNetTables:SetTableValue( "talents", tostring(hero:entindex()), talentData )
  end
end)