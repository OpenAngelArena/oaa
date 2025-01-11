if HeroSelection == nil then
  Debug:EnableDebugging()
  DebugPrint ('Starting HeroSelection')
  HeroSelection = class({})
end

HERO_SELECTION_WHILE_PAUSED = false

-- available heroes
local herolist = {}
local lockedHeroes = {}
local loadedHeroes = {} -- marks the hero as precached
local totalheroes = 0

local cmtimer = nil
local rankedTimer = nil

-- storage for this game picks
local selectedtable = {}
-- force stop handle for timer, when all picked before time end
local forcestop = false

-- list all available heroes and get their primary attrs, and send it to client
function HeroSelection:Init ()
  Debug.EnabledModules['heroselection:*'] = false
  DebugPrint("Initializing HeroSelection")
  self.moduleName = "HeroSelection"

  self.isCM = GetMapName() == "captains_mode"
  self.is10v10 = GetMapName() == "10v10" or GetMapName() == "oaa_bigmode"
  self.isRanked = GetMapName() == "oaa_alternate" or GetMapName() == "oaa_seasonal" or GetMapName() == "oaa_legacy" or GetMapName() == "tinymode"
  self.lowPlayerCount = GetMapName() == "1v1" or GetMapName() == "tinymode"

  local herolistFile = 'scripts/npc/herolist.txt'
  if self.isCM then
    herolistFile = 'scripts/npc/herolist_cm.txt'
  end
  if self.is10v10 then
    herolistFile = 'scripts/npc/herolist_10v10.txt'
  end
  if self.lowPlayerCount then
    herolistFile = 'scripts/npc/herolist_2_6_players.txt'
  end
  if self.isRanked or self.is10v10 or self.lowPlayerCount then
    self.isBanning = true
  end

  local heroAbilities = {}
  for key, value in pairs(LoadKeyValues(herolistFile)) do
    --DebugPrint("Heroes: ".. key)
    local hero_data = GetUnitKeyValuesByName(key)
    if not hero_data then
      DebugPrint("Couldn't find keyvalues for hero "..key)
      local data = {}
      if key == "npc_dota_hero_electrician" then
        data = LoadKeyValues('scripts/npc/heroes/chatterjee.txt')
      elseif key == "npc_dota_hero_sohei" then
        data = LoadKeyValues('scripts/npc/heroes/sohei.txt')
      elseif key == "npc_dota_hero_eul" then
        data = LoadKeyValues('scripts/npc/heroes/eul.txt')
      else
        data = LoadKeyValues('scripts/npc/npc_heroes.txt')
      end

      if data and data[key] then
        hero_data = data[key]
      end
    end
    if value == 1 then
      if not heroAbilities[hero_data.AttributePrimary] then
        heroAbilities[hero_data.AttributePrimary] = {}
      end
      local function FilterOutHiddenAbilities(ability_name)
        if not ability_name or ability_name == "" then
          return "generic_hidden"
        end
        local ability_data = GetAbilityKeyValuesByName(ability_name)
        if not ability_data then
          return "generic_hidden"
        end
        local ability_behaviour = ability_data.AbilityBehavior
        if not ability_behaviour then
          return "generic_hidden"
        end
        if string.find(ability_behaviour, "DOTA_ABILITY_BEHAVIOR_HIDDEN") then
          return "generic_hidden"
        end
        return ability_name
      end
      heroAbilities[hero_data.AttributePrimary][key] = {
        FilterOutHiddenAbilities(hero_data.Ability1),
        FilterOutHiddenAbilities(hero_data.Ability2),
        FilterOutHiddenAbilities(hero_data.Ability3),
        FilterOutHiddenAbilities(hero_data.Ability4),
        FilterOutHiddenAbilities(hero_data.Ability5),
        FilterOutHiddenAbilities(hero_data.Ability6),
        FilterOutHiddenAbilities(hero_data.Ability7),
        FilterOutHiddenAbilities(hero_data.Ability8),
        FilterOutHiddenAbilities(hero_data.Ability9)
      }
      herolist[key] = hero_data.AttributePrimary
      totalheroes = totalheroes + 1
      assert(key ~= FORCE_PICKED_HERO, "FORCE_PICKED_HERO cannot be a pickable hero")
    end
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', {gametype = GetMapName(), herolist = herolist})
  for attr, data in pairs(heroAbilities) do
    CustomNetTables:SetTableValue( 'hero_selection', 'abilities_' .. attr, data)
  end

  GameEvents:OnHeroInGame(function (hero)
    if not HeroSelection.isARDM then
      local playerId = hero:GetPlayerID()
      local hero_name = hero:GetUnitName()
      -- Don't trigger for neutrals, Tempest Double and Meepo Clones
      if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS or hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
        return
      end
      DebugPrint("OnHeroInGame - Hero "..hero_name.." spawned for the first time.")
      if hero_name == "npc_dota_hero_electrician" or hero_name == "npc_dota_hero_sohei" then
        DebugPrint("OnHeroInGame - Applying custom arcana for player "..tostring(playerId).." and hero "..hero_name..".")
        HeroCosmetics:ApplySelectedArcana(hero, HeroSelection:GetSelectedArcanaForPlayer(playerId)[hero_name])
      end
      -- loadedHeroes is here to mark the spawned hero as already precached in case the player spawned in the wrong hero with 'vanilla random'
      -- we can't fix the wrong hero here...
      loadedHeroes[hero_name] = true
    end
  end)

  GameEvents:OnHeroSelection(function (keys)
    if OAAOptions and OAAOptions.settings then
      HeroSelection.isARDM = OAAOptions.settings.GAME_MODE == "ARDM"
    end

    if HeroSelection.isARDM and ARDMMode then
      PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
        HeroSelection:UpdateTable(playerID, "empty")
      end)
      HeroSelection:APTimer(-1, "ALL RANDOM")
      HeroSelection:BuildBottlePass()
    else
      print("START HERO SELECTION")
      HeroSelection:StartSelection()
    end
  end)

  GameEvents:OnPlayerReconnect(function (keys)
    local playerid = keys.PlayerID or keys.player_id
    if not playerid then
      print("HeroSelection module - player_reconnected event has no PlayerID or player_id key. Gj Valve.")
      return
    end
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    local hero_name
    if hero then
      hero_name = hero:GetUnitName()
    end
    -- Prevent hero changing if game time is after MIN_MATCH_TIME
    if HudTimer and HudTimer:GetGameTime() > MIN_MATCH_TIME then
      lockedHeroes[playerid] = hero_name
      return
    end
    if not lockedHeroes[playerid] then
      -- Player didnt lock a hero before disconnecting
      -- Indirectly check when player reconnected (during picking or when game started)
      if hero_name and HeroSelection:IsHeroDisabled(hero_name) then
        -- Reconnected when game started and randomed hero is invalid
        local new_hero_name = HeroSelection:RandomHero()
        if loadedHeroes[new_hero_name] then
          PlayerResource:ReplaceHeroWith(playerid, new_hero_name, 0, PlayerResource:GetTotalEarnedXP(playerid))
          Gold:SetGold(playerid, STARTING_GOLD) -- ReplaceHeroWith doesn't work properly ofc
        else
          PrecacheUnitByNameAsync(new_hero_name, function()
            PlayerResource:ReplaceHeroWith(playerid, new_hero_name, 0, PlayerResource:GetTotalEarnedXP(playerid))
            Gold:SetGold(playerid, STARTING_GOLD) -- ReplaceHeroWith doesn't work properly ofc
          end)
        end
        lockedHeroes[playerid] = new_hero_name
      elseif hero_name then
        -- Reconnected when game started and randomed hero is valid
        lockedHeroes[playerid] = hero_name
      else
        -- Reconnected during picking and not locked yet
        return
      end
    else
      -- Player locked a hero before disconnecting
      -- Check if player has no hero after reconnecting (there is a very small chance for this to happen)
      local locked_hero_name = lockedHeroes[playerid]
      if (not hero or hero_name == FORCE_PICKED_HERO) and loadedHeroes[locked_hero_name] then
        local player = PlayerResource:GetPlayer(playerid)
        if player then
          player:SetSelectedHero(locked_hero_name)
        end
        return
      end
      -- Player has a hero after reconnecting (game probably started)
      -- Check if player has a hero they didn't lock during the picking screen, change it to the locked hero
      if hero and hero_name ~= locked_hero_name and OAAOptions.settings.GAME_MODE ~= "ARDM" then
        local new_hero_name = locked_hero_name
        -- All Random mode special cases
        if OAAOptions.settings.GAME_MODE == "AR" then
          -- Locked hero is not allowed, check if actual hero is allowed, random a new one if it's not
          if HeroSelection:IsHeroDisabled(hero_name) then
            new_hero_name = HeroSelection:RandomHero()
          else
            new_hero_name = hero_name
          end
        end

        -- Change locked hero (For All Random mode)
        lockedHeroes[playerid] = new_hero_name

        -- Check if new_hero_name is already precached, change the hero to new_hero_name immediately if true
        if loadedHeroes[new_hero_name] then
          PlayerResource:ReplaceHeroWith(playerid, new_hero_name, 0, PlayerResource:GetTotalEarnedXP(playerid))
          Gold:SetGold(playerid, STARTING_GOLD) -- ReplaceHeroWith doesn't work properly ofc
        else
          PrecacheUnitByNameAsync(new_hero_name, function()
            PlayerResource:ReplaceHeroWith(playerid, new_hero_name, 0, PlayerResource:GetTotalEarnedXP(playerid))
            Gold:SetGold(playerid, STARTING_GOLD) -- ReplaceHeroWith doesn't work properly ofc
          end)
        end
      end
    end
  end)

  GameEvents:OnHeroSwapped(function (keys)
    local p1 = tonumber(keys.playerid1)
    local p2 = tonumber(keys.playerid2)

    if not p1 or not p2 or not PlayerResource:IsValidPlayerID(p1) or not PlayerResource:IsValidPlayerID(p2) then
      print("Player IDs are not valid numbers. Thanks Valve")
      return
    end

    local h1 = PlayerResource:GetSelectedHeroEntity(p1)
    local h1_name
    if h1 then
      h1_name = h1:GetUnitName()
    end
    local h2 = PlayerResource:GetSelectedHeroEntity(p2)
    local h2_name
    if h2 then
      h2_name = h2:GetUnitName()
    end

    -- Change locked heroes (we will assume that OnHeroSwapped triggers after a successful hero-swap)
    if lockedHeroes[p1] ~= h1_name then
      lockedHeroes[p1] = h1_name
    end
    if lockedHeroes[p2] ~= h2_name then
      lockedHeroes[p2] = h2_name
    end
  end)

  GameEvents:OnPreGame(function (keys)
    -- Pause the game at the start (not during strategy time)
    if HeroSelection.isCM or HeroSelection.isARDM then
      PauseGame(true)
    end
  end)
end

function HeroSelection:GetHeroList ()
  return herolist
end

-- set "empty" hero for every player and start picking phase
function HeroSelection:StartSelection ()
  DebugPrint("Starting HeroSelection Process")
  --DebugPrint(GetMapName())

  self.shouldBePaused = true
  self:CheckPause()

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    HeroSelection:UpdateTable(playerID, "empty")
  end)
  CustomGameEventManager:RegisterListener('cm_become_captain', Dynamic_Wrap(HeroSelection, 'CMBecomeCaptain'))
  CustomGameEventManager:RegisterListener('cm_hero_selected', Dynamic_Wrap(HeroSelection, 'CMManager'))
  CustomGameEventManager:RegisterListener('hero_selected', Dynamic_Wrap(HeroSelection, 'HeroSelected'))
  CustomGameEventManager:RegisterListener('preview_hero', Dynamic_Wrap(HeroSelection, 'HeroPreview'))
  CustomGameEventManager:RegisterListener('bottle_selected', Dynamic_Wrap(HeroSelection, 'OnBottleSelected'))
  CustomGameEventManager:RegisterListener('arcana_selected', Dynamic_Wrap(HeroSelection, 'OnArcanaSelected'))
  CustomGameEventManager:RegisterListener('hero_rerandomed', Dynamic_Wrap(HeroSelection, 'HeroRerandom'))

  if OAAOptions and OAAOptions.settings then
    if OAAOptions.settings.small_player_pool == 1 then
      local herolistFile = 'scripts/npc/herolist_2_6_players.txt'
      local herolistTable = LoadKeyValues(herolistFile)
      for key, value in pairs(herolistTable) do
        if value == 0 then
          table.insert(rankedpickorder.bans, key)
        end
      end
      HeroSelection.lowPlayerCount = true
    end
    if OAAOptions.settings.GAME_MODE == "ARDM" then
      local herolistFile = 'scripts/npc/herolist_ardm.txt'
      local herolistTable = LoadKeyValues(herolistFile)
      for key, value in pairs(herolistTable) do
        if value == 0 then
          table.insert(rankedpickorder.bans, key)
        end
      end
    elseif OAAOptions.settings.GAME_MODE == "LP" then
      -- local herolistFile = 'scripts/npc/herolist_lp.txt'
      -- local herolistTable = LoadKeyValues(herolistFile)
      Bottlepass:GetUnpopularHeroes(function(data)
        if data and data.ok then
          for i, value in ipairs(data.bans) do
            table.insert(rankedpickorder.bans, value)
          end
        end

        if HeroSelection.isCM then
          HeroSelection:CMManager(nil)
        elseif HeroSelection.isBanning then
          HeroSelection:RankedManager(nil)
        else
          HeroSelection:APTimer(0, "ALL PICK")
        end

        HeroSelection:BuildBottlePass()
      end)
      return

    end
    if OAAOptions.settings.HEROES_MODS == "HM03" or OAAOptions.settings.HEROES_MODS_2 == "HM03" then
      local herolistFile = 'scripts/npc/herolist_blood_magic.txt'
      local herolistTable = LoadKeyValues(herolistFile)
      for key, value in pairs(herolistTable) do
        if value == 0 then
          table.insert(rankedpickorder.bans, key)
        end
      end
    end
  end

  if self.isCM then
    self:CMManager(nil)
  elseif self.isBanning then
    self:RankedManager(nil)
  else
    self:APTimer(0, "ALL PICK")
  end

  self:BuildBottlePass()
end

function HeroSelection:BuildBottlePass()
  local special_bottles = {}
  local special_arcanas = {}
  HeroSelection.SelectedBottle = {}
  HeroSelection.SelectedArcana = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:IsValidPlayer(playerID) then
      local steamid = PlayerResource:GetSteamAccountID(playerID)
      -- get bottlepass level from server component
      local bottlepassLevel = Bottlepass.userData[steamid].bottlepassLevel

      if steamid ~= 0 then
        -- Handle bottles
        local playerBottles = {}
        if SPECIAL_BOTTLES[steamid] then
          playerBottles = SPECIAL_BOTTLES[steamid]
        end

        for level, bottleId in pairs(BOTTLEPASS_LEVEL_REWARDS) do
          if bottlepassLevel >= level then
            local hasBottle = false
            for _, existingBottle in ipairs(playerBottles) do
              if existingBottle == bottleId then
                hasBottle = true
                break
              end
            end

            if not hasBottle then
              table.insert(playerBottles, bottleId)
            end
          end
        end

        if #playerBottles > 0 then
          special_bottles[playerID] = { SteamId = steamid, PlayerId = playerID, Bottles = playerBottles }
          HeroSelection.SelectedBottle[playerID] = playerBottles[#playerBottles]
        end

        -- Handle arcanas
        local playerArcanas = {}
        if SPECIAL_ARCANAS[steamid] then
          playerArcanas = SPECIAL_ARCANAS[steamid]
        end

        for level, arcanaId in pairs(BOTTLEPASS_ARCANA_REWARDS) do
          if bottlepassLevel >= level then
            local hasArcana = false
            for _, existingArcana in ipairs(playerArcanas) do
              if existingArcana == arcanaId then
                hasArcana = true
                break
              end
            end

            if not hasArcana then
              table.insert(playerArcanas, arcanaId)
            end
          end
        end

        if #playerArcanas > 0 then
          special_arcanas[playerID] = { SteamId = steamid, PlayerId = playerID, Arcanas = playerArcanas }
        end
      end
    end
  end

  CustomNetTables:SetTableValue( 'bottlepass', 'special_bottles', special_bottles )
  CustomNetTables:SetTableValue( 'bottlepass', 'special_arcanas', special_arcanas )
end

function HeroSelection:OnBottleSelected (selectedBottle)
  if HeroSelection.SelectedBottle == nil then
    HeroSelection.SelectedBottle = {}
  end
  HeroSelection.SelectedBottle[selectedBottle.PlayerID] = selectedBottle.BottleId
  CustomNetTables:SetTableValue( 'bottlepass', 'selected_bottles', HeroSelection.SelectedBottle )
end

function HeroSelection:OnArcanaSelected (selectedArcana)
  if HeroSelection.SelectedArcana == nil then
    HeroSelection.SelectedArcana = {}
  end
  if HeroSelection.SelectedArcana[selectedArcana.PlayerID] == nil then
    HeroSelection.SelectedArcana[selectedArcana.PlayerID] = {}
  end
  HeroSelection.SelectedArcana[selectedArcana.PlayerID][selectedArcana.Hero] = selectedArcana.Arcana
  CustomNetTables:SetTableValue( 'bottlepass', 'selected_arcanas', HeroSelection.SelectedArcana )
end

function HeroSelection:GetSelectedBottleForPlayer(playerId)
  if HeroSelection.SelectedBottle == nil then
    HeroSelection.SelectedBottle = {}
  end
  return HeroSelection.SelectedBottle[playerId] or 0
end

function HeroSelection:GetSelectedArcanaForPlayer(playerId)
  if HeroSelection.SelectedArcana == nil then
    HeroSelection.SelectedArcana = {}
  end
  return HeroSelection.SelectedArcana[playerId] or {}
end

function HeroSelection:RankedManager (event)
  local function save ()
    CustomNetTables:SetTableValue( 'hero_selection', 'rankedData', rankedpickorder)
  end
  if event == nil then
    -- start
    save()
    return self:RankedTimer(RANKED_PREGAME_TIME, "PREPARING")
  end

  -- phases!
  if rankedpickorder.phase == 'strategy' then
    return
  elseif rankedpickorder.phase == 'start' then
    if event.isTimeout then
      rankedpickorder.phase = 'bans'
      save()
      return self:RankedTimer(RANKED_BAN_TIME, "BAN")
    else
      DebugPrint('Event during ranked start phase, that makes no sense!')
    end
  elseif rankedpickorder.phase == 'bans' then
    local changeToPickingPhase = event.isTimeout
    if not event.isTimeout then
      -- ban hero
      if event.hero == 'random' or rankedpickorder.banChoices[event.PlayerID] then
        -- bad ban
        save()
        return
      end
      -- good ban
      rankedpickorder.banChoices[event.PlayerID] = event.hero
      save()

      local banCount = 0
      for _, a in pairs(rankedpickorder.banChoices) do
        banCount = banCount + 1
      end
      if PlayerResource:GetAllTeamPlayerIDs():length() == banCount then
        changeToPickingPhase = true
      else
        return
      end
    end

    if event.isTimeout or changeToPickingPhase then
      rankedpickorder.phase = 'picking'
      rankedpickorder.currentOrder = 1
      self:ChooseBans()
      save()
      if OAAOptions and (OAAOptions.settings.GAME_MODE == "AR" or OAAOptions.settings.GAME_MODE == "ARDM") then
        return self:APTimer(-1, "ALL RANDOM")
      else
        return self:RankedTimer(RANKED_PICK_TIME, "PICK")
      end
    end
  elseif rankedpickorder.phase == 'picking' then
    if forcestop or not rankedpickorder.order[rankedpickorder.currentOrder] then
      rankedpickorder.phase = 'strategy'
      save()
      return HeroSelection:APTimer(0, "PRE-STRATEGY")
    end
    local choice = event.hero
    if event.isTimeout then
      DebugPrint('Timeout hero pick, randoming...')
      choice = 'forcerandom'
      local team = rankedpickorder.order[rankedpickorder.currentOrder].team
      DebugPrint('Checking team: ' .. team)
      PlayerResource:GetPlayerIDsForTeam(team):foreach(function (playerID)
        if not selectedtable[playerID] or selectedtable[playerID].selectedhero == 'empty' then
          DebugPrint('Trying player ' .. playerID)
          if not event.PlayerID or RandomInt(0, 2) == 0 then
            event.PlayerID = playerID
          end
        else
          DebugPrint('Cant random because player ' .. playerID .. ' selected: ' .. selectedtable[playerID].selectedhero)
        end
      end)
    end
    if not event.PlayerID then
      DebugPrint('How are there no players for this thing?')
      rankedpickorder.currentOrder = rankedpickorder.currentOrder + 1
      save()
      return self:RankedTimer(RANKED_PICK_TIME, "PICK")
    end
    local playerId = event.PlayerID
    local playercontroller = PlayerResource:GetPlayer(playerId) or PlayerResource:FindFirstValidPlayer()
    local original_choice = choice
    if choice == 'random' then
      if OAAOptions.settings.GAME_MODE == "SD" then
        choice = self:SingleDraftRandom(playerId)
      else
        choice = self:RandomHero(playerId)
      end

      -- Mark this player ID as a randomer
      if not selectedtable[playerId] then
        selectedtable[playerId] = {}
      end
      selectedtable[playerId].didRandom = "true"
    elseif choice == 'forcerandom' then
      if OAAOptions.settings.GAME_MODE == "SD" then
        choice = self:SingleDraftForceRandom(playerId)
      else
        choice = self:ForceRandomHero(playerId)
      end

      -- Mark this player ID as a randomer
      if not selectedtable[playerId] then
        selectedtable[playerId] = {}
      end
      selectedtable[playerId].didRandom = "true"
    end

    DebugPrint('Picking step ' .. rankedpickorder.currentOrder)
    if rankedpickorder.order[rankedpickorder.currentOrder].team ~= PlayerResource:GetTeam(playerId) then
      -- wrong team
      DebugPrint("This pick is from the wrong team!")
      save()
      return
    end
    if selectedtable[playerId] and selectedtable[playerId].selectedhero ~= 'empty' then
      -- already picked a hero
      DebugPrint("This player already selected!")
      save()
      return
    end
    rankedpickorder.order[rankedpickorder.currentOrder].hero = choice
    rankedpickorder.currentOrder = rankedpickorder.currentOrder + 1
    HeroSelection:UpdateTable(playerId, choice)
    save()
    -- Chat messages
    if selectedtable[playerId].selectedhero ~= 'empty' then
      local player_name = tostring(event.player_name or PlayerResource:GetPlayerName(playerId))
      if original_choice == 'random' then
        -- Send the 'randomed' message to chat
        CustomGameEventManager:Send_ServerToPlayer(playercontroller, 'oaa_random_hero_message', {
          player_name = player_name,
          hero = choice,
          picker_playerid = playerId
        })
      elseif original_choice == 'forcerandom' then
        local previewHero = HeroSelection:GetPreviewHero(playerId)
        local data = {
          player_name = player_name,
          hero = choice,
          forced = 1,
          picker_playerid = playerId
        }
        if choice == previewHero then
          data.forced_pick = 1
          -- Send the 'forced to pick' message to chat
          CustomGameEventManager:Send_ServerToPlayer(playercontroller, 'oaa_random_hero_message', data)
        else
          -- Send the 'forced to random' message to chat
          CustomGameEventManager:Send_ServerToPlayer(playercontroller, 'oaa_random_hero_message', data)
        end
      else
        local hero_name = tostring(event.hero_name) -- string but localized hero name not internal name
        GameRules:SendCustomMessage(player_name.." picked "..hero_name, 0, 0)
      end
    end
    return self:RankedTimer(RANKED_PICK_TIME, "PICK")
  end
  if forcestop then
    save()
    return HeroSelection:APTimer(0, "PRE-STRATEGY")
  end
end

function HeroSelection:ChooseBans ()
  local banCount = 0
  local goodBans = 0
  local badBans = 0
  local goodBanChoices = 0
  local badBanChoices = 0
  local playerIDs = {}
  local rollForBans = true

  if OAAOptions and OAAOptions.settings then
    if OAAOptions.settings.GAME_MODE == "AP" or OAAOptions.settings.GAME_MODE == "AR" then
      rollForBans = false
    end
  end

  if rollForBans then
    -- 50% chance bans, to change this -> change the condition that has RandomInt if totalChoices is 1 and while condition if totalChoices is > 1
    for playerID, choice in pairs(rankedpickorder.banChoices) do
      table.insert(playerIDs, playerID)
      local team = PlayerResource:GetTeam(playerID)
      if team == DOTA_TEAM_GOODGUYS then
        goodBanChoices = goodBanChoices + 1
      end
      if team == DOTA_TEAM_BADGUYS then
        badBanChoices = badBanChoices + 1
      end
    end

    local totalChoices = badBanChoices + goodBanChoices

    DebugPrint('Choosing bans from ' .. totalChoices .. ' nominations...')

    if totalChoices == 1 then
      if RandomInt(0, 1) == 1 then
        for playerID, choice in pairs(rankedpickorder.banChoices) do
          if choice then
            table.insert(rankedpickorder.bans, choice)
            DebugPrint('Only suggestion was ' .. choice)
          end
        end
      else
        DebugPrint('Rolled 0, no bans!')
      end
    else
      local skippedBans = 0
      local maxBansPerTeam = 3
      if HeroSelection.is10v10 then
        maxBansPerTeam = 6
      end
      while banCount < totalChoices / 2 do
        local choiceNum = RandomInt(1, totalChoices - banCount - skippedBans)
        local playerID = playerIDs[choiceNum]
        table.remove(playerIDs, choiceNum)
        local team = PlayerResource:GetTeam(playerID)
        local canBan = true
        if team == DOTA_TEAM_BADGUYS then
          if badBans >= maxBansPerTeam then
            canBan = false
            DebugPrint('Not chosing this ban because we already choose ' .. badBans .. ' bans from the Dire team')
          end
          badBans = badBans + 1
        elseif team == DOTA_TEAM_GOODGUYS then
          if goodBans >= maxBansPerTeam then
            canBan = false
            DebugPrint('Not chosing this ban because we already choose ' .. goodBans .. ' bans from the Radiant team')
          end
          goodBans = goodBans + 1
        end
        if canBan then
          banCount = banCount + 1
          DebugPrint('Banning ' .. rankedpickorder.banChoices[playerID])
          table.insert(rankedpickorder.bans, rankedpickorder.banChoices[playerID])
        else
          skippedBans = skippedBans + 1
        end
      end
    end
  else
    -- 100% chance bans
    PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
      if rankedpickorder.banChoices[playerID] then
        table.insert(rankedpickorder.bans, rankedpickorder.banChoices[playerID])
      end
    end)
  end

  -- we've applied all the ban selections, lets send what was chosen vs what was actually banned to the bottlepass server
  Bottlepass:SendBans({
    banChoices = rankedpickorder.banChoices,
    bans = rankedpickorder.bans
  })

  if OAAOptions and OAAOptions.settings then
    local list_of_hero_names = {}
    if OAAOptions.settings.GAME_MODE == "RD" then
      for k, v in pairs(herolist) do
        table.insert(list_of_hero_names, k)
      end

      -- Randomly ban certain number of heroes
      local random_draft_bans = math.ceil(#list_of_hero_names * 60/100)
      if HeroSelection.is10v10 then
        random_draft_bans = math.ceil(#list_of_hero_names * 40/100)
      end
      DebugPrint("RANDOM DRAFT: Banning "..tostring(random_draft_bans).." random heroes")
      local i = 0
      while i <= random_draft_bans do
        local random_number = RandomInt(1, #list_of_hero_names)
        local hero_name = list_of_hero_names[random_number]
        -- Check if already banned
        local banned = false
        for _, v in pairs(rankedpickorder.bans) do
          if v and v == hero_name then
            banned = true
            break -- break for loop
          end
        end

        if not banned then
          table.insert(rankedpickorder.bans, hero_name)
          i = i + 1
        end
      end
    elseif OAAOptions.settings.GAME_MODE == "SD" then
      -- generate 3 hero choices for each player
      local heroExclusions = {}
      local singleDraftChoices = {}
      PlayerResource:GetAllTeamPlayerIDs():each(function(PlayerID)
        local strengthChoice = HeroSelection:RandomHeroByAttribute('DOTA_ATTRIBUTE_STRENGTH', heroExclusions)
        local agilityChoice = HeroSelection:RandomHeroByAttribute('DOTA_ATTRIBUTE_AGILITY', heroExclusions)
        local intellectChoice = HeroSelection:RandomHeroByAttribute('DOTA_ATTRIBUTE_INTELLECT', heroExclusions)
        local allChoice = HeroSelection:RandomHeroByAttribute('DOTA_ATTRIBUTE_ALL', heroExclusions)

        heroExclusions[strengthChoice] = PlayerID
        heroExclusions[agilityChoice] = PlayerID
        heroExclusions[intellectChoice] = PlayerID
        heroExclusions[allChoice] = PlayerID

        singleDraftChoices[PlayerID] = {
          DOTA_ATTRIBUTE_STRENGTH = strengthChoice,
          DOTA_ATTRIBUTE_AGILITY = agilityChoice,
          DOTA_ATTRIBUTE_INTELLECT = intellectChoice,
          DOTA_ATTRIBUTE_ALL = allChoice
        }
      end)
      CustomNetTables:SetTableValue('hero_selection', 'SDdata', singleDraftChoices)
    end
  end
end

function HeroSelection:RankedTimer (time, message)
  self:CheckPause()

  if forcestop == true or time < 0 then
    self:RankedManager({hero = "forcerandom", isTimeout = true})
    return
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = message})

  if rankedTimer then
    Timers:RemoveTimer(rankedTimer)
    rankedTimer = nil
  end

  rankedTimer = Timers:CreateTimer({
    useGameTime = not HERO_SELECTION_WHILE_PAUSED,
    endTime = 1,
    callback = function()
      HeroSelection:RankedTimer(time - 1, message)
    end
  })
end

-- start heropick CM timer
function HeroSelection:CMManager (event)
  if forcestop == false then
    forcestop = true

    if event == nil then
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      HeroSelection:CMTimer(CAPTAINS_MODE_CAPTAIN_TIME, "CHOOSE CAPTAIN")

    elseif cmpickorder["currentstage"] == 0 then
      Timers:RemoveTimer(cmtimer)
      if cmpickorder["captainradiant"] == "empty" then
        --random captain
        local skipnext = false
        PlayerResource:GetAllTeamPlayerIDs():each(function(PlayerID)
          if skipnext == false and PlayerResource:GetTeam(PlayerID) == DOTA_TEAM_GOODGUYS then
            cmpickorder["captainradiant"] = PlayerID
            skipnext = true
          end
        end)
      end
      if cmpickorder["captaindire"] == "empty" then
        --random captain
        local skipnext = false
        PlayerResource:GetAllTeamPlayerIDs():each(function(PlayerID)
          if skipnext == false and PlayerResource:GetTeam(PlayerID) == DOTA_TEAM_BADGUYS then
            if PlayerResource:GetConnectionState(PlayerID) == DOTA_CONNECTION_STATE_CONNECTED then
              cmpickorder["captaindire"] = PlayerID
              skipnext = true
            end
          end
        end)
      end
      cmpickorder["currentstage"] = cmpickorder["currentstage"] + 1
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      HeroSelection:CMTimer(CAPTAINS_MODE_PICK_BAN_TIME, "CAPTAINS MODE")

    elseif cmpickorder["currentstage"] <= cmpickorder["totalstages"] then
      --random if not selected
      if event.hero == "random" then
        event.hero = HeroSelection:RandomHero()
      elseif event.hero == "forcerandom" then
        event.hero = HeroSelection:ForceRandomHero(event.PlayerID)
      elseif HeroSelection:IsHeroDisabled(event.hero) then
        forcestop = false
        return
      end

      -- cmpickorder["order"][cmpickorder["currentstage"]].side
      if event.PlayerID then
        if PlayerResource:GetTeam(event.PlayerID) ~= cmpickorder["order"][cmpickorder["currentstage"]].side then
          forcestop = false
          return
        end
      end

      DebugPrint('Got a CM pick ' .. cmpickorder["order"][cmpickorder["currentstage"]].side)

      Timers:RemoveTimer(cmtimer)

      if cmpickorder["order"][cmpickorder["currentstage"]].type == "Pick" then
        table.insert(cmpickorder[cmpickorder["order"][cmpickorder["currentstage"]].side.."picks"], 1, event.hero)
      end
      cmpickorder["order"][cmpickorder["currentstage"]].hero = event.hero
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      cmpickorder["currentstage"] = cmpickorder["currentstage"] + 1

      --DebugPrint('--')
      --DebugPrintTable(event)

      if cmpickorder["currentstage"] <= cmpickorder["totalstages"] then
        HeroSelection:CMTimer(CAPTAINS_MODE_PICK_BAN_TIME, "CAPTAINS MODE")
      else
        forcestop = false
        HeroSelection:APTimer(CAPTAINS_MODE_HERO_PICK_TIME, "CHOOSE HERO")
      end
    end
    forcestop = false
  end
end

-- manage cm timer
function HeroSelection:CMTimer (time, message, isReserveTime)
  HeroSelection:CheckPause()
  CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = message, isReserveTime = isReserveTime})

  if cmpickorder["currentstage"] > 0 and forcestop == false then
    if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_GOODGUYS and cmpickorder["captainradiant"] == "empty" then
      HeroSelection:CMManager({hero = "forcerandom"})
      return
    end

    if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_BADGUYS and cmpickorder["captaindire"] == "empty" then
      HeroSelection:CMManager({hero = "forcerandom"})
      return
    end
  end

  if isReserveTime then
    if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_BADGUYS then
      cmpickorder["reservedire"] = time
    elseif cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_GOODGUYS then
      cmpickorder["reserveradiant"] = time
    end
    CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
  end

  if time <= 0 then
    if cmpickorder["currentstage"] > 0 then
     if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_BADGUYS and cmpickorder["reservedire"] > 0 then
        -- start using reserve time
        time = cmpickorder["reservedire"]
        isReserveTime = true
      elseif cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_GOODGUYS and cmpickorder["reserveradiant"] > 0 then
        -- start using reserve time
        time = cmpickorder["reserveradiant"]
        isReserveTime = true
      end
    end
    if time <= 0 then
      HeroSelection:CMManager({hero = "forcerandom"})
      return
    end
  end

  cmtimer = Timers:CreateTimer({
    useGameTime = not HERO_SELECTION_WHILE_PAUSED,
    endTime = 1,
    callback = function()
      HeroSelection:CMTimer(time -1, message, isReserveTime)
    end
  })
end

function HeroSelection:CheckPause ()
  if HERO_SELECTION_WHILE_PAUSED then
    if GameRules:IsGamePaused() ~= HeroSelection.shouldBePaused then
      PauseGame(HeroSelection.shouldBePaused)
    end
  end
end

-- become a captain, go to next stage, if both captains are selected
function HeroSelection:CMBecomeCaptain (event)
  DebugPrint("Selecting captain")
  DebugPrintTable(event)
  if PlayerResource:GetTeam(event.PlayerID) == DOTA_TEAM_GOODGUYS then
    cmpickorder["captainradiant"] = event.PlayerID
    CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
    if cmpickorder["captaindire"] and cmpickorder["captaindire"] ~= "empty" then
      HeroSelection:CMManager({dummy = "dummy"})
    end
  elseif PlayerResource:GetTeam(event.PlayerID) == DOTA_TEAM_BADGUYS then
    cmpickorder["captaindire"] = event.PlayerID
    CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
    if cmpickorder["captainradiant"] and cmpickorder["captainradiant"] ~= "empty" then
      HeroSelection:CMManager({dummy = "dummy"})
    end
  end
end

-- start heropick AP timer
function HeroSelection:APTimer (time, message)
  DebugPrint("APTimer - "..tostring(message))
  self:CheckPause()

  if forcestop == true or time < 0 then
    for playerId, value in pairs(selectedtable) do
      if value.selectedhero == "empty" then
        -- if someone hasnt selected until time end, random for him
        if self.isCM then
          self:UpdateTable(playerId, cmpickorder[value.team.."picks"][1])
        else
          self:UpdateTable(playerId, "random") -- important for AR and ARDM
        end
      end
      self:SelectHero(playerId, selectedtable[playerId].selectedhero) -- important for every game mode
    end

    -- Iterate over each player and update their hero table only if they haven't locked in a hero yet
    -- `lockedHeroes[playerId]` will not exist if `HeroSelection:SelectHero` (used in the loop above) didn't work or if
    -- `selectedtable` doesn't have all the player slots -> that is possible only if 'StartSelection' (inital 'UpdateTable') didn't happen (ARDM for example)
    -- `HeroSelection:SelectHero` will not work only if 'selectedtable[playerId].selectedhero' was `nil` or something invalid ('empty')
    PlayerResource:GetAllTeamPlayerIDs():each(function (playerId)
      if not lockedHeroes[playerId] then
        if HeroSelection.isCM then
          HeroSelection:UpdateTable(playerId, cmpickorder[PlayerResource:GetTeam(playerId).."picks"][1])
        else
          local hero
          if OAAOptions.settings.GAME_MODE == "SD" then
            hero = HeroSelection:SingleDraftForceRandom(playerId)
          else
            hero = HeroSelection:ForceRandomHero(playerId)
          end
          HeroSelection:UpdateTable(playerId, hero)
          HeroSelection:SelectHero(playerId, hero)
        end
      end
    end)

    HeroSelection:StrategyTimer(3)
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = message})
    Timers:CreateTimer({
      useGameTime = not HERO_SELECTION_WHILE_PAUSED,
      endTime = 1,
      callback = function()
        HeroSelection:APTimer(time - 1, message)
      end
    })
  end
end

function HeroSelection:SelectHero (playerId, hero)
  local hero_name = hero
  if not self.alreadySelectedHeroForThisPlayerID then
    self.alreadySelectedHeroForThisPlayerID = {}
  end
  if self.alreadySelectedHeroForThisPlayerID[playerId] then
    DebugPrint("SelectHero - Already did hero selection for playerID: "..tostring(playerId))
    return
  end

  self.alreadySelectedHeroForThisPlayerID[playerId] = true

  if not hero_name then
    DebugPrint("SelectHero - Selected hero is nil for playerID: "..tostring(playerId))
    return
  end

  if hero_name == "empty" then
    DebugPrint("SelectHero - Selected hero is invalid for playerID: "..tostring(playerId))
    return
  end

  local player = PlayerResource:GetPlayer(playerId)
  if player then
    player:SetSelectedHero(hero_name)
  end

  lockedHeroes[playerId] = hero_name

  -- Precache the hero if player is disconnected, game will precache automatically if connected
  if not player then
    PrecacheUnitByNameAsync(hero_name, function()
      loadedHeroes[hero_name] = true
    end)
  end
end

function HeroSelection:IsHeroDisabled (hero)
  if self.isCM then
    for _, data in ipairs(cmpickorder["order"]) do
      if hero == data.hero then
        return true
      end
    end
  elseif self.isBanning then
    for _, bannedHero in pairs(rankedpickorder.bans) do
      if bannedHero and hero == bannedHero then
        return true
      end
    end
    for _, data in pairs(rankedpickorder.order) do
      if hero == data.hero then
        return true
      end
    end
    if hero ~= "empty" and self:IsHeroChosen(hero) then
      return true
    end
  end
  if not hero or hero == "npc_dota_hero_dummy_dummy" or hero == "empty" then
    return true
  end
  return false
end

function HeroSelection:IsHeroChosen (hero)
  for _, data in pairs(selectedtable) do
    if hero == data.selectedhero then
      return true
    end
  end
  return false
end

function HeroSelection:ForceRandomHero (playerId)
  if not playerId or (OAAOptions and (OAAOptions.settings.GAME_MODE == "AR" or OAAOptions.settings.GAME_MODE == "ARDM")) then
    DebugPrint("ForceRandomHero - Doing normal random for AR or ARDM and for players without player ID.")
    return HeroSelection:RandomHero()
  end
  local previewHero = HeroSelection:GetPreviewHero(playerId)
  local team = tostring(PlayerResource:GetTeam(playerId))
  DebugPrint("ForceRandomHero - Started forced random for player " .. playerId .. " on team " .. team)
  if previewHero and not HeroSelection:IsHeroDisabled(previewHero) then
    DebugPrint("ForceRandomHero - Force picking highlighted hero")
    return previewHero
  end

  DebugPrint("ForceRandomHero - Bad preview hero, falling back to normal random")
  return HeroSelection:RandomHero()
end

function HeroSelection:SingleDraftForceRandom(playerId)
  local singleDraftChoices = CustomNetTables:GetTableValue('hero_selection', 'SDdata') or {}
  local myChoices = singleDraftChoices[tostring(playerId)]
  if not myChoices then
    return self:ForceRandomHero(playerId)
  end
  local previewHero = HeroSelection:GetPreviewHero(playerId)
  -- if they're forced to pick then we'll take preview hero instead
  for attr, heroName in pairs(myChoices) do
    if previewHero == heroName then
      return heroName
    end
  end

  -- otherwise random the hero
  local randomIndex = RandomInt(1, 4)
  local index = 1
  for attr, heroName in pairs(myChoices) do
    if index == randomIndex then
      return heroName
    end
    index = index + 1
  end

  -- error case? how did this happen?
  DebugPrint('Single Draft: Failed to FORCE random hero for player ' .. tostring(playerId))
  return self:ForceRandomHero(playerId)
end

function HeroSelection:SingleDraftRandom(playerId, dontPickThisHeroPlease)
  local singleDraftChoices = CustomNetTables:GetTableValue('hero_selection', 'SDdata') or {}
  local myChoices = singleDraftChoices[tostring(playerId)]
  if not myChoices then
    return self:RandomHero(playerId)
  end

  local validHeroChoices = {};

  for attr, heroName in pairs(myChoices) do
    if heroName ~= dontPickThisHeroPlease then
      table.insert(validHeroChoices, heroName)
    end
  end
  -- random the hero!
  local randomIndex = RandomInt(1, #validHeroChoices)
  local index = 1

  for attr, heroName in pairs(validHeroChoices) do
    if index == randomIndex then
      return heroName
    end
    index = index + 1
  end

  -- error case? how did this happen?
  DebugPrint('Single Draft: Failed to random hero for player ' .. tostring(playerId))
  return self:RandomHero(playerId)
end

function HeroSelection:GetPreviewHero (playerId)
  local previewTable = CustomNetTables:GetTableValue('hero_selection', 'preview_table') or {}
  local team = tostring(PlayerResource:GetTeam(playerId))
  local steamid = tostring(PlayerResource:GetSteamAccountID(playerId))
  if not PlayerResource:IsBlackBoxPlayer(playerId) then
    if previewTable[team] and previewTable[team][steamid] then
      return previewTable[team][steamid]
    end
  end
  return
end

function HeroSelection:RandomHeroByAttribute (attribute, heroExclusions)
  local attempts = 0
  while true do
    attempts = attempts + 1
    local choice = HeroSelection:RandomHero()
    if not heroExclusions[choice] and herolist[choice] == attribute then
      return choice
    end

    if attempts > 1000 then
      return choice
    end
  end

end

function HeroSelection:RandomHero ()
  local attempts = 0
  while true do
    attempts = attempts + 1
    local choice = HeroSelection:UnsafeRandomHero()
    if not self:IsHeroDisabled(choice) then
      return choice
    end

    if attempts > 1000 then
      return choice
    end
  end
end

function HeroSelection:UnsafeRandomHero ()
  local curstate = 1
  local rndhero = RandomInt(1, totalheroes)
  for name, _ in pairs(herolist) do
    if curstate == rndhero then
      return name
    end
    curstate = curstate + 1
  end
end

function HeroSelection:EndStrategyTime ()
  DebugPrint("EndStrategyTime - This shouldn't happen multiple times.")
  HeroSelection.shouldBePaused = false
  HeroSelection:CheckPause()

  -- GameMode:OnGameInProgress first happens here
  if not self.alreadyDidOnGameInProgressStuff then
    self.alreadyDidOnGameInProgressStuff = true
    DebugPrint("EndStrategyTime - Initializing modules in OnGameInProgress when hero selection is over.")
    GameMode:OnGameInProgress()

    Bottlepass:SendHeroPicks(selectedtable)
  end

  CustomNetTables:SetTableValue('hero_selection', 'time', {time = -1, mode = ""})
end

function HeroSelection:StrategyTimer (time)
  HeroSelection:CheckPause()
  if time < 0 then
    HeroSelection:EndStrategyTime()
  else
    CustomNetTables:SetTableValue('hero_selection', 'time', {time = time, mode = "STRATEGY"})
    Timers:CreateTimer({
      useGameTime = not HERO_SELECTION_WHILE_PAUSED,
      endTime = 1,
      callback = function()
        HeroSelection:StrategyTimer(time - 1)
      end
    })
  end
end

-- receive choice from players about their selection
function HeroSelection:HeroSelected (event)
  local playerId = event.PlayerID
  local hero = event.hero -- string but in a form npc_dota_hero_blah, can also be 'empty', 'random' or 'forcerandom'
  DebugPrint("Player "..playerId.." pressed a button: Ban, Lock or Random: " .. tostring(hero))

  if not hero or hero == "empty" or (not HeroSelection.isCM and HeroSelection:IsHeroDisabled(hero)) then
    Debug:EnableDebugging()
    DebugPrint('Cheater...')
    return
  end

  if OAAOptions.settings.GAME_MODE == "SD" then
    -- do SD check
    local singleDraftChoices = CustomNetTables:GetTableValue('hero_selection', 'SDdata') or {}
    local myChoices = singleDraftChoices[tostring(playerId)]
    if myChoices then
      local isAValidChoice = false

      if hero == "random" or hero == "forcerandom" then
        isAValidChoice = true
      end
      -- mark as valid when valid
      for attr, heroName in pairs(myChoices) do
        if heroName == hero then
          isAValidChoice = true
        end
      end
      if not isAValidChoice then
        return
      end
    end
  end

  local player_name = tostring(event.player_name) -- tostring(PlayerResource:GetPlayerName(playerId)) doesn't work
  local hero_name = tostring(event.hero_name) -- string but localized hero name not internal name

  if rankedpickorder.phase == 'bans' then
    if IsInToolsMode() then
      GameRules:SendCustomMessage("Tools Mode: "..player_name.." nominated "..hero_name.." to be banned.", 0, 0)
    end
  end

  if HeroSelection.isBanning then
    -- pass it off to ranked manager for bans etc
    return HeroSelection:RankedManager(event)
  end

  HeroSelection:UpdateTable(playerId, hero)
end

function HeroSelection:HeroPreview (event)
  local previewTable = CustomNetTables:GetTableValue('hero_selection', 'preview_table') or {}
  local id = event.PlayerID
  if not PlayerResource:IsBlackBoxPlayer(id) then
    local teamID = tostring(PlayerResource:GetTeam(id))
    if not previewTable[teamID] then
      previewTable[teamID] = {}
    end

    previewTable[teamID][tostring(PlayerResource:GetSteamAccountID(id))] = event.hero
    CustomNetTables:SetTableValue('hero_selection', 'preview_table', previewTable)
  end
end

-- write new values to table
function HeroSelection:UpdateTable (playerID, hero)
  local teamID = PlayerResource:GetTeam(playerID)
  DebugPrint("UpdateTable - Called with: " .. tostring(playerID) .. " = " .. tostring(hero))

  if not selectedtable[playerID] then
    selectedtable[playerID] = {}
  end

  if hero == "random" then
    DebugPrint("UpdateTable - Randoming a hero for playerID: "..tostring(playerID))
    if OAAOptions.settings.GAME_MODE == "SD" then
      hero = self:SingleDraftRandom(playerID)
    else
      hero = self:RandomHero(playerID)
    end

    -- Mark this player ID as a randomer
    selectedtable[playerID].didRandom = "true"
  elseif hero == "forcerandom" then
    DebugPrint("UpdateTable - Force Randoming a hero for playerID: "..tostring(playerID))
    if OAAOptions.settings.GAME_MODE == "SD" then
      hero = self:SingleDraftForceRandom(playerID)
    else
      hero = self:ForceRandomHero(playerID)
    end

    -- Mark this player ID as a randomer
    selectedtable[playerID].didRandom = "true"
  end

  if lockedHeroes[playerID] then
    DebugPrint("UpdateTable - Locking a hero for playerID: "..tostring(playerID))
    hero = lockedHeroes[playerID]
  end

  if selectedtable[playerID].selectedhero == hero then
    DebugPrint('UpdateTable - Player re-selected their hero again ' .. hero)
    return
  end

  if self:IsHeroChosen(hero) and hero ~= "empty" then
    DebugPrint('UpdateTable - Player selected a hero that is already chosen: ' .. hero)
    hero = "empty"
  end

  if self.isCM then
    if hero ~= "empty" then
      local cmFound = false
      for k, v in pairs(cmpickorder[teamID.."picks"])do
        if v == hero then
          table.remove(cmpickorder[teamID.."picks"], k)
          cmFound = true
        end
      end
      if not cmFound then
        DebugPrint('Couldnt find that hero in the CM pool ' .. tostring(hero))
        hero = "empty"
      end
    end
    -- if they've already selected a hero then unselect it
    if selectedtable[playerID].selectedhero ~= "empty" then
      table.insert(cmpickorder[teamID.."picks"], selectedtable[playerID].selectedhero)
    end
  end

  DebugPrint("UpdateTable - Updating select-table with a hero "..tostring(hero).." for playerID: "..tostring(playerID))

  selectedtable[playerID].selectedhero = hero
  selectedtable[playerID].team = teamID
  selectedtable[playerID].steamid = tostring(PlayerResource:GetSteamAccountID(playerID))

  -- if everyone has picked, stop
  local isanyempty = false
  for _, value in pairs(selectedtable) do
    if HeroSelection.isCM and value.steamid == "0" then
      value.selectedhero = HeroSelection:RandomHero()
    end
    if value.selectedhero == "empty" then
      isanyempty = true
    end
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'APdata', selectedtable)

  if isanyempty == false then
    forcestop = true
  end
end

function HeroSelection:HeroRerandom(event)
  local playerId = event.PlayerID
  if not selectedtable[playerId] or selectedtable[playerId].didRandom ~= "true" or rankedpickorder.phase ~= 'picking' then
    DebugPrint('Bad re-random')
    return
  end

  local player_name = tostring(event.player_name) --or tostring(PlayerResource:GetPlayerName(playerId))

  -- Get old randomed hero (SelectHero/assigning lockedHeroes happens after UpdateTable and after picking phase)
  local locked_hero = lockedHeroes[playerId] -- so this is probably nil
  if not locked_hero then
    locked_hero = selectedtable[playerId].selectedhero
  end

  -- Add old randomed hero to banned heroes
  table.insert(rankedpickorder.bans, locked_hero)
  CustomNetTables:SetTableValue('hero_selection', 'rankedData', rankedpickorder)

  -- Re-random new hero
  local new_hero
  if OAAOptions.settings.GAME_MODE == "SD" then
    new_hero = HeroSelection:SingleDraftRandom(playerId, locked_hero)
  else
    new_hero = HeroSelection:RandomHero(playerId)
  end

  -- Nullify hero tables
  selectedtable[playerId].selectedhero = "empty"
  selectedtable[playerId].didRandom = "rerandomed"
  lockedHeroes[playerId] = nil

  -- Update hero table
  HeroSelection:UpdateTable(playerId, new_hero)

  -- Send the 'Re-random' message to chat
  local player = PlayerResource:GetPlayer(playerId) or PlayerResource:FindFirstValidPlayer()
  CustomGameEventManager:Send_ServerToPlayer(player, 'oaa_random_hero_message', {
    player_name = player_name,
    hero = new_hero,
    picker_playerid = playerId,
    rerandom = 1,
  })
end
