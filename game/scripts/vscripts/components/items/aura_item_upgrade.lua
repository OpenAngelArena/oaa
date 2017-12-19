
GameEvents:OnItemCombined(function (keys)
    -- The playerID of the hero who is buying something
    local plyID = keys.PlayerID
    if not plyID then return end
    local player = PlayerResource:GetPlayer(plyID)

    -- The name of the item purchased
    local itemName = keys.itemname

    local hero = player:GetAssignedHero()
    local hthinker = CreateModifierThinker( hero, nil , "modifier_aura_item_upgrade", { ItemName = itemName, PlayerId = plyID}, hero:GetOrigin(), hero:GetTeamNumber(), false )
end)

