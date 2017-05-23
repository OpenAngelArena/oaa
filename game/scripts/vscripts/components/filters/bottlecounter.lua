
LinkLuaModifier('modifier_bottle_counter', 'modifiers/modifier_bottle_counter.lua', LUA_MODIFIER_MOTION_NONE)

if BottleCounter == nil then
  Debug.EnabledModules['filters:bottlecounter'] = true
  DebugPrint('Creating new BottleCounter object')
  BottleCounter = class({})
end

function BottleCounter:Init()
  self.bottleCount = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(0)))
  FilterManager:AddFilter(FilterManager.ItemAddedToInventory, self, Dynamic_Wrap(BottleCounter, 'Filter'))
end

function BottleCounter:Filter(filterTable)
  --DebugPrintTable(filterTable)
  local itemEntIndex = filterTable.item_entindex_const
  local item = EntIndexToHScript(itemEntIndex)
  local parentEntIndex = filterTable.inventory_parent_entindex_const
  local parent = EntIndexToHScript(parentEntIndex)
  local player = parent:GetPlayerOwner()

  if player and not parent:IsIllusion() and not parent:IsTempestDouble() and not parent:IsPhantom() then
    local hero = player:GetAssignedHero()
    local playerID = player:GetPlayerID()

    if item:GetName() == "item_infinite_bottle" and not item.firstPickedUp then
      item.firstPickedUp = true
      self.bottleCount[playerID] = self.bottleCount[playerID] + 1
      CustomNetTables:SetTableValue('stat_display', 'BC', { value = self.bottleCount })
    end
  end
  return true
end

function BottleCounter:GetBottles(playerID)
  return self.bottleCount[playerID]
end
