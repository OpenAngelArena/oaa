
if BottleCounter == nil then
  DebugPrint('Creating new BottleCounter object')
  BottleCounter = class({})
end

function BottleCounter:Init()
  self.moduleName = "BottleCounter"
  self.bottleCount = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(0)))
  FilterManager:AddFilter(FilterManager.ItemAddedToInventory, self, Dynamic_Wrap(BottleCounter, 'Filter'))
end

function BottleCounter:Filter(filterTable)
  local itemEntIndex = filterTable.item_entindex_const
  local item = EntIndexToHScript(itemEntIndex)
  local parentEntIndex = filterTable.inventory_parent_entindex_const
  local parent = EntIndexToHScript(parentEntIndex)

  if not parent or parent:IsNull() then
    return true
  end

  local player = parent:GetPlayerOwner()

  if player and not parent:IsIllusion() and not parent:IsTempestDouble() and not parent:IsPhantom() then
    local playerID = player:GetPlayerID()
    if item:GetName() == "item_infinite_bottle" and not item.firstPickedUp then
      item.firstPickedUp = true
      if not PlayerResource:IsFakeClient(playerID) then
        self.bottleCount[playerID] = self.bottleCount[playerID] + 1
        CustomNetTables:SetTableValue('stat_display_player', 'BC', { value = self.bottleCount })
      end
    end
  end
  return true
end

function BottleCounter:GetBottles(playerID)
  return self.bottleCount[playerID]
end
