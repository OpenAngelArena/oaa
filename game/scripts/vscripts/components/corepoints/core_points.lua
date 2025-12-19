
if CorePointsManager == nil then
  if Debug == nil or DebugPrint == nil then
    require('internal/util')
  end
  --Debug.EnableDebugging()
  DebugPrint("Creating CorePointsManager.")
  CorePointsManager = class({})
end

function CorePointsManager:Init()
  self.moduleName = "CorePointsManager"
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(CorePointsManager, "FilterOrders"))
  GameEvents:OnHeroInGame(partial(self.InitializeCorePointsCounter, self))
  ChatCommand:LinkDevCommand("-corepoints", Dynamic_Wrap(CorePointsManager, "CorePointsCommand"), self)
  local upgrade_items_ids = self:ItemIdTableCreate()
  CustomNetTables:SetTableValue("item_kv", "upgrade_items", upgrade_items_ids)
  self.playerID_table = {}
  CustomGameEventManager:RegisterListener("oaa_upgrade_item", Dynamic_Wrap(CorePointsManager, "UpgradeItemButtonPressed"))
  CustomGameEventManager:RegisterListener("oaa_purchase_core", Dynamic_Wrap(CorePointsManager, "PurchaseCoreButtonPressed"))
end

local forcedUpgrades = {
  item_power_treads = "item_greater_power_treads",
  item_desolator = "item_devastator_oaa_2",
}

function CorePointsManager:ItemIdTableCreate()
  local custom_items = LoadKeyValues("scripts/npc/npc_items_custom.txt")
  local upgrade_item_ids = {}
  for item_name, item_values in pairs(custom_items) do
    if (item_values["UpgradesItems"] ~= nil and item_values["UpgradesItems"] ~= "") then
      local item_ids_needed = self:GetUpgradeItemIds(item_name, item_values["UpgradesItems"])
      upgrade_item_ids[item_name] = item_ids_needed
    end
  end
  for item_name, item_upgrades in pairs(forcedUpgrades) do
    local item_ids_needed = self:GetUpgradeItemIds(item_name, item_upgrades)
    upgrade_item_ids[item_name] = item_ids_needed
  end
  return upgrade_item_ids
end

function CorePointsManager:GetUpgradeItemIds(item_name, item_upgrade)
  local item_ids_needed = {}
  local item_upgrade_recipe = item_upgrade:gsub("item_", "item_recipe_")
  local item_requirements = {}
  local recipe_kvs = GetAbilityKeyValuesByName(item_upgrade_recipe)
  if not recipe_kvs then
    print("KVs for recipe "..tostring(item_upgrade_recipe).." do not exist.")
  end
  for substr in recipe_kvs["ItemRequirements"]["01"]:gmatch("([^;]+)") do
    table.insert(item_requirements, substr)
  end
  local needs_upgrade_core = false
  for index, value in ipairs(item_requirements) do
    local item_kvs = GetAbilityKeyValuesByName(value)
    if item_kvs then
      if (item_kvs["ItemCorePointCost"] ~= nil and item_kvs["ItemCost"] ~= nil) then
        if (item_kvs["ItemCorePointCost"] > 0 and item_kvs["ItemCost"] == 1) then
          --print(value)
          table.insert(item_ids_needed, item_kvs["ID"])
          needs_upgrade_core = true
        end
      end
    else
      print("KVs for "..tostring(value).." do not exist.")
    end
  end
  if needs_upgrade_core then
    --print(item_upgrade_recipe)
    table.insert(item_ids_needed, recipe_kvs["ID"])
  else
    for index, value in ipairs(item_requirements) do
      if value ~= item_name then
        table.insert(item_ids_needed, GetAbilityKeyValuesByName(value)["ID"])
      end
    end
  end
  return item_ids_needed
end

function CorePointsManager:BuyIfAllowed(item, hero, playerID)
  local current_gold = Gold:GetGold(playerID)
  local current_cps = CorePointsManager:GetCorePointsOnHero(hero, playerID)
  local gold_cost = GetItemCost(item)
  local cp_cost = CorePointsManager:GetCorePointsFullValue(item)
  -- Check for core point cost
  if current_cps >= cp_cost then
    local allowed_to_buy = true
    local tier = CorePointsManager:GetTierFromCorePointCost(cp_cost)
    if cp_cost > CorePointsManager:GetCorePointValueOfTier(1) then
      if BossSpawner then
        allowed_to_buy = BossSpawner.hasKilledTiers[tier] == true
      end
      if CapturePoints and CapturePoints.currentCapture == nil and CapturePoints.NumCaptures >= tier then
        allowed_to_buy = true -- Both Capture Points of corresponding tier were captured
      end
    end

    if allowed_to_buy then
      -- Check for gold cost
      if current_gold >= gold_cost then
        if hero:HasRoomForItemOAA() then
          CorePointsManager:AddCorePoints(-cp_cost, hero, playerID)
          Gold:ModifyGold(hero, -gold_cost, true, DOTA_ModifyGold_PurchaseItem)
          hero:AddItemByName(item)
          -- Sound for the player only
          EmitSoundOnClient("General.Buy", PlayerResource:GetPlayer(playerID))
          hero:EmitSound("General.Buy") -- plays on the hero
        else
          local error_msg_inventory_full = "#dota_hud_error_cant_pick_up_item"
          CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg_inventory_full})
        end
      else
        -- Error - not enough gold
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 63})
      end
    else
      -- Error - requirements not met
      local error_msg1 = "#oaa_hud_error_requires_tier_" .. tostring(tier) .. "_boss_or_cp"
      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg1})
    end
  else
    -- Error - not enough core points
    --local needed = cp_cost - current_cps
    local error_msg2 = "#oaa_hud_error_not_enough_core_points" --.. tostring(needed) .. "#oaa_hud_error_more_needed"
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg2})
  end
end

function CorePointsManager:UpgradeItemButtonPressed(event)
  local pid = event.PlayerID
  local item_name = event.itemName
  local purchaser = PlayerResource:GetSelectedHeroEntity(pid)

  local item_kvs = GetAbilityKeyValuesByName(item_name)
  local item_upgrade = item_kvs.UpgradesItems
  for name, upgrade in pairs(forcedUpgrades) do
    if name == item_name then
      item_upgrade = upgrade
      break
    end
  end

  if item_upgrade ~= nil and item_upgrade ~= "" then
    local item_requirements = {}
    local item_upgrade_recipe = item_upgrade:gsub("item_", "item_recipe_")
    local recipe_kvs = GetAbilityKeyValuesByName(item_upgrade_recipe)
    if not recipe_kvs then
      print("KVs for recipe "..tostring(item_upgrade_recipe).." do not exist.")
      return
    end
    if not purchaser:HasItemAlreadyOAA(item_upgrade_recipe) then
      CorePointsManager:BuyIfAllowed(item_upgrade_recipe, purchaser, pid)
    end
    for substr in recipe_kvs["ItemRequirements"]["01"]:gmatch("([^;]+)") do
      table.insert(item_requirements, substr)
    end
    for _, item in ipairs(item_requirements) do
      if item ~= item_name then
        local sub_item_kvs = GetAbilityKeyValuesByName(item)
        if sub_item_kvs then
          if not purchaser:HasItemAlreadyOAA(item) then
            CorePointsManager:BuyIfAllowed(item, purchaser, pid)
          end
        else
          print("KVs for "..tostring(item).." do not exist.")
        end
      end
    end
  end
end

function CorePointsManager:PurchaseCoreButtonPressed(event)
  local pid = event.PlayerID
  local core_tier = event.tier
  local purchaser = PlayerResource:GetSelectedHeroEntity(pid)
  local item_name = "item_upgrade_core"
  if tonumber(core_tier) ~= 1 then
    item_name = item_name.."_"..tostring(core_tier)
  end

  CorePointsManager:BuyIfAllowed(item_name, purchaser, pid)
end

function CorePointsManager:GetState()
  local state = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if steamid ~= "0" then
      state[steamid] = self.playerID_table[playerID]
    end
  end

  return state
end

function CorePointsManager:LoadState(state)
  if not state then
    -- CorePointsManager didn't exist when state was saved
    return
  end

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if steamid ~= "0" and state[steamid] then
      self.playerID_table[playerID] = state[steamid]
    end
  end
end

function CorePointsManager:FilterOrders(keys)
  local order = keys.order_type
  local units = keys.units
  local playerID = keys.issuer_player_id_const

  local unit_with_order
  if units and units["0"] then
    unit_with_order = EntIndexToHScript(units["0"])
  end
  local ability_index = keys.entindex_ability
  local ability
  if ability_index then
    ability = EntIndexToHScript(ability_index)
  end
  local shop_item = keys.shop_item_name
  local target_index = keys.entindex_target
  local target
  if target_index then
    target = EntIndexToHScript(target_index)
  end

  -- DOTA_UNIT_ORDER_DROP_ITEM = 12
  -- DOTA_UNIT_ORDER_GIVE_ITEM = 13
  -- DOTA_UNIT_ORDER_PICKUP_ITEM = 14
  -- DOTA_UNIT_ORDER_PURCHASE_ITEM = 16
  -- DOTA_UNIT_ORDER_SELL_ITEM = 17
  -- DOTA_UNIT_ORDER_DISASSEMBLE_ITEM = 18
  -- DOTA_UNIT_ORDER_MOVE_ITEM = 19
  -- DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH = 25
  -- DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK = 32
  -- DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN = 37
  -- DOTA_UNIT_ORDER_TAKE_ITEM_FROM_NEUTRAL_ITEM_STASH = 39
  -- DOTA_UNIT_ORDER_CONSUME_ITEM = 41
  -- DOTA_UNIT_ORDER_SET_ITEM_MARK_FOR_SELL = 42

  if order == DOTA_UNIT_ORDER_PURCHASE_ITEM then -- ignores items purchased through quickbuy
    -- Check if needed variables exist
    if unit_with_order and shop_item then
      local core_points_cost = self:GetCorePointsFullValue(shop_item)
      local purchaser_core_points = self:GetCorePointsOnHero(unit_with_order, playerID)
      if purchaser_core_points >= core_points_cost then
        if core_points_cost ~= 0 then
          local allowed_to_buy = true
          local tier = CorePointsManager:GetTierFromCorePointCost(core_points_cost)
          if core_points_cost > self:GetCorePointValueOfTier(1) then
            allowed_to_buy = BossSpawner.hasKilledTiers[tier] == true
            if CapturePoints and CapturePoints.currentCapture == nil and CapturePoints.NumCaptures >= tier then
              allowed_to_buy = true -- Both Capture Points of corresponding tier were captured
            end
          end
          if allowed_to_buy then
            self:AddCorePoints(-core_points_cost, unit_with_order, playerID)
            local shop_item_name -- string
            if type(shop_item) == 'string' then
              shop_item_name = shop_item
            else
              shop_item_name = shop_item:GetName()
            end
            if shop_item_name == "item_core_info" and Gold then
              local gold = self:GetGoldValueOfCorePoint()
              local player = PlayerResource:GetPlayer(playerID)
              -- Convert Core Points to Gold
              Gold:ModifyGold(unit_with_order, gold, true, DOTA_ModifyGold_SellItem)
              -- Gold text/number over unit's head
              SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit_with_order, gold, nil)
              -- Sound for the player only
              EmitSoundOnClient("General.Sell", player)
              return false
            end
          else
            -- Error - requirements not met
            local error_msg1 = "#oaa_hud_error_requires_tier_" .. tostring(tier) .. "_boss_or_cp"
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg1})
            return false
          end
        end
      else
        -- Error - not enough core points
        --local needed = core_points_cost - purchaser_core_points
        local error_msg2 = "#oaa_hud_error_not_enough_core_points" --.. tostring(needed) .. "#oaa_hud_error_more_needed"
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg2})
        return false
      end
    end
  elseif order == DOTA_UNIT_ORDER_SELL_ITEM then
    if unit_with_order and ability then
      --local purchaser = ability:GetPurchaser()
      self:AddCorePoints(self:GetCorePointsSellValue(ability), unit_with_order, playerID)
    end
  elseif order == DOTA_UNIT_ORDER_GIVE_ITEM then
    if unit_with_order and ability and target then
      if string.find(target:GetName(), "shop") ~= nil then
        --local purchaser = ability:GetPurchaser()
        self:AddCorePoints(self:GetCorePointsSellValue(ability), unit_with_order, playerID)
      end
    end
  elseif order == DOTA_UNIT_ORDER_SET_ITEM_MARK_FOR_SELL then
    if unit_with_order and ability then
      local item_name = ability:GetName()
      if string.find(item_name, "item_upgrade_core") then
        -- Grant core points value of the upgrade core
        self:AddCorePoints(self:GetCorePointsSellValue(ability), unit_with_order, playerID)
        -- Remove the item
        unit_with_order:RemoveItem(ability)
        -- Sounds
        EmitSoundOnClient("General.Sell", PlayerResource:GetPlayer(playerID)) -- plays only in the center of the map for some reason
        unit_with_order:EmitSound("General.Sell") -- plays on the hero
        return false
      end
      if CorePointsManager:GetCorePointsFullValue(ability) > 0 then
        local error_msg3 = "#oaa_hud_error_cannot_mark_to_sell"
        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg3})
        return false
      end
    end
  end

  return true
end

function CorePointsManager:InitializeCorePointsCounter(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
    return
  end

  --Timers:CreateTimer(2, function ()
  if not hero:HasModifier("modifier_core_points_counter_oaa") then
    hero:AddNewModifier(hero, nil, "modifier_core_points_counter_oaa", {})
  end

  if self.playerID_table[UnitVarToPlayerID(hero)] == nil then
    self.playerID_table[UnitVarToPlayerID(hero)] = 0
  end
  --end)
end

function CorePointsManager:GetCorePointValueOfTier(tier)
  if tier == 1 then
    return 2
  elseif tier == 2 then
    return 4
  elseif tier == 3 then
    return 8
  elseif tier == 4 then
    return 16
  else
    return 0
  end
end

function CorePointsManager:GetGoldValueOfCorePoint()
  return 750
end

-- Unused until Valve fixes Quickbuy ignoring the filter
function CorePointsManager:GetCorePointValueOfUpdgradeCore(item_name)
  return self:GetCorePointsFullValue(item_name)
end

function CorePointsManager:GetTierFromCorePointCost(number)
  if number > 0 and number <= self:GetCorePointValueOfTier(1) then
    return 1
  elseif number > self:GetCorePointValueOfTier(1) and number <= self:GetCorePointValueOfTier(2) then
    return 2
  elseif number > self:GetCorePointValueOfTier(2) and number <= self:GetCorePointValueOfTier(3) then
    return 3
  elseif number > self:GetCorePointValueOfTier(3) and number <= self:GetCorePointValueOfTier(4) then
    return 4
  elseif number == 0 then
    return 0
  else
    print("CorePointsManager (GetTierFromCorePointCost): Unusual core point cost.")
    return 4
  end
end

function CorePointsManager:GetCorePointsFullValue(item)
  --Debug.EnableDebugging()
  if not item then
    print("CorePointsManager (GetCorePointsFullValue): item doesn't exist.")
    return 0
  end

  local item_name -- string
  local recipe_check -- boolean
  if type(item) == 'string' then
    item_name = item
    recipe_check = string.find(item_name, "item_recipe_")
  else
    item_name = item:GetName()
    recipe_check = item:IsRecipe()
  end

  --DebugPrint("Item that is being checked: "..item_name)

  -- Check if the item is a recipe item
  local recipe_name
  if recipe_check then
    recipe_name = item_name
  else
    recipe_name = string.gsub(item_name, "item_", "item_recipe_")
  end

  --DebugPrint("Recipe of the item that is being checked: "..recipe_name)

  -- Get KV data of the item and recipe
  local item_data = GetAbilityKeyValuesByName(item_name)
  local recipe_data = GetAbilityKeyValuesByName(recipe_name)

  if not item_data then
    print("CorePointsManager (GetCorePointsFullValue): item data doesn't exist for "..item_name)
    return 0
  end

  if item_data["ItemCorePointCost"] and item_data["ItemCorePointCost"] ~= "" then
    return tonumber(item_data["ItemCorePointCost"]) -- Full Value of the item in core points set in KV file
  end

  -- Calculate ItemCorePointCost (full value) through the recipe because it's not set in KV file
  -- If recipe doesn't exist, that's not possible to do
  if not recipe_data then
    DebugPrint("CorePointsManager (GetCorePointsFullValue): recipe data doesn't exist for "..item_name)
    return 0
  end

  if recipe_check then
    -- Item is a recipe and item_data["ItemCorePointCost"] is nil or empty
    DebugPrint("CorePointsManager (GetCorePointsFullValue): ItemCorePointCost key-value not set properly for "..item_name)
    return 0
  end

  -- Item Requirements table - table of strings
  local item_req = recipe_data["ItemRequirements"]

  -- If Item Requirements table doesn't exist, it's not possible to calculate ItemCorePointCost (full value)
  if not item_req then
    DebugPrint("CorePointsManager (GetCorePointsFullValue): recipe "..recipe_name.." doesn't contain ItemRequirements!")
    return 0
  end

  -- First recipe
  local req_string = item_req["01"]

  -- Check the first recipe if it contains upgrade cores (HAVING MULTIPLE UPGRADE CORES IN THE RECIPE IS NOT SUPPORTED with the following code!)
  local uc1 = string.find(req_string, "upgrade_core", -15)
  local uc2 = string.find(req_string, "upgrade_core_2", -15)
  local uc3 = string.find(req_string, "upgrade_core_3", -15)
  local uc4 = string.find(req_string, "upgrade_core_4", -15)

  local recipe_value = 0
  if recipe_data["ItemCorePointCost"] and recipe_data["ItemCorePointCost"] ~= "" then
    recipe_value = tonumber(recipe_data["ItemCorePointCost"]) -- Value of the recipe
  end

  -- Full value (important when selling items)
  -- Tier 1 items = upgrade core 1 value;
  -- T2 items = upgrade core 2 value + upgrade core 1 value;
  -- T3 items = upgrade core 3 value + upgrade core 2 value + upgrade core 1 value;
  -- T4 items = upgrade core 4 value + upgrade core 3 value + upgrade core 2 value + upgrade core 1 value;
  local full_value = recipe_value

  -- Value of Upgrade Cores in core points:
  local c1 = self:GetCorePointsFullValue("item_upgrade_core") -- or self:GetCorePointValueOfTier(1) if core point cost is not set in upgrade core's kvs
  local c2 = self:GetCorePointsFullValue("item_upgrade_core_2") -- or self:GetCorePointValueOfTier(2) if core point cost is not set in upgrade core 2's kvs
  local c3 = self:GetCorePointsFullValue("item_upgrade_core_3") -- or self:GetCorePointValueOfTier(3) if core point cost is not set in upgrade core 3's kvs
  local c4 = self:GetCorePointsFullValue("item_upgrade_core_4") -- or self:GetCorePointValueOfTier(4) if core point cost is not set in upgrade core 4's kvs

  if uc1 then
    if uc2 then
      full_value = recipe_value + c2 + c1
    elseif uc3 then
      full_value = recipe_value + c3 + c2 + c1
    elseif uc4 then
      full_value = recipe_value + c4 + c3 + c2 + c1
    else
      full_value = recipe_value + c1
    end
  end

  DebugPrint("Core point value of "..item_name.." is: "..tostring(full_value))

  return full_value
end

function CorePointsManager:GetCorePointsSellValue(item)
  local item_name -- string
  if type(item) == 'string' then
    item_name = item
  else
    item_name = item:GetName()
  end

  if item_name == "item_upgrade_core" or item_name == "item_upgrade_core_2" or item_name == "item_upgrade_core_3" or item_name == "item_upgrade_core_4" then
    return self:GetCorePointsFullValue(item)
  end

  return self:GetCorePointsFullValue(item) -- full refund
end

function CorePointsManager:GetCorePointsOnHero(unit, playerID)
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do GetCorePointsOnHero for this unit and playerID")
    return 0
  end

  local hero = unit

  if not unit:HasModifier("modifier_core_points_counter_oaa") then
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if not hero then
    print("CorePointsManager (GetCorePointsOnHero): Couldnt find a hero.")
    return self.playerID_table[UnitVarToPlayerID(unit)]
  end

  local counter = hero:FindModifierByName("modifier_core_points_counter_oaa")
  if not counter then
    print("CorePointsManager (GetCorePointsOnHero): Couldnt find a counter buff.")
    return self.playerID_table[UnitVarToPlayerID(hero)]
  end

  return counter:GetStackCount()
end

function CorePointsManager:SetCorePointsOnHero(number, unit, playerID)
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do SetCorePointsOnHero for this unit and playerID")
    return
  end

  local hero = unit

  if not unit:HasModifier("modifier_core_points_counter_oaa") then
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if not hero then
    print("CorePointsManager (SetCorePointsOnHero): Couldnt find a hero.")
    self.playerID_table[UnitVarToPlayerID(unit)] = number
    return
  end

  self.playerID_table[UnitVarToPlayerID(hero)] = number

  local counter = hero:FindModifierByName("modifier_core_points_counter_oaa")
  if not counter then
    print("CorePointsManager (SetCorePointsOnHero): Couldnt find a counter buff.")
    return
  end

  counter:SetStackCount(number)

  -- Send a custom event to the player because number of core points change
  CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "core_point_number_changed", {cp = number})
end

function CorePointsManager:AddCorePoints(amount, unit, playerID)
  -- Avoid calling SetCorePointsOnHero if amount (core point change) is 0
  -- amount can be negative
  if amount ~= 0 then
    local core_points = self:GetCorePointsOnHero(unit, playerID)
    self:SetCorePointsOnHero(core_points + amount, unit, playerID)
  end
end

-- Unused
function CorePointsManager:GiveUpgradeCoreToHero(number, unit, playerID)
  Debug.EnableDebugging()
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do GiveUpgradeCoreToHero for this unit and playerID")
    return
  end

  local hero = unit

  if not hero then
    hero = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(unit))
  end

  if not unit:HasModifier("modifier_core_points_counter_oaa") then
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if not hero then
    print("CorePointsManager (GiveUpgradeCoreToHero): Couldnt find a hero.")
    return
  end

  local item_name = ""
  if number == self:GetCorePointValueOfTier(1) then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 1 core")
    item_name = "item_upgrade_core"
  elseif number == self:GetCorePointValueOfTier(2) then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 2 core")
    item_name = "item_upgrade_core_2"
  elseif number == self:GetCorePointValueOfTier(3) then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 3 core")
    item_name = "item_upgrade_core_3"
  elseif number == self:GetCorePointValueOfTier(4) then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 4 core")
    item_name = "item_upgrade_core_4"
  elseif number == 0 then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Item has no core point value. Not giving a core.")
    return
  else
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Special case - item has multiple cores in recipe.")
    return
  end

  if item_name ~= "" then
    DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Giving a core")
    if hero:HasRoomForItemOAA() then
      hero:AddItemByName(item_name)
    else
      local error_msg_inventory_full = "#dota_hud_error_cant_pick_up_item"
      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg_inventory_full})
    end
  end
end

-- Unused until Valve fixes Quickbuy ignoring the filter
function CorePointsManager:GiveCorePointsToWholeTeam(amount, teamID)
  PlayerResource:GetPlayerIDsForTeam(teamID):each(function (playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
      CorePointsManager:AddCorePoints(amount, hero, playerID)
    end
  end)
end

function CorePointsManager:CorePointsCommand(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local points = tonumber(splitted[2]) or 1
  self:SetCorePointsOnHero(points, hero, keys.playerid)
end

---------------------------------------------------------------------------------------------------

modifier_core_points_counter_oaa = class({})

function modifier_core_points_counter_oaa:IsHidden()
  return true
end

function modifier_core_points_counter_oaa:IsPurgable()
  return false
end

function modifier_core_points_counter_oaa:RemoveOnDeath()
  return false
end

function modifier_core_points_counter_oaa:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    if parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
      self:Destroy()
      return
    end

    local count = CorePointsManager.playerID_table[UnitVarToPlayerID(parent)] or 0
    self:SetStackCount(count)
  end
end

-- function modifier_core_points_counter_oaa:OnStackCountChanged(old_stacks)
  -- if not IsServer() then
    -- return
  -- end
  -- local parent = self:GetParent()
  -- local playerID = UnitVarToPlayerID(parent)
  -- local player = PlayerResource:GetPlayer(playerID)
  -- local stack_count = self:GetStackCount()

  -- CustomGameEventManager:Send_ServerToPlayer(player, "core_point_number_changed", {cp = stack_count})
-- end
