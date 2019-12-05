-- Component for various chat commands useful for testing
-- Majority of original command code by Darklord

DevCheats = class({})

function DevCheats:Init()
  ChatCommand:LinkDevCommand("-help", Dynamic_Wrap(DevCheats, "Help"), self)
  ChatCommand:LinkDevCommand("-list", Dynamic_Wrap(DevCheats, "Help"), self)
  ChatCommand:LinkDevCommand("-print_modifiers", Dynamic_Wrap(DevCheats, "PrintModifiers"), self)
  ChatCommand:LinkDevCommand("-addbots", Dynamic_Wrap(DevCheats, "AddBots"), self)
  ChatCommand:LinkDevCommand("-nofog", Dynamic_Wrap(DevCheats, "DisableFog"), self)
  ChatCommand:LinkDevCommand("-fog", Dynamic_Wrap(DevCheats, "EnableFog"), self)
  ChatCommand:LinkDevCommand("-fixspawn", Dynamic_Wrap(DevCheats, "TeleportHeroesToFountain"), self)
  ChatCommand:LinkDevCommand("-getpos", Dynamic_Wrap(DevCheats, "PrintPosition"), self)
  ChatCommand:LinkDevCommand("-god", Dynamic_Wrap(DevCheats, "GodMode"), self)
  ChatCommand:LinkDevCommand("-disarm", Dynamic_Wrap(DevCheats, "ToggleDisarm"), self)
  ChatCommand:LinkDevCommand("-dagger", Dynamic_Wrap(DevCheats, "GiveDevDagger"), self)
  ChatCommand:LinkDevCommand("-core", Dynamic_Wrap(DevCheats, "GiveUpgradeCore"), self)
  ChatCommand:LinkDevCommand("-addability", Dynamic_Wrap(DevCheats, "AddAbility"), self)
  ChatCommand:LinkDevCommand("-give", Dynamic_Wrap(DevCheats, "GiveLevelledItem"), self)
  ChatCommand:LinkDevCommand("-loadout", Dynamic_Wrap(DevCheats, "GiveLoadout"), self)
  ChatCommand:LinkDevCommand("-scepter", Dynamic_Wrap(DevCheats, "GiveUltimateScepter"), self)
  ChatCommand:LinkDevCommand("-dagon", Dynamic_Wrap(DevCheats, "GiveDevDagon"), self)
  ChatCommand:LinkDevCommand("-switchhero", Dynamic_Wrap(DevCheats, "SwitchHero"), self)
  ChatCommand:LinkDevCommand("-lazer", Dynamic_Wrap(DevCheats, "AddDevAttack"), self)
  ChatCommand:LinkDevCommand("-lvlup", Dynamic_Wrap(DevCheats, "LevelUp"), self)
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

-- Print list of available commands to chat
function DevCheats:Help(keys)
  GameRules:SendCustomMessage("-nofog, -fog, -god, -disarm, -dagger, -core 1-4, -duel, -end_duel, -addbots", 0, 0)
  GameRules:SendCustomMessage("-addability x, -give x y, -fixspawn, -kill_limit x, -switchhero x, -loadout x, -scepter [1-5]", 0, 0)
  GameRules:SendCustomMessage("-addpoints, -print_modifiers, -dagon, -lazer, -spawncamps, -getpos", 0, 0)
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
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero ~= nil and IsValidEntity(hero) then
      hero:AddNewModifier(nil, nil, "modifier_chen_test_of_faith_teleport", {duration = 1})
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

    -- Not sure what this is for. Seems to remove Talents for some reason?
    -- for i = 0, 23 do
    --   if hero:GetAbilityByIndex(i) then
    --     local ability = hero:GetAbilityByIndex(i)
    --     if ability and string.match(ability:GetName(), "special_bonus_") then
    --       local abName = ability:GetName()
    --       hero:RemoveAbility(abName)
    --     end
    --   end
    -- end
  end
end

function DevCheats:AddDevAttack(keys)
  PlayerResource:GetSelectedHeroEntity(keys.playerid):AddAbility("dev_attack")
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
    ['tank'] = {"item_heart_5", "item_stoneskin_2", "item_satanic_core_3"},
    ['damage'] = {"item_greater_crit_5", "item_desolator_5", "item_mjollnir_5", "item_monkey_king_bar_5"},
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

-- Give player Aghanim's Scepter of given level or level 1 if no level given
function DevCheats:GiveUltimateScepter(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local name = "item_ultimate_scepter"
  if splitted[2] then
    name = name .. "_" .. splitted[2]
  end
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
        PrecacheUnitByNameAsync(hero, function()
          PlayerResource:ReplaceHeroWith(playerID, hero, Gold:GetGold(playerID), PlayerResource:GetTotalEarnedXP(playerID))
        end)
      end
    end
  else
    GameRules:SendCustomMessage("Usage is -switchhero X, where X is the name of the hero to switch to", 0, 0)
  end
end

function DevCheats:LevelUp(keys)
  local text = string.lower(keys.text)
  local splitted = split(text, " ")
  local number = false
  if #splitted > 0 then
    number = tonumber(splitted[1])
  end

  if not number then
    number = 1
  end

  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)

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
