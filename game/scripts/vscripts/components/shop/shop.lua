if PanoramaShop == nil then
  Debug.EnabledModules['shop:*'] = true
  DebugPrint('Creating new PanoramaShop object.')
  PanoramaShop = class({})
end

function PanoramaShop:Init()
  self._RawItemData = {}
  self._ItemData = {}
  self.FormattedData = {}
  self.StocksTable = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {},
  }
end

function PanoramaShop:PushStockInfoToAllClients()
  for teamID, tt in pairs(PanoramaShop.StocksTable) do
    local ItemStocks = PlayerTables:GetTableValue("panorama_shop_data", "ItemStocks_team" .. teamID) or {}
    for _, v in pairs(tt) do
      ItemStocks[itemID] = {
        current_stock = v.current_stock,
        current_cooldown = v.current_cooldown,
        current_last_purchased_time = v.current_last_purchased_time,
      }
    end
    PlayerTables:SetTableValue("panorama_shop_data", "ItemStocks_team" .. team, ItemStocks)
  end
end

function PanoramaShop:GetItemStockCooldown(teamID, item)
  local t = PanoramaShop.StocksTable[teamID][item]
  return t ~= nil and (t.current_cooldown - (GameRules:GetGameTime() - t.current_last_purchased_time))
end

function PanoramaShop:GetItemStockCount(teamID, item)
  local t = PanoramaShop.StocksTable[teamID][item]
  return t ~= nil and t.current_stock
end

function PanoramaShop:IncreaseItemStock(teamID, item)
  local t = PanoramaShop.StocksTable[teamID][item]
  if t and (t.ItemStockMax == -1 or t.current_stock < t.ItemStockMax) then
    t.current_stock = t.current_stock + 1
    if (t.ItemStockMax == -1 or t.current_stock < t.ItemStockMax) then
      PanoramaShop:StackStockableCooldown(teamID, item, t.ItemStockTime)
    end
    PanoramaShop:PushStockInfoToAllClients()
  end
end

function PanoramaShop:DecreaseItemStock(teamID, item)
  local t = PanoramaShop.StocksTable[teamID][item]
  if t and t.current_stock > 0 then
    if t.current_stock == t.ItemStockMax then
      PanoramaShop:StackStockableCooldown(teamID, item, t.ItemStockTime)
    end
    t.current_stock = t.current_stock - 1
    PanoramaShop:PushStockInfoToAllClients()
  end
end

function PanoramaShop:StackStockableCooldown(teamID, item, time)
  local t = PanoramaShop.StocksTable[teamID][item]

  if GameRules:State_Get() < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    time = time - GameRules:GetDOTATime(false, true)
  end

  t.current_cooldown = time
  t.current_last_purchased_time = GameRules:GetGameTime()

  Timers:CreateTimer(time, function()
    PanoramaShop:IncreaseItemStock(teamID, item)
  end)
end

function PanoramaShop:InitializeItemTable()
  local RecipesToCheck = {}
  --загрузка всех предметов, разделение на предмет/рецепт -- Download all items, division by subject / recipe
  for name, kv in pairs(KeyValues.ItemKV) do
    if type(kv) == "table" and (kv.ItemPurchasable or 1) == 1 then
      if name == "item_blink" then
        PrintTable(kv)
      end
      if kv.ItemRecipe == 1 then
        RecipesToCheck[kv.ItemResult] = name
      end
      PanoramaShop._RawItemData[name] = kv
    end
  end
  --заполнение данных для каждого предмета -- Filling in the data for each item
  local itemsBuldsInto = {}
  for name, kv in pairs(PanoramaShop._RawItemData) do
    local itemdata = {
      id = kv.ID or -1,
      purchasable = (kv.ItemPurchasable or 1) == 1 and (kv.ItemPurchasableFilter or 1) == 1,
      cost = GetTrueItemCost(name),
      names = { name:lower() },
    }
    if kv.ItemAliases then
      for _,v in ipairs(string.split(kv.ItemAliases, ";")) do
        if not table.contains(itemdata.names, v:lower()) then
          table.insert(itemdata.names, v:lower())
        end
      end
    end
    local translated_english = LANG_ENGLISH["DOTA_Tooltip_Ability_" .. name] or LANG_ENGLISH["DOTA_Tooltip_ability_" .. name]
    if translated_english then
      if not table.contains(itemdata.names, translated_english:lower()) then
        table.insert(itemdata.names, translated_english:lower())
      end
    end
    local translated_russian = LANG_RUSSIAN["DOTA_Tooltip_Ability_" .. name] or LANG_RUSSIAN["DOTA_Tooltip_ability_" .. name]
    if translated_russian then
      if not table.contains(itemdata.names, translated_russian:lower()) then
        table.insert(itemdata.names, translated_russian:lower())
      end
    end
    if RecipesToCheck[name] then
      local recipedata = {
        visible = GetTrueItemCost(RecipesToCheck[name]) > 0,
        items = {},
        cost = GetTrueItemCost(RecipesToCheck[name]),
        recipeItemName = RecipesToCheck[name],
      }
      local recipeKv = KeyValues.ItemKV[RecipesToCheck[name]]

      if not itemsBuldsInto[RecipesToCheck[name]] then itemsBuldsInto[RecipesToCheck[name]] = {} end
      if not table.contains(itemsBuldsInto[RecipesToCheck[name]], name) then
        table.insert(itemsBuldsInto[RecipesToCheck[name]], name)
      end
      for key, ItemRequirements in pairsByKeys(recipeKv.ItemRequirements) do
        local itemParts = string.split(string.gsub(ItemRequirements, " ", ""), ";")
        table.insert(recipedata.items, itemParts)
        for _,v in ipairs(itemParts) do
          if not itemsBuldsInto[v] then itemsBuldsInto[v] = {} end
          if not table.contains(itemsBuldsInto[v], name) then
            table.insert(itemsBuldsInto[v], name)
          end
        end
      end
      itemdata.Recipe = recipedata
    end
    if kv.ItemStockMax or kv.ItemStockTime or kv.ItemInitialStockTime or kv.ItemStockInitial then
      local stocks = {
        ItemStockMax = kv.ItemStockMax or -1,
        ItemStockTime = kv.ItemStockTime or 0,
        current_stock = kv.ItemStockInitial,
        current_cooldown = kv.ItemInitialStockTime or 0,
        current_last_purchased_time = -1,
      }
      if not stocks.current_stock then
        if stocks.current_cooldown == 0 then
          stocks.current_stock = kv.ItemStockInitial or kv.ItemStockMax or 0
        else
          stocks.current_stock = 0
        end
      end
      for k,_ in pairs(PanoramaShop.StocksTable) do
        PanoramaShop.StocksTable[k][name] = {}
        table.merge(PanoramaShop.StocksTable[k][name], stocks)
      end
    end
    PanoramaShop.FormattedData[name] = itemdata
  end
  for unit,itemlist in pairs(DROP_TABLE) do
    for _,v in ipairs(itemlist) do
      local iteminfo = PanoramaShop.FormattedData[v.Item]
      if iteminfo.Recipe then
        print("[PanoramaShop] Item that has recipe is defined in unit drop table", itemName)
      else
        if not iteminfo.DropListData then
          iteminfo.DropListData = {}
        end
        if not iteminfo.DropListData[unit] then
          iteminfo.DropListData[unit] = {}
        end

        table.insert(iteminfo.DropListData[unit], v.DropChance)
      end
    end
  end
  for name,items in pairs(itemsBuldsInto) do
    if PanoramaShop.FormattedData[name] then
      PanoramaShop.FormattedData[name].BuildsInto = items
    end
  end
  --распределение данных по вкладкам и группам
  local Items = {}
  for shopName, shopData in pairs(PANORAMA_SHOP_ITEMS) do
    Items[shopName] = {}
    for groupName, groupData in pairs(shopData) do
      Items[shopName][groupName] = {}
      for _, itemName in ipairs(groupData) do
        if not PanoramaShop.FormattedData[itemName] then
          print("[PanoramaShop] Item defined in shop list is not defined in any of item KV files", itemName)
        else
          table.insert(Items[shopName][groupName], itemName)
        end
      end
    end
  end
  local allItembuilds = {}
  table.add(allItembuilds, ARENA_ITEMBUILDS)
  table.add(allItembuilds, VALVE_ITEMBUILDS)

  local itembuilds = {}
  for k,v in ipairs(allItembuilds) do
    if not itembuilds[v.hero] then itembuilds[v.hero] = {} end
    table.insert(itembuilds[v.hero], {
      title = v.title,
      author = v.author,
      patch = v.patch,
      description = v.description,
      items = v.items,
    })
  end
  PanoramaShop._ItemData = Items
  CustomGameEventManager:RegisterListener("panorama_shop_item_buy", Dynamic_Wrap(PanoramaShop, "OnItemBuy"))
  PlayerTables:CreateTable("panorama_shop_data", {ItemData = PanoramaShop.FormattedData, ShopList = Items, Itembuilds = itembuilds}, AllPlayersInterval)
  PanoramaShop:PushStockInfoToAllClients()
end

function PanoramaShop:StartItemStocks()
  for team,v in pairs(PanoramaShop.StocksTable) do
    for item,stocks in pairs(v) do
      if stocks.current_cooldown > 0 then
        PanoramaShop:StackStockableCooldown(team, item, stocks.current_cooldown)
      elseif stocks.ItemStockMax == -1 or stocks.current_stock < stocks.ItemStockMax then
        PanoramaShop:StackStockableCooldown(team, item, stocks.ItemStockTime)
      end
    end
  end
  PanoramaShop:PushStockInfoToAllClients()
end

function PanoramaShop:OnItemBuy(data)
  if data and data.itemName and data.unit then
    local ent = EntIndexToHScript(data.unit)
    if ent and ent.entindex and (ent:GetPlayerOwner() == PlayerResource:GetPlayer(data.PlayerID) or ent == FindCourier(PlayerResource:GetTeam(data.PlayerID))) then
      PanoramaShop:BuyItem(data.PlayerID, ent, data.itemName)
    end
  end
end

function PanoramaShop:PushItem(playerID, unit, name, bOnlyStash)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local team = PlayerResource:GetTeam(playerID)
  local item = CreateItem(name, hero, hero)
  local isInShop = unit:HasModifier("modifier_fountain_aura_arena")
  item:SetPurchaseTime(GameRules:GetGameTime())
  item:SetPurchaser(hero)

  local itemPushed = false
  --If unit has slot for that item
  if isInShop and not bOnlyStash then
    if unit:UnitHasSlotForItem(name, true) then
      unit:AddItem(item)
      itemPushed = true
    end
  end
  --Try to add item to hero's stash
  if not itemPushed then
    if not isInShop then SetAllItemSlotsLocked(hero, true, true) end
    FillSlotsWithDummy(hero, false)
    for i = DOTA_STASH_SLOT_1 , DOTA_STASH_SLOT_6 do
      local current_item = unit:GetItemInSlot(i)
      if current_item and current_item:GetAbilityName() == "item_dummy" then
        UTIL_Remove(current_item)
        unit:AddItem(item)
        itemPushed = true
        break
      end
    end
    ClearSlotsFromDummy(hero, false)
    if not isInShop then SetAllItemSlotsLocked(hero, false, true) end
  end
  --At last drop an item on fountain
  if not itemPushed then
    local spawnPointName = "info_courier_spawn"
    local teamCared = true
    if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
      spawnPointName = "info_courier_spawn_radiant"
      teamCared = false
    elseif PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
      spawnPointName = "info_courier_spawn_dire"
      teamCared = false
    end
    local ent
    while true do
      ent = Entities:FindByClassname(ent, spawnPointName)
      if ent and (not teamCared or (teamCared and ent:GetTeam() == PlayerResource:GetTeam(playerID))) then
        CreateItemOnPositionSync(ent:GetAbsOrigin() + RandomVector(RandomInt(0, 300)), item)
        break
      end
    end
  end
end

SHOP_LIST_STATUS_IN_INVENTORY = 0
SHOP_LIST_STATUS_IN_STASH = 1
SHOP_LIST_STATUS_TO_BUY = 2
SHOP_LIST_STATUS_NO_STOCK = 3
SHOP_LIST_STATUS_NO_BOSS = 4
function PanoramaShop:BuyItem(playerID, unit, itemName)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local team = PlayerResource:GetTeam(playerID)
  if Duel:IsDuelOngoing() then
    Containers:DisplayError(playerID, "#dota_hud_error_cant_purchase_duel_ongoing")
    return
  end
  if unit:IsIllusion() or not unit:HasInventory() then
    unit = hero
  end
  local isInShop = unit:HasModifier("modifier_fountain_aura_arena")

  local itemCounter = {}
  local ProbablyPurchasable = {}

  function GetAllPrimaryRecipeItems(childItemName)
    local primary_items = {}
    local itemData = PanoramaShop.FormattedData[childItemName]
    local _tempItemCounter = {}
    _tempItemCounter[childItemName] = (_tempItemCounter[childItemName] or 0) + 1

    --local itemcount_all = #GetAllItemsByNameInInventory(unit, childItemName, true)
    local itemcount = #GetAllItemsByNameInInventory(unit, childItemName, true) --isInShop and itemcount_all or itemcount_all - #GetAllItemsByNameInInventory(unit, childItemName, false)
    if (childItemName == itemName or itemcount < _tempItemCounter[childItemName]) and itemData.Recipe then
      for _, newchilditem in ipairs(itemData.Recipe.items[1]) do
        local subitems, newCounter = GetAllPrimaryRecipeItems(newchilditem)
        table.add(primary_items, subitems)
        for k,v in pairs(newCounter) do
          _tempItemCounter[k] = (_tempItemCounter[k] or 0) + v
        end
      end
      if itemData.Recipe.cost > 0 then
        table.insert(primary_items, itemData.Recipe.recipeItemName)
        _tempItemCounter[itemData.Recipe.recipeItemName] = (_tempItemCounter[itemData.Recipe.recipeItemName] or 0) + 1
      end
    end
    table.insert(primary_items, childItemName)
    return primary_items, _tempItemCounter
  end
  function HasAnyOfItemChildren(childItemName)
    if not PanoramaShop.FormattedData[childItemName].Recipe then return false end
    local primary_items = GetAllPrimaryRecipeItems(childItemName)
    table.removeByValue(primary_items, childItemName)

    for _,v in ipairs(primary_items) do
      local stocks = PanoramaShop:GetItemStockCount(team, v)
      if FindItemInInventoryByName(unit, v, true) or GetKeyValue(v, "ItemPurchasableFilter") == 0 or GetKeyValue(v, "ItemPurchasable") == 0 or stocks then
        return true
      end
    end
    return false
  end
  function DefineItemState(name)
    local has = HasAnyOfItemChildren(name)
    --print(name, has)
    if has then
      InsertItemChildrenToCheck(name)
    else
      itemCounter[name] = (itemCounter[name] or 0) + 1
      local itemcount_inv = #GetAllItemsByNameInInventory(unit, name, false)
      local itemcount_stash = #GetAllItemsByNameInInventory(unit, name, true) - itemcount_inv
      local stocks = PanoramaShop:GetItemStockCount(team, name)
      if name ~= itemName and itemcount_stash >= itemCounter[name] then
        ProbablyPurchasable[name .. "_index_" .. itemCounter[name]] = SHOP_LIST_STATUS_IN_STASH
      elseif name ~= itemName and itemcount_inv >= itemCounter[name] then
        ProbablyPurchasable[name .. "_index_" .. itemCounter[name]] = SHOP_LIST_STATUS_IN_INVENTORY
      elseif GetKeyValue(name, "ItemPurchasableFilter") == 0 or GetKeyValue(name, "ItemPurchasable") == 0 then
        ProbablyPurchasable[name .. "_index_" .. itemCounter[name]] = SHOP_LIST_STATUS_NO_BOSS
      elseif stocks and stocks < 1 then
        ProbablyPurchasable[name .. "_index_" .. itemCounter[name]] = SHOP_LIST_STATUS_NO_STOCK
      else
        ProbablyPurchasable[name .. "_index_" .. itemCounter[name]] = SHOP_LIST_STATUS_TO_BUY
      end
    end
  end
  function InsertItemChildrenToCheck(name)
    local itemData = PanoramaShop.FormattedData[name]
    if itemData.Recipe then
      for _, newchilditem in ipairs(itemData.Recipe.items[1]) do
        DefineItemState(newchilditem)
      end
      if itemData.Recipe.cost > 0 then
        DefineItemState(itemData.Recipe.recipeItemName)
      end
    end
  end
  DefineItemState(itemName)

  local ItemsInInventory = {}
  local ItemsInStash = {}
  local ItemsToBuy = {}
  local wastedGold = 0
  for name,status in pairs(ProbablyPurchasable) do
    name = string.gsub(name, "_index_%d+", "")
    if status == SHOP_LIST_STATUS_NO_BOSS then
      Containers:DisplayError(playerID, "dota_hud_error_item_from_bosses")
      return
    elseif status == SHOP_LIST_STATUS_NO_STOCK then
      Containers:DisplayError(playerID, "dota_hud_error_item_out_of_stock")
      return
    elseif status == SHOP_LIST_STATUS_TO_BUY then
      wastedGold = wastedGold + GetTrueItemCost(name)
      table.insert(ItemsToBuy, name)
    elseif status == SHOP_LIST_STATUS_IN_INVENTORY then
      table.insert(ItemsInInventory, name)
    elseif status == SHOP_LIST_STATUS_IN_STASH then
      table.insert(ItemsInStash, name)
    end
  end

  if Gold:GetGold(playerID) >= wastedGold then
    Containers:EmitSoundOnClient(playerID, "General.Buy")
    Gold:RemoveGold(playerID, wastedGold)

    if isInShop then
      for _,v in ipairs(ItemsInStash) do
        local removedItem = FindItemInInventoryByName(unit, v, true, not isInShop)
        if not removedItem then removedItem = FindItemInInventoryByName(unit, v, false) end
        unit:RemoveItem(removedItem)
      end
      for _,v in ipairs(ItemsInInventory) do
        local removedItem = FindItemInInventoryByName(unit, v, false)
        if not removedItem then removedItem = FindItemInInventoryByName(unit, v, true, true) end
        unit:RemoveItem(removedItem)
      end
      PanoramaShop:PushItem(playerID, unit, itemName)
      if PanoramaShop.StocksTable[team][itemName] then
        PanoramaShop:DecreaseItemStock(team, itemName)
      end
    elseif #ItemsInInventory == 0 and #ItemsInStash > 0 then
      for _,v in ipairs(ItemsInStash) do
        unit:RemoveItem(FindItemInInventoryByName(unit, v, true, false))
      end
      PanoramaShop:PushItem(playerID, unit, itemName, true)
      if PanoramaShop.StocksTable[team][itemName] then
        PanoramaShop:DecreaseItemStock(team, itemName)
      end
    else
      for _,v in ipairs(ItemsToBuy) do
        PanoramaShop:PushItem(playerID, unit, v)
        if PanoramaShop.StocksTable[team][v] then
          PanoramaShop:DecreaseItemStock(team, v)
        end
      end
    end
  end
end
