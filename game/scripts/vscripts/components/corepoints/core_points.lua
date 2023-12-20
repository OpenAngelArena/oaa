
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

  self.playerID_table = {}
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

  if order == DOTA_UNIT_ORDER_PURCHASE_ITEM then
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
            --self:GiveUpgradeCoreToHero(core_points_cost, unit_with_order, playerID)
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
              SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit_with_order, gold, player)
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
  end

  return true
end

function CorePointsManager:InitializeCorePointsCounter(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() then
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

  -- Check the first recipe if it contains upgrade cores
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
  local c1 = self:GetCorePointsFullValue("item_upgrade_core")
  local c2 = self:GetCorePointsFullValue("item_upgrade_core_2")
  local c3 = self:GetCorePointsFullValue("item_upgrade_core_3")
  local c4 = self:GetCorePointsFullValue("item_upgrade_core_4")

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
  if amount ~= 0 then
    local core_points = self:GetCorePointsOnHero(unit, playerID)
    self:SetCorePointsOnHero(core_points + amount, unit, playerID)
  end
end

-- function CorePointsManager:GiveUpgradeCoreToHero(number, unit, playerID)
  -- Debug.EnableDebugging()
  -- if not unit or not playerID then
    -- print("CorePointsManager: Couldnt do GiveUpgradeCoreToHero for this unit and playerID")
    -- return
  -- end

  -- local hero = unit

  -- if not hero then
    -- hero = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(unit))
  -- end

  -- if not unit:HasModifier("modifier_core_points_counter_oaa") then
    -- hero = PlayerResource:GetSelectedHeroEntity(playerID)
  -- end

  -- if not hero then
    -- print("CorePointsManager (GiveUpgradeCoreToHero): Couldnt find a hero.")
    -- return
  -- end

  -- local item_name = ""
  -- if number == self:GetCorePointValueOfTier(1) then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 1 core")
    -- item_name = "item_upgrade_core"
  -- elseif number == self:GetCorePointValueOfTier(2) then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 2 core")
    -- item_name = "item_upgrade_core_2"
  -- elseif number == self:GetCorePointValueOfTier(3) then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 3 core")
    -- item_name = "item_upgrade_core_3"
  -- elseif number == self:GetCorePointValueOfTier(4) then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Tier 4 core")
    -- item_name = "item_upgrade_core_4"
  -- elseif number == 0 then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Item has no core point value. Not giving a core.")
    -- return
  -- else
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Special case - item has multiple cores in recipe.")
    -- return
  -- end

  -- if item_name ~= "" then
    -- DebugPrint("CorePointsManager (GiveUpgradeCoreToHero): Giving a core")
    -- hero:AddItemByName(item_name)
  -- end
-- end

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
    if parent:IsTempestDouble() or parent:IsClone() then
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
