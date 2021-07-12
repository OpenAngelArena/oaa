CorePointsManager = Components:Register('CorePointsManager', COMPONENT_STRATEGY)

function CorePointsManager:Init()
  if self.initialized then
    print("CorePointsManager is already initialized and there was an attempt to initialize it again -> preventing")
    return nil
  end
  LinkLuaModifier("modifier_core_points_counter_oaa", "components/points/core_points.lua", LUA_MODIFIER_MOTION_NONE)
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(self, "FilterOrders"))
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
    if unit_with_order and ability then
      -- Check if ability is an item
      if ability:IsItem() then
        -- if ability:IsRecipe() then
        local core_points_cost = self:GetCorePointsFullValue(ability)
        local purchaser_core_points = self:GetCorePointsOnHero(unit_with_order, playerID)
        if purchaser_core_points >= core_points_cost and core_points_cost ~= 0 then
          self:AddCorePoints(-core_points_cost, unit_with_order, playerID)
          self:GiveUpgradeCoreToHero(core_points_cost, unit_with_order, playerID)
        else
          --CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "display_custom_error", { message = "#hud_error_not_enough_core_points" })
          --CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason = 70, message = ""})
          return false
        end
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

  if not hero:HasModifier("modifier_core_points_counter_oaa") then
    hero:AddNewModifier(hero, nil, "modifier_core_points_counter_oaa", {})
  end

  if self.playerID_table[UnitVarToPlayerID(hero)] == nil then
    self.playerID_table[UnitVarToPlayerID(hero)] = 0
  end
end

function CorePointsManager:GetCorePointValueOfUpdgradeCore(item_name)
  if item_name == "item_upgrade_core" then
    return 2
  elseif item_name == "item_upgrade_core_2" then
    return 4
  elseif item_name == "item_upgrade_core_3" then
    return 8
  elseif item_name == "item_upgrade_core_4" then
    return 16
  else
    return 0
  end
end

function CorePointsManager:GetCorePointsFullValue(item)
  local value = 0
  if not item then
    print("CorePointsManager (GetCorePointsFullValue): item doesn't exist.")
    return value
  end

  local item_name = item:GetName()
  if not item:IsRecipe() then
    item_name = string.gsub(item_name, "item_", "item_recipe_")
    --value = tonumber(item:GetAbilityKeyValues()["CorePointCost"])
  end

  local item_data = GetAbilityKeyValuesByName(item_name)
  if not item_data then
    print("CorePointsManager (GetCorePointsFullValue): item data doesn't exist.")
    return value
  end
  local item_req = item_data["ItemRequirements"]

  print(item_name)
  print(item_req)
  print("===================")
  for k, v in pairs(item_req) do
    print(k, v)
  end
  print(item_req["01"])
  print("===================")
  local req_string = item_req["01"]
  --local b = string.sub(a, #a-7)
  local c = string.find(req_string, "upgrade_core", -15)
  local d = string.find(req_string, "upgrade_core_2", -15)
  local e = string.find(req_string, "upgrade_core_3", -15)
  local f = string.find(req_string, "upgrade_core_4", -15)
  if c then
    if d then
      value = self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_2")
    elseif e then
      value = self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_3")
    elseif f then
      value = self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_4")
    else
      value = self:GetCorePointValueOfUpdgradeCore("item_upgrade_core")
    end
  end

  return value
end

function CorePointsManager:GetCorePointsSellValue(item)
  return math.floor(self:GetCorePointsFullValue(item) / 2)
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
end

function CorePointsManager:AddCorePoints(amount, unit, playerID)
  local core_points = self:GetCorePointsOnHero(unit, playerID)
  self:SetCorePointsOnHero(core_points + amount, unit, playerID)
end

function CorePointsManager:GiveUpgradeCoreToHero(number, unit, playerID)
  if not unit or not playerID then
    print("CorePointsManager: Couldnt do GiveUpgradeCoreToHero for this unit and playerID")
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
    print("CorePointsManager (GiveUpgradeCoreToHero): Couldnt find a hero.")
    return
  end

  local item_name = ""
  if number == self:GetCorePointValueOfUpdgradeCore("item_upgrade_core") then
    item_name = "item_upgrade_core"
  elseif number == self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_2") then
    item_name = "item_upgrade_core_2"
  elseif number == self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_3") then
    item_name = "item_upgrade_core_3"
  elseif number == self:GetCorePointValueOfUpdgradeCore("item_upgrade_core_4") then
    item_name = "item_upgrade_core_4"
  else
    print("CorePointsManager (GiveUpgradeCoreToHero): Special case - item has multiple cores in recipe.")
    -- special cases
    return
  end

  if item_name ~= "" then
    hero:AddItemByName(item_name)
  end
end

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
