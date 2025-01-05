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
  if hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
    return
  end
  -- Add starting items
  --for _, itemName in pairs(StartingItems.itemList) do
    --local item = hero:AddItemByName(itemName)
    -- item:SetSellable(false) -- this removes the right-click menu so use with care
  --end
end
