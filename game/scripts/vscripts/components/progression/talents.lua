if Talents == nil then
  Talents = class({})
end

GameEvents:OnPlayerLearnedAbility(function(keys)
  -- OnPlayerLearnedAbility event doesn't happen for abilities that are leveled up in Lua with: ability:SetLevel(level)

  --"PlayerID"
  --"player"
  --"abilityname"

  local playerID = keys.PlayerID or keys.player_id -- just in case Valve randomly changes it again
  local abilityname = keys.abilityname

  local player
  if keys.player then
    player = EntIndexToHScript(keys.player)
  else
    player = PlayerResource:GetPlayer(playerID)
  end

  local hero
  if player then
    hero = player:GetAssignedHero()
  else
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if abilityname and hero then
    local talent = hero:FindAbilityByName(abilityname)
    -- Check if ability is a talent
    if string.find(abilityname, "special_bonus_") and talent:IsAttributeBonus() then
      -- Store information into net-table (probably not needed)
      local talentData = CustomNetTables:GetTableValue("talents", tostring(hero:entindex())) or {}
      talentData[abilityname] = true
      CustomNetTables:SetTableValue("talents", tostring(hero:entindex()), talentData)
    end
  end
end)
