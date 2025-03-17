-- Component for various chat commands useful for testing
-- Majority of original command code by Darklord

DevCheats = DevCheats or class({})

function DevCheats:Init()
  self.moduleName = "DevCheats"
  ChatCommand:LinkDevCommand("-help", Dynamic_Wrap(DevCheats, "Help"), self)
  ChatCommand:LinkDevCommand("-list", Dynamic_Wrap(DevCheats, "Help"), self)
  ChatCommand:LinkDevCommand("-print_modifiers", Dynamic_Wrap(DevCheats, "PrintModifiers"), self)
  ChatCommand:LinkDevCommand("-print_abilities", Dynamic_Wrap(DevCheats, "PrintAbilities"), self)
  ChatCommand:LinkDevCommand("-addbots", Dynamic_Wrap(DevCheats, "AddBots"), self)
  ChatCommand:LinkDevCommand("-nofog", Dynamic_Wrap(DevCheats, "DisableFog"), self)
  ChatCommand:LinkDevCommand("-fog", Dynamic_Wrap(DevCheats, "EnableFog"), self)
  ChatCommand:LinkDevCommand("-fixspawn", Dynamic_Wrap(DevCheats, "TeleportHeroesToFountain"), self)
  ChatCommand:LinkDevCommand("-getpos", Dynamic_Wrap(DevCheats, "PrintPosition"), self)
  ChatCommand:LinkDevCommand("-god", Dynamic_Wrap(DevCheats, "GodMode"), self)
  ChatCommand:LinkDevCommand("-disarm", Dynamic_Wrap(DevCheats, "ToggleDisarm"), self)
  ChatCommand:LinkDevCommand("-dagger", Dynamic_Wrap(DevCheats, "GiveDevDagger"), self)
  ChatCommand:LinkDevCommand("-blink", Dynamic_Wrap(DevCheats, "GiveDevDagger"), self)
  ChatCommand:LinkDevCommand("-core", Dynamic_Wrap(DevCheats, "GiveUpgradeCore"), self)
  ChatCommand:LinkDevCommand("-addability", Dynamic_Wrap(DevCheats, "AddAbility"), self)
  ChatCommand:LinkDevCommand("-give", Dynamic_Wrap(DevCheats, "GiveLevelledItem"), self)
  ChatCommand:LinkDevCommand("-loadout", Dynamic_Wrap(DevCheats, "GiveLoadout"), self)
  ChatCommand:LinkDevCommand("-scepter", Dynamic_Wrap(DevCheats, "GiveUltimateScepter"), self)
  ChatCommand:LinkDevCommand("-shard", Dynamic_Wrap(DevCheats, "GiveAghanimShard"), self)
  ChatCommand:LinkDevCommand("-dagon", Dynamic_Wrap(DevCheats, "GiveDevDagon"), self)
  ChatCommand:LinkDevCommand("-switchhero", Dynamic_Wrap(DevCheats, "SwitchHero"), self)
  ChatCommand:LinkDevCommand("-kill_all", Dynamic_Wrap(DevCheats, "KillEverything"), self)
  --ChatCommand:LinkDevCommand("-lvlup", Dynamic_Wrap(DevCheats, "LevelUp"), self)
  ChatCommand:LinkCommand("-entity_count", Dynamic_Wrap(DevCheats, "CountAllEntities"), self)
  ChatCommand:LinkCommand("-memory", Dynamic_Wrap(DevCheats, "MemoryUsage"), self)
end

-- Print all modifiers on player's hero to console
-- TODO: Allow printing modifiers on selected units if possible
function DevCheats:PrintModifiers(keys)
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local modifiers = hero:FindAllModifiers()

  local function PrintModifier(modifier)
    print(modifier:GetName())
  end

  foreach(PrintModifier, modifiers)
end

function DevCheats:PrintAbilities(keys)
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)

  for a = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(a)
    if ability and not ability:IsNull() then
      print(tostring(a) .. ': ' .. ability:GetAbilityName())
    else
      print(tostring(a) .. ': empty')
    end
  end
end

-- Print list of available commands to chat
function DevCheats:Help(keys)
  GameRules:SendCustomMessage("-nofog, -fog, -god, -disarm, -dagger, -dagon, -duel, -end_duel, -kill_all", 0, 0)
  GameRules:SendCustomMessage("-addability x, -give x y, -switchhero x, -loadout x, -scepter, -shard", 0, 0)
  GameRules:SendCustomMessage("-corepoints x, -core 1-4, -addpoints, -add_enemy_points, -kill_limit x, -print_modifiers, -getpos", 0, 0)
  GameRules:SendCustomMessage("-spawncamps, -spawnbosses, -spawngrendel, -spawnwanderer, -capture, -end_capture", 0, 0)
  GameRules:SendCustomMessage("-test_state, -test_tp, -fixspawn, -addbots, -state, -enable_lock_in, -enable_lock_out", 0, 0)
  GameRules:SendCustomMessage("-entity_count, -memory, -print_abilities", 0, 0)
end

-- Populate game with bots
function DevCheats:AddBots(keys)
  local numPlayers = PlayerResource:GetPlayerCount()

  --PlayerResource:RandomHeroForPlayersWithoutHero()

  -- Eanble bots and fill empty slots
  if IsServer() and GameRules:GetMaxTeamPlayers() - numPlayers > 0 then
    -- Set bot difficulty
    SendToServerConsole("dota_bot_set_difficulty 4")
    SendToServerConsole("dota_bot_practice_difficulty 4")
    -- Fill all empty slots with bots
    SendToServerConsole("dota_bot_populate")
  end

  -- Don't think these settings are necessary
  -- GameRules:GetGameModeEntity():SetBotThinkingEnabled(true)
  -- GameRules:GetGameModeEntity():SetBotsInLateGame(true)

  -- This applies the simple bot controller ability, which shouldn't be necessary since bots have a semi-proper AI by RamonNZ.
  -- The AI probably doesn't quite work right due to all the map changes though. Don't think the bots know where all the camps are now.
  -- Timers:CreateTimer(5,function()
  --   PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
  --     local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  --     if hero ~= nil and IsValidEntity(hero) and PlayerResource:GetSteamAccountID(playerID) == 0 then
  --       hero:AddAbility("dev_bot_control")
  --       local controller = hero:FindAbilityByName("dev_bot_control")
  --       if controller then
  --         controller:UpgradeAbility(false)
  --         controller:SetHidden(true)
  --       end
  --     end
  --   end)
  -- end)
end

-- Remove fog of war on the map, revealing everything
function DevCheats:DisableFog(keys)
  GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)
end

-- Bring the back fog of war
-- BUG?: Re-enabling Fog of War after disabling causes a blue overlay to mark all areas seen since re-enabling Fog of War
function DevCheats:EnableFog(keys)
  GameRules:GetGameModeEntity():SetFogOfWarDisabled(false)
end

-- Teleport all heroes to their fountain
function DevCheats:TeleportHeroesToFountain(keys)
  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  local radiant_fountain
  local dire_fountain
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      dire_fountain = entity
    end
  end
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero and not hero:IsNull() then
      local team = hero:GetTeamNumber()
      if team == DOTA_TEAM_GOODGUYS then
        FindClearSpaceForUnit(hero, radiant_fountain:GetAbsOrigin(), true)
        hero:AddNewModifier(hero, nil, "modifier_phased", {duration = FrameTime()})
      elseif team == DOTA_TEAM_BADGUYS then
        FindClearSpaceForUnit(hero, dire_fountain:GetAbsOrigin(), true)
        hero:AddNewModifier(hero, nil, "modifier_phased", {duration = FrameTime()})
      end
    end
  end)
end

-- Print vector of current position of hero to console and chat
function DevCheats:PrintPosition(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)

  print(hero:GetAbsOrigin())
  GameRules:SendCustomMessage(tostring(hero:GetAbsOrigin()), 0, 0)
end

-- Toggle invulnerability on player hero
function DevCheats:GodMode(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local godMode = hero:FindModifierByName("modifier_invulnerable")
  if godMode then
    hero:RemoveModifierByName("modifier_invulnerable")
  else
    hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
  end
end

-- Toggle disarm on player hero
function DevCheats:ToggleDisarm(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local disarmModifier = hero:FindModifierByName("modifier_disarmed")
  if disarmModifier then
    hero:RemoveModifierByName("modifier_disarmed")
  else
    hero:AddNewModifier(hero, nil, "modifier_disarmed", {})
  end
end

-- Give player global Blink Dagger
function DevCheats:GiveDevDagger(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  hero:AddItemByName('item_devDagger')
end

-- Give player specified level of upgrade core
function DevCheats:GiveUpgradeCore(keys)
  -- Give user lvl 1 core, unless they specify a number after
  local level = 1
  local text = string.lower(keys.text)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local splitted = split(text, " ")
  if splitted[2] and tonumber(splitted[2]) then
    level = tonumber(splitted[2])
  end

  if level == 1 then
    hero:AddItemByName("item_upgrade_core")
  elseif level == 2 then
    hero:AddItemByName("item_upgrade_core_2")
  elseif level == 3 then
    hero:AddItemByName("item_upgrade_core_3")
  elseif level == 4 then
    hero:AddItemByName("item_upgrade_core_4")
  end
end

-- Adds an ability, if partial name given, gives the last ability it finds matching that string
function DevCheats:AddAbility(keys)
  local text = string.lower(keys.text)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local splitted = split(text, " ")
  if splitted[2] then
    local absCustom = LoadKeyValues('scripts/npc/npc_abilities_override.txt')
    for k,v in pairs(absCustom) do
      --print(k)
      if string.find(k, splitted[2]) then
        splitted[2] = k
      end
    end
    hero:AddAbility(splitted[2])
  end
end

-- Give items. If you put a number after the name of the item, it will look for that level, e.g. "-give heart 3" gives lvl 3 heart
-- NOTE: Partial item name matching is a little funny, e.g. "-give heart" gives item_heart_transplant. Not sure this is fixable
function DevCheats:GiveLevelledItem(keys)
  local text = string.lower(keys.text)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local level = nil
  local splitted = split(text, " ")

  if splitted[3] and tonumber(splitted[3]) then
    level = tonumber(splitted[3])
  end
  if splitted[2] then
    local absCustom = LoadKeyValues('scripts/npc/npc_items_custom.txt')
    for k,v in pairs(absCustom) do
      if string.find(k, splitted[2]) and not string.find(k, "recipe") then
        if not splitted[3] or string.find(k, splitted[3]) then
          splitted[2] = k
          break
        end
      end
    end

    hero:AddItemByName(splitted[2])
  end
end

-- Set player inventory to pre-defined loadouts
function DevCheats:GiveLoadout(keys)
  local loadouts = {
    ['tank'] = {"item_heart_oaa_5", "item_stoneskin_2", "item_eternal_shroud_5", "item_pipe_5"},
    ['damage'] = {"item_greater_crit_5", "item_devastator_oaa_5", "item_mjollnir_5", "item_monkey_king_bar_5"},
  }
  local text = string.lower(keys.text)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local splitted = split(text, " ")
  if splitted[2] then
    if loadouts[splitted[2]] then
      local RemoveItem = function(handle) hero:RemoveItem(handle) end
      local GetItemInSlot = function(slot) return hero:GetItemInSlot(slot) end
      local AddItemByName = function(item) hero:AddItemByName(item) end

      each(RemoveItem, map(GetItemInSlot, range(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6)))
      each(AddItemByName, iter(loadouts[splitted[2]]))
    end
  end
end

-- Give player Aghanim's Scepter
function DevCheats:GiveUltimateScepter(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local name = "item_ultimate_scepter"
  hero:AddItemByName(name)
end

-- Give player Aghanim's Shard
function DevCheats:GiveAghanimShard(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local name = "item_aghanims_shard"
  hero:AddItemByName(name)
end

-- Give player Dev Dagon
function DevCheats:GiveDevDagon(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  hero:AddItemByName("item_devDagon")
end

-- Switch player's hero to given hero
function DevCheats:SwitchHero(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local playerID = keys.playerid

  if splitted[2] then
    local herolist = LoadKeyValues('scripts/npc/herolist.txt')
    for hero,_ in pairs(herolist) do
      if string.find(hero, splitted[2]) then
        PrecacheUnitByNameAsync(
          hero,
          function()
            local old_gold = Gold:GetGold(playerID)
            PlayerResource:ReplaceHeroWith(playerID, hero, 0, 0)
            Gold:SetGold(playerID, old_gold) -- because ReplaceHeroWith doesn't work properly ofc
          end,
          playerID
        )
      end
    end
  else
    GameRules:SendCustomMessage("Usage is -switchhero X, where X is the name of the hero to switch to", 0, 0)
  end
end

function DevCheats:LevelUp(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local number
  if #splitted > 0 then
    number = tonumber(splitted[1])
  end

  if not number then
    number = 1
  end

  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)

  local desiredLevel = math.min(50, hero:GetLevel() + number)

  Timers:CreateTimer(function()
    while hero:GetLevel() < desiredLevel do
      if XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] < hero:GetCurrentXP() then
        print('Level was totally wrong ' .. tostring(hero:GetCurrentXP()) .. ' > ' .. tostring(XP_PER_LEVEL_TABLE[hero:GetLevel() + 1]))
        return
      end
      hero:AddExperience(XP_PER_LEVEL_TABLE[hero:GetLevel() + 1] - hero:GetCurrentXP(), DOTA_ModifyXP_Unspecified, false, false)
    end
  end)
end

function DevCheats:KillEverything(keys)
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local all_units = FindUnitsInRadius(
    hero:GetTeamNumber(),
    Vector(0, 0, 0),
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_BOTH,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
    FIND_ANY_ORDER,
    false
  )

  for _, unit in pairs(all_units) do
    if unit and not unit:IsNull() and unit ~= hero then
      unit:Kill(nil, hero)
    end
  end
end

function DevCheats:CountAllEntities(keys)
  local hero_count = 0
  local creep_count = 0
  local thinker_count = 0
  local wearable_count = 0
  local modifier_count = 0
  local all_entities = Entities:FindAllInSphere(Vector(0, 0, 0), 50000)

  for _, ent in pairs(all_entities) do
    if string.find(ent:GetDebugName(), "hero") then
      hero_count = hero_count + 1
    end

    if string.find(ent:GetDebugName(), "creep") then
      creep_count = creep_count + 1
    end

    if string.find(ent:GetDebugName(), "thinker") then
      thinker_count = thinker_count + 1
    end

    if string.find(ent:GetDebugName(), "wearable") then
      wearable_count = wearable_count + 1
    end

    if ent.FindAllModifiers then
      local ent_modifiers = ent:FindAllModifiers()
      modifier_count = modifier_count + #ent_modifiers
    end
  end

  GameRules:SendCustomMessage("There are currently "..tostring(#all_entities).." entities residing on the map. From these entities, it is estimated that...", 0, 0)
  GameRules:SendCustomMessage(tostring(hero_count).." of them are heroes, "..tostring(creep_count).." of them are creeps, "..tostring(thinker_count).." of them are thinkers, and "..tostring(wearable_count).." of them are wearables.", 0, 0)
  GameRules:SendCustomMessage("There are a total of "..tostring(modifier_count).." modifiers present.", 0, 0)
end

function DevCheats:MemoryUsage(keys)
  local function comma_value(n)
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
  end
  GameRules:SendCustomMessage("Current LUA Memory Usage: "..comma_value(collectgarbage('count')*1024).." KB", 0, 0)
end
