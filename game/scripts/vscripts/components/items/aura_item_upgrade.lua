
LinkLuaModifier( "modifier_aura_item_upgrade", "modifiers/modifier_aura_item_upgrade.lua", LUA_MODIFIER_MOTION_NONE )

-- Used for refreshing auras on items when they are upgraded
GameEvents:OnItemCombined(function (keys)
  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not PlayerResource:IsValidPlayerID(plyID) then
    return
  end

  -- The name of the item purchased
  local itemName = keys.itemname

  local hero = PlayerResource:GetSelectedHeroEntity(plyID)
  if hero then
    -- Doesn't work when hero is dead
    hero:AddNewModifier(hero, nil, "modifier_aura_item_upgrade", {ItemName = itemName})
  end
end)
