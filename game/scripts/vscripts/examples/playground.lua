--[[

  This file is an example scenario showing a number of ways to make use of the containers.lua library.
  It works based on the "playground" map provided with barebones.

  This code creates several containers:
    1) A backpack container for every hero in the game.  This container has an item within their normal inventory
      which when used/cast opens/closes the corresponding container.
    2) An equipment container for every hero in the game.  This container has an item within their normal inventory
      which when used/cast opens/closes the corresponding container.  There are 3 item slots in this container:
      a helmet slot, a chest armor slot, and a boots slot.  Putting valid items into the correct slot will equip
      them and apply the passive associated with them (similar to the standard dota inventory).

    3) Loot Boxes which are 2x2 boxes that spawn on the map and can be looted by each player.
    4) Private Bank containers for each player, represented by a stone chest in the game world.  Opening this
      container by right clicking it shows the private bank of the player that clicked it.
    5) Shared Bank container represented by a wooden treasure chest.  Opening and using this container is
      shared among all players.
    6) Item-based Shop container represented by a golden treasure chest. This shop is availble to all players.
    7) Team-based Unit-based shops.  There is one team-shop for radiant (Ancient Apparition) and one for
      dire (Enigma). These shops can be inspected by left clicking them to select them from any distance.
    8) Crafting Materials container represented by a wooden crate.
    9) Crafting Station container represented by a workbench/table which allows for crafting things in a
      Minecraft-style.  The only recipe built-in is branch+claymore+broadsword makes a battlefury 
      (when properly oriented)

]]

if GetMapName() == "playground" then

  if not PlayGround then
    PlayGround = {}
  end

  function RandomItem(owner)
    local id = RandomInt(1,29)
    local name = Containers.itemIDs[id]
    return CreateItem(name, owner, owner)
  end

  function CreateLootBox(loc)
    local phys = CreateItemOnPositionSync(loc:GetAbsOrigin(), nil)
    phys:SetForwardVector(Vector(0,-1,0))
    phys:SetModelScale(1.5)

    local items = {}
    local slots = {1,2,3,4}
    for i=1,RandomInt(1,3) do
      items[table.remove(slots, RandomInt(1,#slots))] = RandomItem()
    end

    local cont = Containers:CreateContainer({
      layout =      {2,2},
      --skins =       {"Hourglass"},
      headerText =  "Loot Box",
      buttons =     {"Take All"},
      position =    "entity", --"mouse",--"900px 200px 0px",
      OnClose = function(playerID, container)
        print("Closed")

        if next(container:GetAllOpen()) == nil and #container:GetAllItems() == 0 then
          container:GetEntity():RemoveSelf()
          container:Delete()
          loc.container = nil

          Timers:CreateTimer(7, function()
            CreateLootBox(loc)
          end)
        end
      end,
      OnOpen = function(playerID, container)
        print("Loot box opened")
      end,
      closeOnOrder= true,
      items = items,
      entity = phys,
      range = 150,
      --OnButtonPressedJS = "ExampleButtonPressed",
      OnButtonPressed = function(playerID, container, unit, button, buttonName)
        if button == 1 then
          local items = container:GetAllItems()
          for _,item in ipairs(items) do
            container:RemoveItem(item)
            Containers:AddItemToUnit(unit,item)
          end

          container:Close(playerID)
        end
      end,
      OnEntityOrder = function(playerID, container, unit, target)
        print("ORDER ACTION loot box: ", playerID)
        container:Open(playerID)
        unit:Stop()
      end
    })

    loc.container = cont
    loc.phys = phys
  end

  function CreateShop(ii)
    local sItems = {}
    local prices = {}
    local stocks = {}

    for _,i in ipairs(ii) do
      item = CreateItem(i[1], unit, unit)
      local index = item:GetEntityIndex()
      sItems[#sItems+1] = item
      if i[2] ~= nil then prices[index] = i[2] end
      if i[3] ~= nil then stocks[index] = i[3] end
    end

    return sItems, prices, stocks
  end


  function PlayGround:OnFirstPlayerLoaded()
    Containers:SetItemLimit(100) -- default item limit is 24 for dota.  Once a unit owns more items than that, they would be unable to buy them from the dota shops
    Containers:UsePanoramaInventory(true)

    -- create initial stuff
    lootSpawns = Entities:FindAllByName("loot_spawn")
    itemDrops = Entities:FindAllByName("item_drops")
    contShopRadEnt = Entities:FindByName(nil, "container_shop_radiant")
    contShopDireEnt = Entities:FindByName(nil, "container_shop_dire")
    privateBankEnt = Entities:FindByName(nil, "private_bank")
    sharedBankEnt = Entities:FindByName(nil, "shared_bank")
    itemShopEnt = Entities:FindByName(nil, "item_shop")
    craftingEnt = Entities:FindByName(nil, "crafting_station")
    craftingMatsEnt = Entities:FindByName(nil, "crafting_mats")


    privateBankEnt = CreateItemOnPositionSync(privateBankEnt:GetAbsOrigin(), nil)
    privateBankEnt:SetModel("models/props_debris/merchant_debris_chest002.vmdl")
    privateBankEnt:SetModelScale(1.8)
    privateBankEnt:SetForwardVector(Vector(-1,0,0))

    craftingEnt = CreateItemOnPositionSync(craftingEnt:GetAbsOrigin(), nil)
    craftingEnt:SetModel("models/props_structures/bad_base_shop002.vmdl")
    craftingEnt:SetForwardVector(Vector(-1,0,0))

    craftingMatsEnt = CreateItemOnPositionSync(craftingMatsEnt:GetAbsOrigin(), nil)
    craftingMatsEnt:SetModel("models/props_debris/shop_set_cage001.vmdl")
    craftingMatsEnt:SetForwardVector(Vector(1,0,0))

    local all = {}
    for i=0,23 do all[#all+1] = i end


    sharedBankEnt = CreateItemOnPositionSync(sharedBankEnt:GetAbsOrigin(), nil)
    sharedBankEnt:SetModel("models/props_debris/merchant_debris_chest001.vmdl")
    sharedBankEnt:SetModelScale(2.3)
    sharedBankEnt:SetForwardVector(Vector(-1,0,0))

    sharedBank = Containers:CreateContainer({
      layout =      {6,4,4,6},
      headerText =  "Shared Bank",
      pids =        all,
      position =    "entity", --"600px 400px 0px",
      entity =      sharedBankEnt,
      closeOnOrder= true,
      range =       230,
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION shared bank: ", playerID)
        container:Open(playerID)
        unit:Stop()
      end,
      OnEntityDrag= function(playerID, container, unit, target, fromContainer, item)
        print("Drag ACTION shared bank: ", playerID, unit, target, fromContainer, item)
        if IsValidEntity(target) and fromContainer:ContainsItem(item) then
          fromContainer:RemoveItem(item)
          if not container:AddItem(item) then
            CreateItemOnPositionSync(unit:GetAbsOrigin() + RandomVector(10), item)
          end
        end

        unit:Stop()
      end
    })


    itemShopEnt = CreateItemOnPositionSync(itemShopEnt:GetAbsOrigin(), nil)
    itemShopEnt:SetModel("models/props_gameplay/treasure_chest001.vmdl")
    itemShopEnt:SetModelScale(2.7)
    itemShopEnt:SetForwardVector(Vector(-1,0,0))

    local ii = {}
    for i=0,RandomInt(4,8) do
      local inner = {Containers.itemIDs[RandomInt(1,29)], RandomInt(8,200)*10}
      if RandomInt(0,1) == 1 then
        inner[3] = RandomInt(3,15)
      end

      table.insert(ii, inner)
    end

    local sItems,prices,stocks = CreateShop(ii)

    itemShop = Containers:CreateShop({
      layout =      {3,3,3},
      skins =       {},
      headerText =  "Item Shop",
      pids =        {},
      position =    "entity", --"1000px 300px 0px",
      entity =      itemShopEnt,
      items =       sItems,
      prices =      prices,
      stocks =      stocks,
      closeOnOrder= true,
      range =       230,
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION item shop", playerID)
        container:Open(playerID)
        unit:Stop()
      end,
    })


    contShopRadEnt = CreateUnitByName("npc_dummy_unit", contShopRadEnt:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
    contShopRadEnt:AddNewModifier(viper, nil, "modifier_shopkeeper", {})
    contShopRadEnt:SetModel("models/heroes/ancient_apparition/ancient_apparition.vmdl")
    contShopRadEnt:SetOriginalModel("models/heroes/ancient_apparition/ancient_apparition.vmdl")
    contShopRadEnt:StartGesture(ACT_DOTA_IDLE)
    contShopRadEnt:SetForwardVector(Vector(1,0,0))

    sItems,prices,stocks = CreateShop({
      {"item_quelling_blade", 150, 3},
      {"item_quelling_blade"},
      {"item_clarity"},
      {"item_bfury", 9000},
    })

    sItems[3]:SetCurrentCharges(2)

    contRadiantShop = Containers:CreateShop({
      layout =      {2,2,2,2,2},
      skins =       {},
      headerText =  "Radiant Shop",
      pids =        {},
      position =    "entity", --"1000px 300px 0px",
      entity =      contShopRadEnt,
      items =       sItems,
      prices =      prices,
      stocks =      stocks,
      closeOnOrder= true,
      range =       300,
      --OnCloseClickedJS = "ExampleCloseClicked",
      OnSelect  =   function(playerID, container, selected)
        print("Selected", selected:GetUnitName())
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
          container:Open(playerID)
        end
      end,
      OnDeselect =  function(playerID, container, deselected)
        print("Deselected", deselected:GetUnitName())
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
          container:Close(playerID)
        end
      end,
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION radiant shop", playerID)
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS then
          container:Open(playerID)
          unit:Stop()
        else
          Containers:DisplayError(playerID, "#dota_hud_error_unit_command_restricted")
        end
      end,
    })


    contShopDireEnt = CreateUnitByName("npc_dummy_unit", contShopDireEnt:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_BADGUYS)
    contShopDireEnt:AddNewModifier(viper, nil, "modifier_shopkeeper", {})
    contShopDireEnt:SetModel("models/heroes/enigma/enigma.vmdl")
    contShopDireEnt:SetOriginalModel("models/heroes/enigma/enigma.vmdl")
    contShopDireEnt:StartGesture(ACT_DOTA_IDLE)
    contShopDireEnt:SetForwardVector(Vector(-1,0,0))

    sItems,prices,stocks = CreateShop({
      {"item_quelling_blade", 150, 3},
      {"item_quelling_blade"},
      {"item_clarity"},
      {"item_bfury", 9000},
    })

    sItems[3]:SetCurrentCharges(2)
    
    contShopDire = Containers:CreateShop({
      layout =      {2,2,2,2,2},
      skins =       {},
      headerText =  "Dire Shop",
      pids =        {},
      position =    "entity", --"1000px 300px 0px",
      entity =      contShopDireEnt,
      items =       sItems,
      prices =      prices,
      stocks =      stocks,
      closeOnOrder= true,
      range =       300,
      OnSelect  =   function(playerID, container, selected)
        print("Selected", selected:GetUnitName())
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
          container:Open(playerID)
        end
      end,
      OnDeselect  =   function(playerID, container, deselected)
        print("Deselected", deselected:GetUnitName())
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
          container:Close(playerID)
        end
      end,
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION dire shop", playerID)
        if PlayerResource:GetTeam(playerID) == DOTA_TEAM_BADGUYS then
          container:Open(playerID)
          unit:Stop()
        else
          Containers:DisplayError(playerID, "#dota_hud_error_unit_command_restricted")
        end
      end,
    })


    crafting = Containers:CreateContainer({
      layout =      {3,3,3},
      skins =       {},
      headerText =  "Crafting Station",
      pids =        {},
      position =    "entity", --"1000px 300px 0px",
      entity =      craftingEnt,
      closeOnOrder= true,
      range =       200,
      buttons =     {"Craft"},
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION crafting station", playerID)
        container:Open(playerID)
        unit:Stop()
      end,
      OnButtonPressed = function(playerID, container, unit, button, buttonName)
        if button == 1 then
          local all = container:GetAllItems()
          local branches = container:GetItemsByName("item_branches")
          local broadswords = container:GetItemsByName("item_broadsword")
          local claymores = container:GetItemsByName("item_claymore")
          print(#all, #branches, #broadswords, #claymores)

          if #all == 3 and #branches == 1 and #broadswords == 1 and #claymores == 1 then
            local row,col = container:GetRowColumnForItem(branches[1])
            local row2,col2 = container:GetRowColumnForItem(broadswords[1])
            local row3,col3 = container:GetRowColumnForItem(claymores[1])
            print(row,col)
            print(row2,col2)
            print(row3,col3)
            if row == 3 and row2+row3 == 3 and col == col2 and col == col3 then
              for _,item in ipairs(all) do
                container:RemoveItem(item)
              end
              container:AddItem(CreateItem("item_bfury",unit,unit), 2, 2)
            end
          end
        end
      end,
    })

    craftingMats = Containers:CreateContainer({
      layout =      {3,3,3},
      skins =       {},
      headerText =  "Materials",
      pids =        {},
      position =    "entity", --"1000px 300px 0px",
      entity =      craftingMatsEnt,
      closeOnOrder= true,
      range =       200,
      buttons =     {},
      OnEntityOrder=function(playerID, container, unit, target)
        print("ORDER ACTION crafting mats", playerID)
        container:Open(playerID)
        unit:Stop()
      end,
    })

    item = CreateItem("item_branches", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_branches", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_broadsword", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_branches", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_claymore", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_claymore", nil, nil)
    craftingMats:AddItem(item)
    item = CreateItem("item_branches", nil, nil)
    craftingMats:AddItem(item)



    for _,loc in ipairs(lootSpawns) do
      CreateLootBox(loc)
    end

    for _,loc in ipairs(itemDrops) do
      local phys = CreateItemOnPositionSync(loc:GetAbsOrigin(), RandomItem())
      phys:SetForwardVector(Vector(0,-1,0))

      loc.phys = phys
    end

    Timers:CreateTimer(.1, function()    
      GameRules:GetGameModeEntity():SetCameraDistanceOverride( 1500 )
    end)

    Timers:CreateTimer(function()
      for _,loc in ipairs(itemDrops) do
        if not IsValidEntity(loc.phys) then
          local phys = CreateItemOnPositionSync(loc:GetAbsOrigin(), RandomItem())
          phys:SetForwardVector(Vector(0,-1,0))

          loc.phys = phys
        end
      end
      return 15
    end)
  end

  function PlayGround:OnHeroInGame(hero)
    -- create inventory
    print(pid, hero:GetName())
    local pid = hero:GetPlayerID()

    local validItemsBySlot = {
      [1] = --helm
        {item_helm_of_iron_will=  true,
        item_veil_of_discord=     true},
      [2] = --chest
        {item_chainmail=          true,
        item_blade_mail=          true},
      [3] = --boots
        {item_boots=              true,
        item_phase_boots=         true},
    }

    local c = Containers:CreateContainer({
      layout =      {3,4,4},
      skins =       {},
      headerText =  "Backpack",
      pids =        {pid},
      entity =      hero,
      closeOnOrder =false,
      position =    "75% 25%",
      OnDragWorld = true,
      OnRightClickJS = "SpecialContextMenu",
      OnRightClick = function(playerID, container, unit, item, slot)
        print("RIGHT CLICK")
        local armor = pidEquipment[playerID]
        for i,valid in pairs(validItemsBySlot) do
          for itemname,_ in pairs(valid) do
            if itemname == item:GetAbilityName() then
              Containers:OnDragFrom(playerID, container, unit, item, slot, armor, i)
            end
          end
        end
      end
    })

    pidInventory[pid] = c

    local item = CreateItem("item_tango", hero, hero)
    c:AddItem(item, 4)

    item = CreateItem("item_tango", hero, hero)
    c:AddItem(item, 6)

    item = CreateItem("item_ring_of_basilius", hero, hero)
    c:AddItem(item, 8)

    item = CreateItem("item_phase_boots", hero, hero)
    c:AddItem(item, 9)

    item = CreateItem("item_force_staff", hero, hero)
    c:AddItem(item)

    item = CreateItem("item_blade_mail", hero, hero)
    c:AddItem(item)

    item = CreateItem("item_veil_of_discord", hero, hero)
    c:AddItem(item)

    privateBank[pid] = Containers:CreateContainer({
      layout =      {4,4,4,4},
      headerText =  "Private Bank",
      pids =        {pid},
      position =    "entity", --"200px 200px 0px",
      entity =      privateBankEnt,
      closeOnOrder= true,
      forceOwner =  hero,
      forcePurchaser=hero,
      range =       250,
      OnEntityOrder =function(playerID, container, unit, target)
        print("ORDER ACTION private bank: ", playerID)
        if privateBank[playerID] then
          privateBank[playerID]:Open(playerID)
        end
        unit:Stop()
      end,
    })

    defaultInventory[pid] = true
    Containers:SetDefaultInventory(hero, c)

    local pack = CreateItem("item_containers_lua_pack", hero, hero)
    pack.container = c
    hero:AddItem(pack)

    c = Containers:CreateContainer({
      layout =      {1,1,1},
      skins =       {"Hourglass"},
      headerText =  "Armor",
      pids =        {pid},
      entity =      hero,
      closeOnOrder =false,
      position =    "200px 500px 0px",
      equipment =   true,
      layoutFile =  "file://{resources}/layout/custom_game/containers/alt_container_example.xml",
      OnDragWithin = false,
      OnRightClickJS = "ExampleRightClick",
      OnMouseOverJS = "ExampleMouseOver",
      AddItemFilter = function(container, item, slot)
        print("Armor, AddItemFilter: ", container, item, slot)
        if slot ~= -1 and validItemsBySlot[slot][item:GetAbilityName()] then
          return true
        end
        return false
      end,
    })

    pidEquipment[pid] = c

    item = CreateItem("item_helm_of_iron_will", hero, hero)
    c:AddItem(item, 1)

    item = CreateItem("item_chainmail", hero, hero)
    c:AddItem(item, 2)

    item = CreateItem("item_boots", hero, hero)
    c:AddItem(item, 3)

    pack = CreateItem("item_containers_lua_pack", hero, hero)
    pack.container = c
    hero:AddItem(pack)
  end


  function PlayGround:OnNPCSpawned(keys)
    local npc = EntIndexToHScript(keys.entindex)

    if npc:IsRealHero() and npc.bFirstSpawnedPG == nil then
      npc.bFirstSpawnedPG = true
      PlayGround:OnHeroInGame(npc)
    end
  end

  function PlayGround:OnConnectFull(keys)
    if OFPL then
      PlayGround:OnFirstPlayerLoaded()
      OFPL = false
    end
  end

  if LOADED then
    return
  end
  LOADED = true
  OFPL = true

  MAX_NUMBER_OF_TEAMS = 2
  USE_AUTOMATIC_PLAYERS_PER_TEAM = true

  ListenToGameEvent('npc_spawned', Dynamic_Wrap(PlayGround, 'OnNPCSpawned'), PlayGround)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(PlayGround, 'OnConnectFull'), PlayGround)

  pidInventory = {}
  pidEquipment = {}
  lootSpawns = nil
  itemDrops = nil
  privateBankEnt = nil
  sharedBankEnt = nil
  contShopRadEnt = nil
  contShopDireEnt = nil
  itemShopEnt = nil

  craftingEnt = nil
  craftingMatsEnt = nil

  crafting = nil
  craftingMats = nil
  contShopRad = nil
  contShopDire = nil
  itemShop = nil
  sharedBank = nil
  privateBank = {}

  defaultInventory = {}
end