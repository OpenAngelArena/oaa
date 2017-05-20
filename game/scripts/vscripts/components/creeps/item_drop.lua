LinkLuaModifier("modifier_creep_loot", "modifiers/modifier_creep_loot.lua", LUA_MODIFIER_MOTION_NONE)

-- Taken from bb template
if CreepItemDrop == nil then
    DebugPrint ( '[creeps/item_drop] creating new CreepItemDrop object' )
    CreepItemDrop = class({})
end

--item power level defines what items drop at given time
local ItemPowerLevel = 1.0

--define how often items drop from creeps. min = 0 (0%), max = 1 (100%)
local DROP_CHANCE = 0.25

--creep properties enumerations
local NAME_ENUM = 1
local FROM_ENUM = 2
local TO_ENUM = 3
local RARITY_ENUM = 4
local DROPS_ENUM = 4
local EVERY_ENUM = 5

--defines items drop levels.
--item will start dropping, between FROM and TO itemPowerLevel.
-- RARITY is used to define how likely the item is to drop in comparison with other items.
-- the higher the value, the less likely the item is to drop
--for negative values:
--  *FROM -> any level smaller or equal than TO will have a chance to drop the item.
--  *TO   -> any level larger or equal than FROM will have  a chance to drop the item.
--  *FROM and TO -> item will drop at any level.
--  *RARITY -> item will not drop.
--for PerCampDrops:
--  DROPS is how many of the item to drop for every EVERY number of creeps spawned in a camp
--it is possible to define the same item twice, for maximum flexibility
local ItemPowerTable = {
  RandomDrops = {
    --NAME                        FROM    TO        RARITY
    --{ "item_infinite_bottle",      3,      -1,      1},
  },
  PerCreepDrops = {
    --NAME                        FROM    TO        DROPS      EVERY
    {"item_infinite_bottle",      -1,       -1,       1,           4}
  }
}

function CreepItemDrop:Init ()
  DebugPrint ( '[creeps/item_drop] Initialize' )
  CreepItemDrop = self

  ListenToGameEvent("entity_killed", CreepItemDrop.OnEntityKilled, self)
  Timers:CreateTimer(Dynamic_Wrap(CreepItemDrop, 'ItemDropUpgradeTimer'))
end

function CreepItemDrop:SetPowerLevel (powerLevel)
  ItemPowerLevel = powerLevel
end

function CreepItemDrop:ItemDropUpgradeTimer ()
  -- upgrade creeps power level every time it triggers
  CreepItemDrop:SetPowerLevel(ItemPowerLevel + 1)

  return 10.0
end

function CreepItemDrop:CreateDrop (itemName, pos)
  local newItem = CreateItem(itemName, nil, nil)

  newItem:SetPurchaseTime(0)
  newItem.firstPickedUp = false

  CreateItemOnPositionSync(pos, newItem)
  newItem:LaunchLoot(false, 300, 0.75, pos + RandomVector(RandomFloat(50, 350)))

  Timers:CreateTimer(60, function ()
    -- check if safe to destroy
    if IsValidEntity(newItem) then
      if newItem:GetContainer() ~= nil then
        newItem:GetContainer():RemoveSelf()
      end
    end
  end)
end

function CreepItemDrop:AddFixedDropsToCamp(creeps, numberOfCreepsSpawned)
  local function AddItemToCamp(item)
    local from = item[FROM_ENUM]
    local to = item[TO_ENUM]
    local numDrops = item[DROPS_ENUM]
    local every = item[EVERY_ENUM]

    if (from < 0 or (from >= 0 and ItemPowerLevel >= from)) and (to < 0 or (to >= 0 and ItemPowerLevel <= to)) and numberOfCreepsSpawned % every == 0 then
      for i = 1,numDrops do
        local selectedCreep = creeps[RandomInt(1, #creeps)]
        selectedCreep:AddNewModifier(nil, nil, "modifier_creep_loot", {drop = item[NAME_ENUM]})
      end
    end
  end

  foreach(AddItemToCamp, ItemPowerTable.PerCreepDrops)
end

function CreepItemDrop:OnEntityKilled (event)
  local killedEntity = EntIndexToHScript(event.entindex_killed)

  if killedEntity ~= nil then
    if killedEntity.Is_ItemDropEnabled then
      local itemToDrop = CreepItemDrop:RandomDropItemName()
      if itemToDrop ~= "" and itemToDrop ~= nil then
        CreepItemDrop:CreateDrop(itemToDrop, killedEntity:GetAbsOrigin())
      end
    end
  end
end

function CreepItemDrop:RandomDropItemName( property_enum, powerLevel )

  --first we need to check against the drop percentage.
  if math.random() > DROP_CHANCE then
    return ""
  end

  --now iterate through item power table and see which items qualify for
  local totalChancePool = 0.0
  local filteredItemTable = {}

  for i=1, #ItemPowerTable.RandomDrops do
    local from = ItemPowerTable.RandomDrops[i][FROM_ENUM]
    local to = ItemPowerTable.RandomDrops[i][TO_ENUM]
    local rarity = ItemPowerTable.RandomDrops[i][RARITY_ENUM]

    if (from < 0 or (from >= 0 and ItemPowerLevel >= from)) and (to < 0 or (to >= 0 and ItemPowerLevel <= to)) and rarity > 0 then
      totalChancePool = totalChancePool + 1.0 / rarity
      filteredItemTable[#filteredItemTable + 1] = ItemPowerTable.RandomDrops[i]
    end
  end

  local passedItemsCumulativeChance = 0.0
  local dropChance = math.random() * totalChancePool

  for i=1, #filteredItemTable do
    passedItemsCumulativeChance = passedItemsCumulativeChance + 1.0 / filteredItemTable[i][RARITY_ENUM]
    if passedItemsCumulativeChance >= dropChance then
      return filteredItemTable[i][NAME_ENUM]
    end
  end

  --in case some configuration was done wrong, return empty, itherwise this point should not be reached normally.
  return ""
end
