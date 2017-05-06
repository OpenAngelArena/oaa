--[[
===== ChatCommand =====
Makes it easier to create commands from anywhere in your code.
Does not break when using script_reload
Usage:
  -Create a function MyFunction(keys)             OR     function SomeClass:SomeFunction(keys)
    keys are those delivered from the 'player_chat' event
  -Use ChatCommand:LinkCommand("-MyTrigger", "MyFunction")   OR     ChatCommand:LinkCommand("-MyTrigger", "SomeFunction", SomeClass)
    Use this to call this function everytime someone's chat starts with -MyTrigger
created by Zarnotox with a lot of constructive help from the mod data guys https://discord.gg/Z7eCcGT (THIS IS NOT THE OAA DISCORD, THIS IS THE MODDATA DISCORD. YOU DID NOT FIND THE SECRET. check it out!)
]]

ChatCommand = ChatCommand or {}

-- Begin Initialise
function ChatCommand:Init()
  self.initialised = true
  ListenToGameEvent("player_chat", Dynamic_Wrap(ChatCommand, 'OnPlayerChat'), self)
end

if not ChatCommand.initialised then
    ChatCommand:Init()
end
-- End Initialise

-- Function to create the link
function ChatCommand:LinkCommand(command, funcName, obj)
  self.commands = self.commands or {}
  self.commands[command] = {funcName, obj}
end

-- Function that's called when somebody chats
function ChatCommand:OnPlayerChat(keys)
  self.commands = self.commands or {}
  local text = string.lower(keys.text)
  local teamonly = keys.teamonly
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)

  local splitted = split(text, " ")

  if self.commands[splitted[1]] ~= nil then
    local location = self.commands[splitted[1]]
    funcName = location[1]

    if location[2] == nil then
      _G[funcName](keys)
    else
      local obj = location[2]
      obj[funcName](obj, keys)
    end
  end

    ----------------------------
    -- Debug/Cheat Commands
    ----------------------------
  if IsInToolsMode() or Convars:GetBool("sv_cheats") then

    -- Test command to quickly test anything
    if string.find(text, "-list") or string.find(text, "-help") then
      GameRules:SendCustomMessage("-nofog, -fog, -god, -disarm, -dagger, -core 1-4, -startduel, -endduel, -addbots", 0, 0)
      GameRules:SendCustomMessage("-addability x, -give x y, -fixspawn, -noend, -switchhero x, -loadout x, -scepter [1-5]", 0, 0)

      -- Add bots to both teams
    elseif string.find(text, "-addbots") then
      local num = 0
      local used_hero_name = "npc_dota_hero_luna"

      for i=0, DOTA_MAX_TEAM_PLAYERS do
        if PlayerResource:IsValidPlayer(i) then
          print(i)

          -- Random heroes for people who have not picked
          if PlayerResource:HasSelectedHero(i) == false then
            --print("Randoming hero for:", i)

            local player = PlayerResource:GetPlayer(i)
            player:MakeRandomHeroSelection()

            local hero_name = PlayerResource:GetSelectedHeroName(i)

            --print("Randomed:", hero_name)
          end

          used_hero_name = PlayerResource:GetSelectedHeroName(i)
          num = num + 1
        end
      end

      self.numPlayers = num
      --print("Number of players:", num)

      -- Eanble bots and fill empty slots
      if IsServer() == true and 10 - self.numPlayers > 0 then
        --print("Adding bots in empty slots")

        for i=1, 5 do
          Tutorial:AddBot(used_hero_name, "", "unfair", true)
          Tutorial:AddBot(used_hero_name, "", "unfair", false)
        end

      end

      GameRules:GetGameModeEntity():SetBotThinkingEnabled(true)
      Tutorial:StartTutorialMode()
      GameRules:GetGameModeEntity():SetBotsInLateGame(true)

      Timers:CreateTimer(5,function()
      for playerID=0,24-1 do
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if hero ~= nil and IsValidEntity(hero) and PlayerResource:GetSteamAccountID(playerID) == 0 then
          hero:AddAbility("dev_bot_control")
          local controller = hero:FindAbilityByName("dev_bot_control")
          if controller then
            controller:UpgradeAbility(false)
            controller:SetHidden(true)
          end
        end
      end
      end)

    -- Remove fog of war on the map, revealing everything
    elseif string.find(text, "-nofog") then
      GameRules:GetGameModeEntity():SetFogOfWarDisabled(true)

    -- Bring back the fog of war
    elseif string.find(text, "-fog") then
      GameRules:GetGameModeEntity():SetFogOfWarDisabled(false)

    -- Bring back the fog of war
    elseif string.find(text, "-fixspawn") then
       for playerID=0,24-1 do
        local hero = PlayerResource:GetSelectedHeroEntity(playerID)
        if hero ~= nil and IsValidEntity(hero) then
          hero:AddNewModifier(caster, ability, "modifier_chen_test_of_faith_teleport", {duration = 1})
        end
      end


    -- Force start of a duel
    elseif string.find(text, "-startduel") then
      Duels:StartDuel()

    -- Force end of a duel
    elseif string.find(text, "-endduel") then
      Duels:EndDuel()

    -- Prints vector of current position of hero to console
    elseif string.find(text, "-getpos") then
      print(hero:GetAbsOrigin())
      GameRules:SendCustomMessage(tostring(hero:GetAbsOrigin()), 0, 0)

    -- Give Invulnerability
    elseif string.find(text, "-god") then
      local godMode = hero:FindModifierByName("modifier_invulnerable")
      if godMode then
        hero:RemoveModifierByName("modifier_invulnerable")
      else
        hero:AddNewModifier(hero,nil,"modifier_invulnerable",{duration = duration})
      end

    -- Disarms the hero, to prevent autoattack
    elseif string.find(text, "-disarm") then
      local godMode = hero:FindModifierByName("modifier_disarmed")
      if godMode then
        hero:RemoveModifierByName("modifier_disarmed")
      else
        hero:AddNewModifier(hero,nil,"modifier_disarmed",{duration = duration})
      end

    -- Give Global blink dagger
    elseif string.find(text, "-dagger") then
      hero:AddItemByName('item_devDagger')

    -- Give upgrade core of level x
    elseif string.find(text, "-core") then
      -- Give user lvl 1 core, unless they specify a number after
      local level = 1
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

    -- Adds an ability, if partial name given, gives the last ability it finds matching that string
  elseif string.find(text, "-addability") then
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
        for i = 0, 23 do
          if hero:GetAbilityByIndex(i) then
            local ability = hero:GetAbilityByIndex(i)
            if ability and string.match(ability:GetName(), "special_bonus_") then
              local abName = ability:GetName()
              hero:RemoveAbility(abName)
            end
          end
        end
      end

    -- Give items. If you put a number after the name of the item, it will look for that number, e.g. "-give heart 3" gives lvl 3 heart
    elseif string.find(text, "-give") then
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
            end
          end
        end

        hero:AddItemByName(splitted[2])
      end

    elseif string.find(text, "-noend") then
      CustomNetTables:SetTableValue('team_scores', 'limit', {value = 9999999})

    elseif string.find(text, "-switchhero") then
      local splitted = split(text, " ")

      if splitted[2] then
        local herolist = LoadKeyValues('scripts/npc/herolist.txt')
        for hero,_ in pairs(herolist) do
          if string.find(hero, splitted[2]) then
            PrecacheUnitByNameSync(hero)
            PlayerResource:ReplaceHeroWith(playerID, hero, Gold:GetGold(playerID), PlayerResource:GetTotalEarnedXP(playerID))
          end
        end
      end

    elseif string.find(text, "-loadout") then
      local loadouts = {
        ['tank']={"item_heart_5", "item_stoneskin_2", "item_satanic_core_3"},
      }
      local splitted = split(text, " ")
      if splitted[2] then
        if loadouts[splitted[2]] then
          local RemoveItem = function(handle) hero:RemoveItem(handle) end
          local GetItemInSlot = function(slot) hero:GetItemInSlot(slot) end
          local AddItemByName = function(item) hero:AddItemByName(item) end
          -- BUG: Items don't get removed
          each(RemoveItem, map(GetItemInSlot, range(DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6)))
          each(AddItemByName, iter(loadouts[splitted[2]]))
        end
      end

    elseif string.find(text, "-scepter") then
      local splitted = split(text, " ")
      local name = "item_ultimate_scepter"
      if splitted[2] then
        name = name .. "_" .. splitted[2]
      end
      hero:AddItemByName(name)

    elseif string.find(text, "-addpoints") then
      local splitted = split(text, " ")
      local teamID = hero:GetTeam()
      local points = tonumber(splitted[2]) or 1
      PointsManager:AddPoints(teamID, points)

    end
  end
end
