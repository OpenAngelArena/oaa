
-- Used for refreshing auras on items when they are upgraded
GameEvents:OnItemCombined(function (keys)
  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not PlayerResource:IsValidPlayerID(plyID) then
    return
  end

  -- Problematic auras
  local auraItems = {
    "item_assault_",
    "item_pipe_",
    "item_radiance_",
    "item_shivas_guard_",
  }

  -- The name of the combined (purchased) item
  local itemName = keys.itemname

  local hero = PlayerResource:GetSelectedHeroEntity(plyID)
  if hero then
    -- Check if combined item is on the list, add the modifier only if found
    for _, value in ipairs(auraItems) do
      if string.find(itemName, value) then
        -- Doesn't work when hero is dead, but items should refresh on respawn so it should not be a problem
        hero:AddNewModifier(hero, nil, "modifier_aura_item_upgrade", {ItemName = itemName})
      end
    end
  end
end)
