
LinkLuaModifier('modifier_bottle_counter', 'modifiers/modifier_bottle_counter.lua', LUA_MODIFIER_MOTION_NONE)

if BottleCounter == nil then
  Debug.EnabledModules['filters:bottlecounter'] = true
  DebugPrint('Creating new BottleCounter object')
  BottleCounter = class({})
end

function BottleCounter:Init()
  FilterManager:AddFilter(FilterManager.ItemAddedToInventory, self, Dynamic_Wrap(BottleCounter, 'Filter'))

  for _,playerID in PlayerResource:GetAllTeamPlayerIDs() do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      player.bottleCount = 0
    end
    if hero then
      hero:AddNewModifier(hero, nil, 'modifier_bottle_counter', {})
    end
  end
end

function BottleCounter:Filter(filterTable)
  --DebugPrintTable(filterTable)
  local itemEntIndex = filterTable.item_entindex_const
  local item = EntIndexToHScript(itemEntIndex)
  local parentEntIndex = filterTable.inventory_parent_entindex_const
  local parent = EntIndexToHScript(parentEntIndex)
  local player = parent:GetPlayerOwner()

  if player and not parent:IsIllusion() and not parent:IsTempestDouble() and not parent:IsPhantom() then
    hero = player:GetAssignedHero()

    if item:GetName() == "item_infinite_bottle" and not item.firstPickedUp then
      item.firstPickedUp = true
      if not player.bottleCount then
        player.bottleCount = 1
      else
        player.bottleCount = player.bottleCount + 1
      end
      hero:AddNewModifier(hero, nil, 'modifier_bottle_counter', {})
    end

  end
  return true
end
