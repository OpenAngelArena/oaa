ARDMMode = ARDMMode or class({})

function ARDMMode:Init ()
  -- ARDM modifiers
  LinkLuaModifier("modifier_ardm", "modifiers/ardm/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_ardm_disable_hero", "modifiers/ardm/modifier_ardm_disable_hero.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_legion_commander_duel_damage_oaa_ardm", "modifiers/ardm/modifier_legion_commander_duel_damage_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_silencer_int_steal_oaa_ardm", "modifiers/ardm/modifier_silencer_int_steal_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_pudge_flesh_heap_oaa_ardm", "modifiers/ardm/modifier_pudge_flesh_heap_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_slark_essence_shift_oaa_ardm", "modifiers/ardm/modifier_slark_essence_shift_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_axe_armor_oaa_ardm", "modifiers/ardm/modifier_axe_armor_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_necrophos_regen_oaa_ardm", "modifiers/ardm/modifier_necrophos_regen_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_moonshard_consumed_oaa_ardm", "modifiers/ardm/modifier_moonshard_consumed_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)

  self.playedHeroes = {}
  self.precachedHeroes = {
    "npc_dota_hero_sohei",
    "npc_dota_hero_electrician",
    "npc_dota_hero_bloodseeker",
  }

  -- Define the hero pool
  self.allHeroes = {}
  local herolistFile = 'scripts/npc/herolist_ardm.txt'
  local herolistTable = LoadKeyValues(herolistFile)
  for key, value in pairs(herolistTable) do
    if value == 1 then
      table.insert(self.allHeroes, key)
    end
  end

  --self.hasPrecached = false
  self.addedmodifier = {}
  self.heroPool = {
    [DOTA_TEAM_GOODGUYS] = {},
    [DOTA_TEAM_BADGUYS] = {}
  }

  -- Register event listeners
  GameEvents:OnHeroInGame(partial(self.ApplyARDMmodifier, self))
  GameEvents:OnHeroKilled(partial(self.PrepareHeroChange, self))
  --GameEvents:OnGameInProgress(partial(self.PrintTables, self))

  self:LoadHeroPoolsForTeams()

  GameRules:SetShowcaseTime(0)
  GameRules:SetStrategyTime(30)
end

-- Start precaching with callback and broadcast when finished
--[[

local PrecacheHeroEvent = Event()

function ARDMMode:StartPrecache()
  --Debug:EnableDebugging()
  if not self.alreadyStartedARDMPrecache and not self.hasPrecached then
    self.alreadyStartedARDMPrecache = true
    self:PrecacheHeroes(function ()
      DebugPrint("ARDMMode - Done precaching")
      GameRules:SendCustomMessage("FINISHED with hero precaching...", 0, 0)
      PauseGame(false)
      ARDMMode.hasPrecached = true
      PrecacheHeroEvent.broadcast(true)
    end)
  else
    DebugPrint("ARDMMode - There was an attempt to start ARDM precache when it already started or it was finished")
  end
end
]]

-- Precache only heroes that need to be precached (ignore starting heroes and already precached heroes)
--[[
function ARDMMode:PrecacheHeroes(cb)
  --Debug:EnableDebugging()
  GameRules:SendCustomMessage("Started precaching heroes. PLEASE BE PATIENT.", 0, 0)
  DebugPrint("PrecacheHeroes - Started precaching heroes")

  local hero_count = #self.allHeroes

  local function check_if_done()
    hero_count = hero_count - 1
    if hero_count <= 0 then
      cb()
    end
  end

  for _, hero_name in pairs(self.allHeroes) do
    local precached = false
    for _, v in pairs(self.precachedHeroes) do
      if v and hero_name == v then
        DebugPrint("PrecacheHeroes - Hero "..tostring(v).." was already precached")
        precached = true
        break
      end
    end
    if not precached and hero_name then
      PrecacheUnitByNameAsync(hero_name, function()
        DebugPrint("PrecacheHeroes - Finished precaching hero: "..tostring(hero_name))
        --GameRules:SendCustomMessage("Precached "..tostring(hero_name), 0, 0)
        table.insert(ARDMMode.precachedHeroes, hero_name)
        check_if_done()
      end)
    else
      check_if_done()
    end
  end
end
]]

-- Precache all heroes
--[[
function ARDMMode:PrecacheAllHeroes(cb)
  Debug:EnableDebugging()
  local heroCount = #self.allHeroes
  local done = after(heroCount, cb)
  DebugPrint('Starting precache process...')
  for _, hero in pairs(self.allHeroes) do
    if hero then
      PrecacheUnitByNameAsync(hero, function ()
        DebugPrint('precached this hero: ' .. hero)
        done()
      end)
    end
  end
end
]]

-- Prints all used tables of ARDMMode
--[[
function ARDMMode:PrintTables()
  --Debug:EnableDebugging()
  DebugPrint("PrintTables - Played heroes: ")
  DebugPrintTable(self.playedHeroes)
  DebugPrint("PrintTables - Precached heroes: ")
  DebugPrintTable(self.precachedHeroes)
  --DebugPrint("PrintTables - All heroes: ")
  --DebugPrintTable(self.allHeroes)
  DebugPrint("PrintTables - Radiant hero pool: ")
  DebugPrintTable(self.heroPool[DOTA_TEAM_GOODGUYS])
  DebugPrint("PrintTables - Dire hero pool: ")
  DebugPrintTable(self.heroPool[DOTA_TEAM_BADGUYS])
end
]]

function ARDMMode:ApplyARDMmodifier(hero)
  --Debug:EnableDebugging()
  local hero_team = hero:GetTeamNumber()
  local hero_name = hero:GetUnitName()

  Timers:CreateTimer(1, function()
    if hero_team == DOTA_TEAM_NEUTRALS then
      return
    end

    if hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
      return
    end

    local playerID = hero:GetPlayerOwnerID()
    if ARDMMode.addedmodifier[playerID] then
      --DebugPrint("ApplyARDMmodifier - Already added modifier_ardm for player "..tostring(playerID))
      ARDMMode:PrepareNextHero(hero, hero_team)
      return
    end

    if not hero:HasModifier("modifier_ardm") then
      hero:AddNewModifier(hero, nil, "modifier_ardm", {})
    end

    -- Mark the first spawned hero as played - needed because of some edge cases
    --DebugPrint("ApplyARDMmodifier - Adding starting hero "..hero_name.." to the list of played heroes. this_should_happen_only_once")
    table.insert(ARDMMode.playedHeroes, hero_name)

    -- Mark the first spawned hero as precached - needed because of some edge cases
    --DebugPrint("ApplyARDMmodifier - Adding starting hero "..hero_name.." to the list of precached heroes. this_should_happen_only_once")
    table.insert(ARDMMode.precachedHeroes, hero_name)

    ARDMMode.addedmodifier[playerID] = true

    ARDMMode:PrepareNextHero(hero, hero_team)
  end)
end

function ARDMMode:PrepareNextHero(current, team)
  local new = ARDMMode:GetRandomHero(team)

  -- Check if we are out of heroes
  if not new then
    -- Reload hero pools
    ARDMMode:LoadHeroPoolsForTeams()
    ARDMMode.playedHeroes = {}
    -- Find recently played heroes and insert them into playedHeroes table
    table.insert(ARDMMode.playedHeroes, current:GetUnitName())
    local heroes = FindUnitsInRadius(
      team,
      Vector(0, 0, 0),
      nil,
      FIND_UNITS_EVERYWHERE,
      DOTA_UNIT_TARGET_TEAM_BOTH,
      DOTA_UNIT_TARGET_HERO,
      bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, DOTA_UNIT_TARGET_FLAG_DEAD),
      FIND_ANY_ORDER,
      false
    )
    for _, v in pairs(heroes) do
      if v then
        table.insert(ARDMMode.playedHeroes, v:GetUnitName())
      end
    end

    new = ARDMMode:GetRandomHero(team)
    if not new then
      ARDMMode:AssignNewHero(current, nil)
      return
    end
  end

  -- Check if precached already
  local precached = false
  for _, v in pairs(ARDMMode.precachedHeroes) do
    if v and v == new then
      precached = true
      break
    end
  end

  ARDMMode:AssignNewHero(current, nil)
  DebugPrint("PrepareNextHero - "..current:GetUnitName().." will be changed into "..tostring(new))
  if not precached then
    -- Precache the next one
    PrecacheUnitByNameAsync(new, function()
      table.insert(ARDMMode.precachedHeroes, new)
      ARDMMode:AssignNewHero(current, new)
    end)
  else
    ARDMMode:AssignNewHero(current, new)
  end
end

function ARDMMode:AssignNewHero(old, new_name)
  local ardm_mod = old:FindModifierByName("modifier_ardm")
  if ardm_mod then
    ardm_mod.hero = new_name
  end
end

function ARDMMode:AllowReplacing(hero, state)
  local ardm_mod = hero:FindModifierByName("modifier_ardm")
  if ardm_mod then
    ardm_mod.allowed = state
  end
end

function ARDMMode:PrepareHeroChange(event)
  --Debug:EnableDebugging()
  if not event.killed then
    return
  end

  local killed_hero = event.killed
  local killed_hero_name = killed_hero:GetUnitName()
  local killed_team = killed_hero:GetTeamNumber()
  local playerID = killed_hero:GetPlayerOwnerID()

  if killed_team == DOTA_TEAM_NEUTRALS then
    return
  end

  if killed_hero:IsClone() then
    killed_hero = killed_hero:GetCloneSource()
  end

  if killed_hero:IsReincarnating() or killed_hero:IsTempestDouble() or killed_hero:IsSpiritBearOAA() then
    ARDMMode:AllowReplacing(killed_hero, false) -- prevent hero change when reincarnating
    return
  end

  if not killed_hero:HasModifier("modifier_ardm") and not ARDMMode.addedmodifier[playerID] then
    DebugPrint("PrepareHeroChange - Killed hero "..killed_hero_name.." doesnt have ARDM modifier for some reason.")
    return
  end

  -- Mark the killed hero as played
  --DebugPrint("PrepareHeroChange - Adding killed hero "..killed_hero_name.." to the list of played heroes. this_should_happen_for_every_hero_death")
  table.insert(ARDMMode.playedHeroes, killed_hero_name)

  -- Remove the killed hero from the pool
  --DebugPrint("PrepareHeroChange - Removing killed hero "..killed_hero_name.." from the list of valid heroes for team "..tostring(killed_team)..". this_should_happen_for_every_hero_death")
  ARDMMode:RemoveHeroFromThePool(killed_hero_name, killed_team)

  ARDMMode:AllowReplacing(killed_hero, true)
  --ARDMMode:RemoveHeroFromThePool(new_hero_name, killed_team) -- to prevent same heroes on 1 team, commented out because heroes can die at the same time
end

function ARDMMode:LoadHeroPoolsForTeams()
  local number_of_heroes = #self.allHeroes
  -- Copy the table
  local other_team_heroes = {}
  for k, v in pairs(self.allHeroes) do
    other_team_heroes[k] = self.allHeroes[k]
  end

  -- Form the hero pool for the Radiant team
  local i = 0
  while i < math.floor(number_of_heroes/2) do
    local random_number = RandomInt(1, number_of_heroes)
    local hero_name = self.allHeroes[random_number]
    if hero_name then
      -- Check if already in the table
      local already = false
      for _, v in pairs(self.heroPool[DOTA_TEAM_GOODGUYS]) do
        if v == hero_name then
          already = true
          break -- break for loop
        end
      end

      if not already then
        table.insert(self.heroPool[DOTA_TEAM_GOODGUYS], hero_name)
        other_team_heroes[random_number] = nil
        i = i + 1
      end
    end
  end

  -- Form the hero pool for the Dire team
  for _, hero_name in pairs(other_team_heroes) do
    if hero_name ~= nil then
      table.insert(self.heroPool[DOTA_TEAM_BADGUYS], hero_name)
    end
  end
end

-- Listener function that can be used in other modules
--[[
function ARDMMode:OnPrecache (cb)
  if self.hasPrecached then
    cb()
    -- no unlisten event to return, send noop
    return noop
  end

  return PrecacheHeroEvent.listen(cb)
end

function noop ()
end
]]

function ARDMMode:GetRandomHero (teamId)
  --Debug:EnableDebugging()
  local heroPool = {}

  -- Store non-nil table elements into local heroPool table
  for _, v in pairs(self.heroPool[teamId]) do
    if v ~= nil then
      table.insert(heroPool, v)
    end
  end

  -- Check if heroPool has elements (I am not sure anymore if '#' counts nil elements or not but I am sure it counts non-nil elements and this table is full of them)
  if #heroPool < 1 then
    -- This will also happen if herolist file is empty
    DebugPrint("GetRandomHero - Hero Pool for "..tostring(teamId).." is empty. No new hero.")
    return nil
  end

  local random_number = RandomInt(1, #heroPool)
  local hero_name = heroPool[random_number]

  -- Check if this hero name is valid, do all the above again if not
  if not hero_name or hero_name == "" then
    -- hero_name should never be nil
    return self:GetRandomHero(teamId)
  end

  -- Check if this hero was played before
  local played = false
  for _, v in pairs(self.playedHeroes) do
    if v and v == hero_name then
      played = true
      break -- break for loop
    end
  end

  if played then
    -- Remove the hero from the pool because it was played
    DebugPrint("GetRandomHero - Hero "..tostring(hero_name).." was already played. Removing from the hero pool.")
    self:RemoveHeroFromThePool(hero_name, teamId)

    -- Do all the above again
    return self:GetRandomHero(teamId)
  end

  -- Check if this hero was precached only if the game started
  --[[
  if GameRules:State_Get() > DOTA_GAMERULES_STATE_TEAM_SHOWCASE then
    local precached = false
    for _, v in pairs(self.precachedHeroes) do
      if v and v == hero_name then
        precached = true
        break
      end
    end

    if not precached then
      -- Remove the hero from the pool because it was not precached
      DebugPrint("GetRandomHero - Hero "..tostring(hero_name).." was not precached. Removing from the hero pool.")
      self:RemoveHeroFromThePool(hero_name, teamId)

      -- Do all the above again
      return self:GetRandomHero(teamId)
    end
  end
  ]]

  return hero_name
end

function ARDMMode:RemoveHeroFromThePool(hero_name, teamId)
  for k, v in pairs(self.heroPool[teamId]) do
    if v ~= nil and v == hero_name then
      self.heroPool[teamId][k] = nil
    end
  end
end

function ARDMMode:ReplaceHero(old_hero, new_hero_name)
  --Debug:EnableDebugging()
  if not new_hero_name or not old_hero then
    if old_hero then
      DebugPrint("ReplaceHero - Old hero is "..tostring(old_hero:GetUnitName()))
    else
      DebugPrint("ReplaceHero - Old hero is nil")
    end
    DebugPrint("ReplaceHero - New hero is "..tostring(new_hero_name))
    DebugPrint("ReplaceHero - Changing hero aborted.")
    return
  end

  local playerID = old_hero:GetPlayerID()

  --[[ -- needed only if ReplaceHeroWith was used
  local old_hero_gold = 0
  if Gold then
    old_hero_gold = Gold:GetGold(playerID)
  else
    old_hero_gold = PlayerResource:GetGold(playerID)
  end
  ]]

  local old_hero_xp = old_hero:GetCurrentXP() -- PlayerResource:GetTotalEarnedXP(playerID)
  local hero_lvl = old_hero:GetLevel()

  -- Calculate spent ability/skill points - not needed
  --local spent_ability_points = 0
  --for ability_index = 0, old_hero:GetAbilityCount() - 1 do
    --local ability = old_hero:GetAbilityByIndex(ability_index)
    --if ability then
      --spent_ability_points = spent_ability_points + ability:GetLevel()
    --end
  --end

  local items = {}
  -- Normal slots and backpack slots
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = old_hero:GetItemInSlot(i)
    local item_name
    local charges
    local purchaser
    local cooldown
    if item then
      if not item:IsNeutralDrop() then
        item_name = item:GetName()
        purchaser = item:GetPurchaser()
        if purchaser == old_hero then
          purchaser = nil
        end
        cooldown = item:GetCooldownTimeRemaining()
        if item:RequiresCharges() then
          charges = item:GetCurrentCharges()
        end
      end
    end
    items[i] = {item_name, purchaser, cooldown, charges}
  end

  -- Stash slots
  for i = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = old_hero:GetItemInSlot(i)
    local item_name
    local charges
    local purchaser
    local cooldown
    if item then
      if not item:IsNeutralDrop() then
        item_name = item:GetName()
        purchaser = item:GetPurchaser()
        if purchaser == old_hero then
          purchaser = nil
        end
        cooldown = item:GetCooldownTimeRemaining()
        if item:RequiresCharges() then
          charges = item:GetCurrentCharges()
        end
      end
    end
    items[i] = {item_name, purchaser, cooldown, charges}
  end

  -- Neutral items and TP scroll (check every slot)
  for i = DOTA_ITEM_SLOT_1, 20 do
    local item = old_hero:GetItemInSlot(i)
    if item then
      if item:IsNeutralDrop() then
        -- Return found neutral item to neutral stash (order), this is better than recreating another neutral item
        local order_table = {
          UnitIndex = old_hero:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN,
          AbilityIndex = item:GetEntityIndex(),
          Queue = false,
        }
        ExecuteOrderFromTable(order_table)
        --PlayerResource:AddNeutralItemToStash(playerID, old_hero:GetTeamNumber(), item) -- crashes
      elseif item:GetName() == "item_tpscroll" and i == DOTA_ITEM_TP_SCROLL then
        items[DOTA_ITEM_TP_SCROLL] = {"item_tpscroll", nil, item:GetCooldownTimeRemaining(), nil}
      end
    end
  end

  -- Permanent modifiers
  local duel_damage = 0
  local stolen_int = 0
  local flesh_heap = 0
  local essence_shift = 0
  local axe_armor_stacks = 0
  local necro_regen_stacks = 0
  local aghanim_scepter
  local aghanim_shard
  local moon_shard

  if old_hero:HasModifier("modifier_legion_commander_duel_damage_boost") then
    duel_damage = duel_damage + old_hero:FindModifierByName("modifier_legion_commander_duel_damage_boost"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_legion_commander_duel_damage_oaa_ardm") then
    duel_damage = duel_damage + old_hero:FindModifierByName("modifier_legion_commander_duel_damage_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_oaa_int_steal") then
    stolen_int = stolen_int + old_hero:FindModifierByName("modifier_oaa_int_steal"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_silencer_int_steal_oaa_ardm") then
    stolen_int = stolen_int + old_hero:FindModifierByName("modifier_silencer_int_steal_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_pudge_flesh_heap") then
    flesh_heap = flesh_heap + old_hero:FindModifierByName("modifier_pudge_flesh_heap"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_pudge_flesh_heap_oaa_ardm") then
    flesh_heap = flesh_heap + old_hero:FindModifierByName("modifier_pudge_flesh_heap_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_slark_essence_shift_permanent_buff") then
    essence_shift = essence_shift + old_hero:FindModifierByName("modifier_slark_essence_shift_permanent_buff"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_slark_essence_shift_oaa_ardm") then
    essence_shift = essence_shift + old_hero:FindModifierByName("modifier_slark_essence_shift_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_axe_culling_blade_permanent") then
    axe_armor_stacks = axe_armor_stacks + old_hero:FindModifierByName("modifier_axe_culling_blade_permanent"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_axe_armor_oaa_ardm") then
    axe_armor_stacks = axe_armor_stacks + old_hero:FindModifierByName("modifier_axe_armor_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_necrolyte_reapers_scythe_respawn_time") then
    necro_regen_stacks = necro_regen_stacks + old_hero:FindModifierByName("modifier_necrolyte_reapers_scythe_respawn_time"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_necrophos_regen_oaa_ardm") then
    necro_regen_stacks = necro_regen_stacks + old_hero:FindModifierByName("modifier_necrophos_regen_oaa_ardm"):GetStackCount()
  end
  if old_hero:HasModifier("modifier_item_ultimate_scepter_consumed") or old_hero:HasModifier("modifier_item_ultimate_scepter_consumed_alchemist") then
    aghanim_scepter = true
  end
  if old_hero:HasShardOAA() then
    aghanim_shard = true
  end
  if old_hero:HasModifier("modifier_item_moon_shard_consumed") or old_hero:HasModifier("modifier_moonshard_consumed_oaa_ardm") then
    moon_shard = true
  end

  -- Find which spark hero has
  local spark
  if old_hero:HasModifier("modifier_spark_cleave") then
    spark = "modifier_spark_cleave"
  end
  if old_hero:HasModifier("modifier_spark_midas") then
    spark = "modifier_spark_midas"
  end
  if old_hero:HasModifier("modifier_spark_power") then
    spark = "modifier_spark_power"
  end

  -- Disable, hide and remove the old hero
  local old_loc = old_hero:GetAbsOrigin()
  local hidden_loc = Vector(-10000, -10000, 0)
  DebugPrint("ReplaceHero - Disabling the old hero")
  old_hero:AddNewModifier(old_hero, nil, "modifier_ardm_disable_hero", {}) -- Disabling
  DebugPrint("ReplaceHero - Hiding the old hero")
  old_hero:AddNoDraw() -- Hiding
  old_hero:SetAbsOrigin(hidden_loc) -- Hiding

  -- Remove modifiers that could create a mess
  old_hero:RemoveModifierByName("modifier_ardm")
  old_hero:RemoveModifierByName("modifier_spark_gpm")
  old_hero:RemoveModifierByName("modifier_oaa_passive_gpm")
  old_hero:RemoveModifierByName("modifier_spark_midas")

  -- Preventing dropping and selling items in inventory
  --old_hero:SetHasInventory(false)
  old_hero:SetCanSellItems(false)

  local player = PlayerResource:GetPlayer(playerID)

  --PlayerResource:ReplaceHeroWith(playerID, new_hero_name, old_hero_gold, 0)
  local new_hero = CreateUnitByName(new_hero_name, old_loc, true, old_hero, player, old_hero:GetTeamNumber()) -- this can crash the game.
  -- without player there are no cosmetics
  new_hero:SetPlayerID(playerID)
  new_hero:SetControllableByPlayer(playerID, true)
  if old_hero:GetPlayerOwner() and not new_hero:GetOwner() then
    new_hero:SetOwner(old_hero:GetPlayerOwner())
  else
    new_hero:SetOwner(old_hero:GetOwner())
  end

  -- Place the new hero at old hero location
  FindClearSpaceForUnit(new_hero, old_loc, false)

  if player then
    if player:GetAssignedHero() ~= new_hero then
      DebugPrint("ReplaceHero - Reassigning the new hero")
      player:SetAssignedHeroEntity(new_hero)
    end
  end

  Timers:CreateTimer(2*FrameTime(), function()
    if not player then
      player = PlayerResource:GetPlayer(playerID)
    end
    if player then
      if player:GetAssignedHero() ~= new_hero then
        DebugPrint("ReplaceHero - Reassigning the new hero again")
        player:SetAssignedHeroEntity(new_hero)
      end
    end

    DebugPrint("ReplaceHero - Selecting the new hero")
    PlayerResource:SetOverrideSelectionEntity(playerID, new_hero)

    -- Level Up the new hero
    for i = 1, hero_lvl - 1 do
      new_hero:HeroLevelUp(false) -- false because we don't want to see level up effects
    end

    -- Adjust experience
    local current_xp = new_hero:GetCurrentXP()
    new_hero:AddExperience(math.abs(old_hero_xp - current_xp), DOTA_ModifyXP_Unspecified, false, true)

    -- Adjust ability points - not needed
    --new_hero:SetAbilityPoints(spent_ability_points)

    -- Remove any item that is given to the new hero for no reason
    --[[
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = new_hero:GetItemInSlot(i)
      if item then
        new_hero:RemoveItem(item)
      end
    end
    ]]

    -- Prevent TP scroll starting on cooldown
    local tp_scroll = new_hero:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
    if tp_scroll then
      if tp_scroll:GetName() == "item_tpscroll" then
        tp_scroll:EndCooldown()
        if items[DOTA_ITEM_TP_SCROLL] then
          tp_scroll:StartCooldown(items[DOTA_ITEM_TP_SCROLL][3] or 1)
        end
      end
    end

    -- Scepter and shard modifiers
    if aghanim_scepter then
      --local scepter = CreateItem("item_ultimate_scepter_2", new_hero, new_hero)
      --new_hero:AddItem(scepter)
      new_hero:AddNewModifier(new_hero, nil, "modifier_item_ultimate_scepter_consumed", {})
    end
    if aghanim_shard then
      --local shard = CreateItem("item_aghanims_shard", new_hero, new_hero)
      --new_hero:AddItem(shard)
      new_hero:AddNewModifier(new_hero, nil, "modifier_item_aghanims_shard", {})
    end
    if moon_shard then
      new_hero:AddNewModifier(new_hero, nil, "modifier_moonshard_consumed_oaa_ardm", {})
    end

    -- Create new permanent modifiers for the new hero
    if duel_damage ~= 0 then
      if not new_hero:HasModifier("modifier_legion_commander_duel_damage_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_legion_commander_duel_damage_oaa_ardm", {})
        mod:SetStackCount(duel_damage)
      end
    end

    if stolen_int ~= 0 then
      if not new_hero:HasModifier("modifier_silencer_int_steal_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_silencer_int_steal_oaa_ardm", {})
        mod:SetStackCount(stolen_int)
      end
    end

    if flesh_heap ~= 0 then
      if not new_hero:HasModifier("modifier_pudge_flesh_heap_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_pudge_flesh_heap_oaa_ardm", {})
        mod:SetStackCount(flesh_heap)
      end
    end

    if essence_shift ~= 0 then
      if not new_hero:HasModifier("modifier_slark_essence_shift_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_slark_essence_shift_oaa_ardm", {})
        mod:SetStackCount(essence_shift)
      end
    end

    if axe_armor_stacks ~= 0 then
      if not new_hero:HasModifier("modifier_axe_armor_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_axe_armor_oaa_ardm", {})
        mod:SetStackCount(axe_armor_stacks)
      end
    end

    if necro_regen_stacks ~= 0 then
      if not new_hero:HasModifier("modifier_necrophos_regen_oaa_ardm") then
        local mod = new_hero:AddNewModifier(new_hero, nil, "modifier_necrophos_regen_oaa_ardm", {})
        mod:SetStackCount(necro_regen_stacks)
      end
    end

    -- Other hidden permanent modifiers
    if not new_hero:HasModifier("modifier_spark_gpm") then
      new_hero:AddNewModifier(new_hero, nil, "modifier_spark_gpm", {})
    end
    if spark then
      if not new_hero:HasModifier(spark) then
        new_hero:AddNewModifier(new_hero, nil, spark, {})
      end
    end
    -- Adding modifier_oaa_passive_gpm is probably not needed because Gold.hasPassiveGPM table adds an element for every new hero spawn

    -- Add ARDM modifier to the new hero
    if not new_hero:HasModifier("modifier_ardm") then
      new_hero:AddNewModifier(new_hero, nil, "modifier_ardm", {})
    end

    -- Create new items for the new hero
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = items[i]
      local item_name = item[1]
      local purchaser = item[2]
      local cooldown = item[3]
      local charges = item[4]
      if item_name then
        local new_item = CreateItem(item_name, new_hero, new_hero)
        new_hero:AddItem(new_item)
        if new_item and not new_item:IsNull() then
          --new_item:SetStacksWithOtherOwners(true)
          -- Set purchaser
          if purchaser then
            new_item:SetPurchaser(purchaser)
          else
            new_item:SetPurchaser(new_hero)
          end
          -- Set charges
          if charges then
            new_item:SetCurrentCharges(charges)
          end
          -- Set cooldowns
          if cooldown and cooldown > 0 then
            new_item:StartCooldown(cooldown)
          end
        end
      end
    end

    for i = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
      local item = items[i]
      local item_name = item[1]
      local purchaser = item[2]
      local cooldown = item[3]
      local charges = item[4]
      if item_name then
        local new_item = CreateItem(item_name, new_hero, new_hero)
        new_hero:AddItem(new_item)
        if new_item and not new_item:IsNull() then
          -- Set purchaser
          if purchaser then
            new_item:SetPurchaser(purchaser)
          else
            new_item:SetPurchaser(new_hero)
          end
          -- Set charges
          if charges then
            new_item:SetCurrentCharges(charges)
          end
          -- Set cooldowns
          if cooldown and cooldown > 0 then
            new_item:StartCooldown(cooldown)
          end
        end
      end
    end

    PlayerResource:SetOverrideSelectionEntity(playerID, nil)
  end)
end

function ARDMMode:RemoveOldHero(hero)
  if hero and not hero:IsNull() then
    DebugPrint("Old hero still exists. Removing "..hero:GetUnitName())
    hero:MakeIllusion() -- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
    hero:ForceKillOAA(false)
    --UTIL_Remove(hero) -- causes Client crashes
  end
end
