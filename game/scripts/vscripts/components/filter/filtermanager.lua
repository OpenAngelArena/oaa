if FilterManager == nil then
  Debug.EnabledModules['filter:*'] = true
  DebugPrint("creating new FilterManager object")
  FilterManager = class({})
end

function FilterManager:Init ()
  GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap( FilterManager, 'InventoryFilter' ), self )
end

function FilterManager:InventoryFilter (filterTable)
  local inventory_owner_entindex = filterTable.inventory_parent_entindex_const
  local item_entindex = filterTable.item_entindex_const
  local item_owner_entindex = filterTable.item_parent_entindex_const
  local suggested_slot = filterTable.suggested_slot
  local item_owner_handle = EntIndexToHScript(item_owner_entindex)
  local item_handle = EntIndexToHScript(item_entindex)
  local item_name = item_handle:GetName()


  if item_name == "item_bottle" then
    filterTable.suggested_slot = FilterManager:HandleBottlesInInventory(item_owner_handle)
  end

  DebugPrintTable(filterTable)
  return true
end

function FilterManager:HandleBottlesInInventory (player)
  if not player:HasItemInInventory("item_bottle") then
    return
  end
  DebugPrint("Player already has a bottle")
  for i=0,9 do
    local item = player:GetItemInSlot(i)
    if item and item:GetName() == "item_bottle" then
      DebugPrint("Found the bottle")
      item:Destroy()
      --TODO Add Modifier here
      return i
    end
  end
end
