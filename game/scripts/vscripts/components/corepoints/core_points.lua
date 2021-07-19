
if CorePointsManager == nil then
  Debug.EnableDebugging()
  DebugPrint("Creating CorePointsManager.")
  CorePointsManager = class({})
end

function CorePointsManager:Init()
  if self.initialized then
    print("CorePointsManager is already initialized and there was an attempt to initialize it again -> preventing")
    return nil
  end
  LinkLuaModifier("modifier_core_points_counter_oaa", "components/corepoints/core_points.lua", LUA_MODIFIER_MOTION_NONE)
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(CorePointsManager, "FilterOrders"))
  GameEvents:OnHeroInGame(partial(self.InitializeCorePointsCounter, self))
  ChatCommand:LinkDevCommand("-corepoints", Dynamic_Wrap(CorePointsManager, "CorePointsCommand"), self)

  self.playerID_table = {}
  self.initialized = true
end

function CorePointsManager:GetState()
  return {
    --playerID_table = self.playerID_table,
  }
end

function CorePointsManager:LoadState(state)
  --self.playerID_table = state.playerID_table
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
            if CapturePoints.currentCapture == nil and CapturePoints.NumCaptures >= tier then
              allowed_to_buy = true -- Capture Point of corresponding tier was captured
            end
          end
          if allowed_to_buy then
            self:AddCorePoints(-core_points_cost, unit_with_order, playerID)
            --self:GiveUpgradeCoreToHero(core_points_cost, unit_with_order, playerID)
          else
            -- Error - requirements not met
            local error_msg1 = "#oaa_hud_error_requires_tier" .. tostring(tier) .. "#oaa_hud_error_boss_or_cp"
            CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 80, message = error_msg1})
            return false
          end
        end
      else
        -- Error - not enough core points
        local needed = core_points_cost - purchaser_core_points
        local error_msg2 = "#oaa_hud_error_not_enough_core_points" .. tostring(needed) .. "#oaa_hud_error_more_needed"
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

function CorePointsManager:GetCorePointValueOfUpdgradeCore(item_name)
  if item_name == "item_upgrade_core" then
    return self:GetCorePointValueOfTier(1)
  elseif item_name == "item_upgrade_core_2" then
    return self:GetCorePointValueOfTier(2)
  elseif item_name == "item_upgrade_core_3" then
    return self:GetCorePointValueOfTier(3)
  elseif item_name == "item_upgrade_core_4" then
    return self:GetCorePointValueOfTier(4)
  else
    return self:GetCorePointsFullValue(item_name)
  end
end

function CorePointsManager:GetTierFromCorePointCost(number)
  if number == self:GetCorePointValueOfTier(1) then
    return 1
  elseif number == self:GetCorePointValueOfTier(2) then
    return 2
  elseif number == self:GetCorePointValueOfTier(3) then
    return 3
  elseif number == self:GetCorePointValueOfTier(4) then
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

  -- Get KV data of the recipe item
  local recipe_data = GetAbilityKeyValuesByName(recipe_name)
  if not recipe_data then
    DebugPrint("CorePointsManager (GetCorePointsFullValue): recipe data doesn't exist for this item.")
    return 0
  end

  if not recipe_data["ItemCorePointCost"] or recipe_data["ItemCorePointCost"] == "" then
    print("ItemCorePointCost key-value not set properly for "..recipe_name)
    return 0
  end

  -- Recipe value (important when buying items)
  local recipe_value = tonumber(recipe_data["ItemCorePointCost"]) -- Value of the recipe (for recipes themselves full_value and recipe_value are the same)

  -- Full value (important when selling items)
  -- Tier 1 items = 2 core points; T2 items = 2+4 core points; T3 items = 2+4+8 core points; T4 items = 2+4+8+16 core points;
  local full_value = 0
  local item_data = GetAbilityKeyValuesByName(item_name)
  if item_data["ItemCorePointCost"] and item_data["ItemCorePointCost"] ~= "" then
    full_value = tonumber(item_data["ItemCorePointCost"]) -- Full Value of the item in core points set in KV file
  end

  -- Value of Upgrade Cores in core points:
  local c1 = self:GetCorePointValueOfTier(1)
  local c2 = self:GetCorePointValueOfTier(2)
  local c3 = self:GetCorePointValueOfTier(3)
  local c4 = self:GetCorePointValueOfTier(4)

  -- Calculate full value of the item if KV is not set
  if full_value == 0 then
    if recipe_value == c1 then
      full_value = c1
    elseif recipe_value == c2 then
      full_value = c2 + c1
    elseif recipe_value == c3 then
      full_value = c3 + c2 + c1
    elseif recipe_value == c4 then
      full_value = c4 + c3 + c2 + c1
    else
      full_value = recipe_value -- temporary
    end
  end

  if recipe_check then
    DebugPrint("Core point value of "..item_name.." is: "..tostring(recipe_value))
    -- Return only the value of the recipe
    return recipe_value
  else
    DebugPrint("Core point value of "..item_name.." is: "..tostring(full_value))
    DebugPrint("Core point value of "..recipe_name.." is: "..tostring(recipe_value))
    -- Return full value
    return full_value
  end
end

function CorePointsManager:GetCorePointsSellValue(item)
  -- Recipes are worth full value
  if item:IsRecipe() then
    return self:GetCorePointsFullValue(item)
  else
    return math.floor(self:GetCorePointsFullValue(item) / 2)
  end
end

function CorePointsManager:GetCorePointsOnHero(unit, playerID)
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do GetCorePointsOnHero for this unit and playerID")
    return 0
  end

  local hero = unit
  --if not hero then
    --hero = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(unit))
  --end

  if not unit:HasModifier("modifier_core_points_counter_oaa") then
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if not hero then
    print("CorePointsManager (GetCorePointsOnHero): Couldnt find a hero.")
    return 0
  end

  --return self.playerID_table[UnitVarToPlayerID(hero)]

  local counter = hero:FindModifierByName("modifier_core_points_counter_oaa")
  if not counter then
    print("CorePointsManager (GetCorePointsOnHero): Couldnt find a counter buff.")
    return 0
  end

  return counter:GetStackCount()
end

function CorePointsManager:SetCorePointsOnHero(number, unit, playerID)
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do SetCorePointsOnHero for this unit and playerID")
    return
  end

  local hero = unit
  --if not hero then
    --hero = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(unit))
  --end

  if not unit:HasModifier("modifier_core_points_counter_oaa") then
    hero = PlayerResource:GetSelectedHeroEntity(playerID)
  end

  if not hero then
    print("CorePointsManager (SetCorePointsOnHero): Couldnt find a hero.")
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
  return false
end

function modifier_core_points_counter_oaa:IsPurgable()
  return false
end

function modifier_core_points_counter_oaa:RemoveOnDeath()
  return false
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
