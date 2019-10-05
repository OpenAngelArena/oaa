-- Gives starting items


-- Taken from bb template
if StartingItems == nil then
  Debug.EnabledModules['startingitems:*'] = true
  DebugPrint ( 'creating new StartingItems object' )
  StartingItems = class({})
end

function StartingItems:Init ()
  --StartingItems.itemList = {"item_farming_core"}

  --GameEvents:OnHeroInGame(StartingItems.GiveStartingItems)
end

function StartingItems.GiveStartingItems (hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end
  if #StartingItems.itemList <= 0 then
    return
  end

  -- We have a timer here so that the courier stuff doesn't interfere
  Timers:CreateTimer(1.54, function ()

    DebugPrint("Giving starting items to " .. hero:GetUnitName())

    -- Create couriers and then cast them straight away
    for _, itemName in pairs(StartingItems.itemList) do
        local item = hero:AddItemByName(itemName)
	    -- no idea if this stuff is gonna be used for anything other than farming cores
	    -- but if it is, let's emulate dota random bonuses ( aka can't be sold )
	    -- item:SetSellable(false) -- this removes the right-click menu that's a terrible idea
    end
  end)
end
