LinkLuaModifier("modifier_out_of_duel", "modifiers/modifier_out_of_duel.lua", LUA_MODIFIER_MOTION_NONE)

Debug:EnableDebugging()

if HeroSelection == nil then
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

HERO_SELECTION_WHILE_PAUSED = false

-- available heroes
local herolist = {}
local lockedHeroes = {}
local loadedHeroes = {}
local totalheroes = 0

local cmtimer = nil
local rankedTimer = nil

-- storage for this game picks
local selectedtable = {}
-- force stop handle for timer, when all picked before time end
local forcestop = false
local LoadFinishEvent = Event()
local loadingHeroes = 1
local finishedLoading = false

LoadFinishEvent.listen(function()
  finishedLoading = true
end)

-- list all available heroes and get their primary attrs, and send it to client
function HeroSelection:Init ()
  Debug.EnabledModules['heroselection:*'] = false
  DebugPrint("Initializing HeroSelection")
  self.isCM = GetMapName() == "captains_mode"
  self.isARDM = GetMapName() == "ardm"
  self.is10v10 = GetMapName() == "10v10"
  self.isRanked = GetMapName() == "oaa" or GetMapName() == "oaa_winter"
  self.isUnranked = false
  self.spawnedHeroes = {}
  self.spawnedPlayers = {}
  self.attemptedSpawnPlayers = {}


  local herolistFile = 'scripts/npc/herolist.txt'

  if self.isCM then
    herolistFile = 'scripts/npc/herolist_cm.txt'
  end
  if self.isARDM then
    herolistFile = 'scripts/npc/herolist_ardm.txt'
  end
  if self.is10v10 then
    herolistFile = 'scripts/npc/herolist_10v10.txt'
  end
  if self.isRanked or self.isUnranked then
    self.isBanning = true
  end

  local allheroes = LoadKeyValues('scripts/npc/npc_heroes.txt')
  local heroAbilities = {}
  for key,value in pairs(LoadKeyValues(herolistFile)) do
    DebugPrint("Heroes: ".. key)
    if allheroes[key] == nil then -- Cookies: If the hero is not in vanilla file, load custom KV's
      DebugPrint(key .. " is not in vanilla file!")
      local data = {}
      if key == "npc_dota_hero_electrician" then
        data = LoadKeyValues('scripts/npc/heroes/chatterjee.txt')
      elseif key == "npc_dota_hero_sohei" then
        data = LoadKeyValues('scripts/npc/heroes/sohei.txt')
      end

      if data and data[key] then
        allheroes[key] = data[key]
      end
    end
    if value == 1 then
      if not heroAbilities[allheroes[key].AttributePrimary] then
        heroAbilities[allheroes[key].AttributePrimary] = {}
      end
      heroAbilities[allheroes[key].AttributePrimary][key] = {
        allheroes[key].Ability1,
        allheroes[key].Ability2,
        allheroes[key].Ability3,
        allheroes[key].Ability4,
        allheroes[key].Ability5,
        allheroes[key].Ability6,
        allheroes[key].Ability7,
        allheroes[key].Ability8,
        allheroes[key].Ability9
      }
      herolist[key] = allheroes[key].AttributePrimary
      totalheroes = totalheroes + 1
      assert(key ~= FORCE_PICKED_HERO, "FORCE_PICKED_HERO cannot be a pickable hero")
    end
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', {gametype = GetMapName(), herolist = herolist})
  for attr,data in pairs(heroAbilities) do
    CustomNetTables:SetTableValue( 'hero_selection', 'abilities_' .. attr, data)
  end

  GameEvents:OnHeroInGame(function (npc)
    local playerId = npc:GetPlayerID()
    DebugPrint('An NPC spawned ' .. npc:GetUnitName())
    DebugPrint('Giving player' .. tostring(playerId)  .. ' starting hero ' .. npc:GetUnitName())
    HeroCosmetics:ApplySelectedArcana(npc, HeroSelection:GetSelectedArcanaForPlayer(playerId)[npc:GetUnitName()])
  end)

  GameEvents:OnHeroSelection(function (keys)
    Debug:EnableDebugging()
    if self.isARDM and ARDMMode then
      -- if it's ardm, show strategy screen right away,
      -- lock in all heroes to initial random heroes
      HeroSelection:StrategyTimer(3)
      PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
        lockedHeroes[playerID] = ARDMMode:GetRandomHero(PlayerResource:GetTeam(playerID))
      end)
      -- once ardm is done precaching, replace all the heroes, then fire off the finished loading event
      ARDMMode:OnPrecache(function ()
        DebugPrint('Precache finished! Woohoo!')
        PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
          DebugPrint('Giving player' .. tostring(playerID)  .. ' starting hero ' .. lockedHeroes[playerID])
          HeroSelection:GiveStartingHero(playerID, lockedHeroes[playerID])
        end)
        LoadFinishEvent.broadcast()
      end)
    else
      print("START HERO SELECTION")
      HeroSelection:StartSelection()
    end
  end)

  GameEvents:OnPlayerReconnect(function (keys)
    -- [VScript] [components\duels\duels:64] PlayerID: 1
    -- [VScript] [components\duels\duels:64] name: Minnakht
    -- [VScript] [components\duels\duels:64] networkid: [U:1:53917791]
    -- [VScript] [components\duels\duels:64] reason: 2
    -- [VScript] [components\duels\duels:64] splitscreenplayer: -1
    -- [VScript] [components\duels\duels:64] userid: 3
    -- [VScript] [components\duels\duels:64] xuid: 76561198014183519
    if not lockedHeroes[keys.PlayerID] then
      -- we don't care if they haven't locked in yet
      return
    end
    local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
    if not hero or hero:GetUnitName() == FORCE_PICKED_HERO and loadedHeroes[lockedHeroes[keys.PlayerID]] then
      DebugPrint('Giving player ' .. keys.PlayerID .. ' ' .. lockedHeroes[keys.PlayerID])
      HeroSelection:GiveStartingHero(keys.PlayerID, lockedHeroes[keys.PlayerID])
    end
  end)

  if self.isARDM and ARDMMode then
    ARDMMode:Init(herolist)
  end
end

-- set "empty" hero for every player and start picking phase
function HeroSelection:StartSelection ()
  DebugPrint("Starting HeroSelection Process")
  DebugPrint(GetMapName())

  HeroSelection.shouldBePaused = true
  HeroSelection:CheckPause()

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    HeroSelection:UpdateTable(playerID, "empty")
  end)
  CustomGameEventManager:RegisterListener('cm_become_captain', Dynamic_Wrap(HeroSelection, 'CMBecomeCaptain'))
  CustomGameEventManager:RegisterListener('cm_hero_selected', Dynamic_Wrap(HeroSelection, 'CMManager'))
  CustomGameEventManager:RegisterListener('hero_selected', Dynamic_Wrap(HeroSelection, 'HeroSelected'))
  CustomGameEventManager:RegisterListener('preview_hero', Dynamic_Wrap(HeroSelection, 'HeroPreview'))
  CustomGameEventManager:RegisterListener('bottle_selected', Dynamic_Wrap(HeroSelection, 'OnBottleSelected'))
  CustomGameEventManager:RegisterListener('arcana_selected', Dynamic_Wrap(HeroSelection, 'OnArcanaSelected'))

  if self.isCM then
    HeroSelection:CMManager(nil)
  elseif self.isBanning then
    HeroSelection:RankedManager(nil)
  else
    HeroSelection:APTimer(0, "ALL PICK")
  end

  HeroSelection:BuildBottlePass()
end

function HeroSelection:BuildBottlePass()
  -- Ideally the bottle info would be moved to the server with {steamId, {List of bottles}}
  local special_bottles = {}
  local special_arcanas = {}
  HeroSelection.SelectedBottle = {}
  HeroSelection.SelectedArcana = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)

    if SPECIAL_BOTTLES[steamid] then
      special_bottles[playerID] = { SteamId = steamid, PlayerId = playerID, Bottles = SPECIAL_BOTTLES[steamid]}
      HeroSelection.SelectedBottle[playerID] = SPECIAL_BOTTLES[steamid][#(SPECIAL_BOTTLES[steamid])]
    end
    if SPECIAL_ARCANAS[steamid] then
      special_arcanas[playerID] = { SteamId = steamid, PlayerId = playerID, Arcanas = SPECIAL_ARCANAS[steamid]}
      table.insert(special_arcanas[playerID].Arcanas, 'RockElectrician')
      if SPECIAL_BOTTLES[steamid] then
        table.insert(special_arcanas[playerID].Arcanas, 'PepsiSohei')
      end
    end
  end

  -- Populate table with playerIds and list of bottles/arcanas for players
  CustomNetTables:SetTableValue( 'bottlepass', 'special_bottles', special_bottles )
  CustomNetTables:SetTableValue( 'bottlepass', 'special_arcanas', special_arcanas )
end


function HeroSelection:OnBottleSelected (selectedBottle)
  if HeroSelection.SelectedBottle == nil then HeroSelection.SelectedBottle = {} end
  HeroSelection.SelectedBottle[selectedBottle.PlayerID] = selectedBottle.BottleId
  CustomNetTables:SetTableValue( 'bottlepass', 'selected_bottles', HeroSelection.SelectedBottle )
end

function HeroSelection:OnArcanaSelected (selectedArcana)
  if HeroSelection.SelectedArcana == nil then HeroSelection.SelectedArcana = {} end
  if HeroSelection.SelectedArcana[selectedArcana.PlayerID] == nil then HeroSelection.SelectedArcana[selectedArcana.PlayerID] = {} end
  HeroSelection.SelectedArcana[selectedArcana.PlayerID][selectedArcana.Hero] = selectedArcana.Arcana
  CustomNetTables:SetTableValue( 'bottlepass', 'selected_arcanas', HeroSelection.SelectedArcana )
end

function HeroSelection:GetSelectedBottleForPlayer(playerId)
  if HeroSelection.SelectedBottle == nil then HeroSelection.SelectedBottle = {} end
  return HeroSelection.SelectedBottle[playerId] or 0
end

function HeroSelection:GetSelectedArcanaForPlayer(playerId)
  if HeroSelection.SelectedArcana == nil then HeroSelection.SelectedArcana = {} end
  return HeroSelection.SelectedArcana[playerId] or {}
end

function HeroSelection:RankedManager (event)
  -- unranked uses regular picking screen
  if self.isUnranked then return end
  local function save ()
    CustomNetTables:SetTableValue( 'hero_selection', 'rankedData', rankedpickorder)
  end
  if event == nil then
    -- start
    save()
    return self:RankedTimer(RANKED_PREGAME_TIME, "PRE-GAME")
  end

  -- phases!
  if rankedpickorder.phase == 'strategy' then
    return
  end
  if rankedpickorder.phase == 'start' then
    if event.isTimeout then
      rankedpickorder.phase = 'bans'
      save()
      return self:RankedTimer(RANKED_BAN_TIME, "BAN HEROES")
    else
      DebugPrint('Event during ranked start phase, that makes no sense!')
    end
  end
  if rankedpickorder.phase == 'bans' then
    -- end banning phase
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
      for _,a in pairs(rankedpickorder.banChoices) do
        banCount = banCount + 1
      end
      if PlayerResource:GetAllTeamPlayerIDs():length() == banCount then
        event.isTimeout = true
      else
        return
      end
    end
    if event.isTimeout then
      rankedpickorder.phase = 'picking'
      rankedpickorder.currentOrder = 1
      self:ChooseBans()
      save()
      return self:RankedTimer(RANKED_PICK_TIME, "PICK")
    end
  end
  if rankedpickorder.phase == 'picking' then
    if forcestop or not rankedpickorder.order[rankedpickorder.currentOrder] then
      rankedpickorder.phase = 'strategy'
      save()
      return HeroSelection:APTimer(0)
    end
    local choice = event.hero
    if event.isTimeout then
      DebugPrint('Timeout hero pick, randoming...')
      choice = 'forcerandom'
      DebugPrint('Checking out this team ' .. rankedpickorder.order[rankedpickorder.currentOrder].team)
      PlayerResource:GetPlayerIDsForTeam(rankedpickorder.order[rankedpickorder.currentOrder].team):foreach(function (playerID)
        if not selectedtable[playerID] or selectedtable[playerID].selectedhero == 'empty' then
          DebugPrint('Trying ' .. playerID)
          if not event.PlayerID or RandomInt(0, 2) == 0 then
            event.PlayerID = playerID
          end
        else
          DebugPrint('Cant random because he selected ' .. playerID .. ' / ' .. selectedtable[playerID].selectedhero)
        end
      end)
    end
    if not event.PlayerID then
      DebugPrint('How are there no players for this thing?')
      rankedpickorder.currentOrder = rankedpickorder.currentOrder + 1
      save()
      return self:RankedTimer(RANKED_PICK_TIME, "PICK")
    end
    if choice == 'random' then
      choice = self:RandomHero()
    end
    if choice == 'forcerandom' then
      choice = self:ForceRandomHero(event.PlayerID)
    end
    DebugPrint('Picking step ' .. rankedpickorder.currentOrder)
    if rankedpickorder.order[rankedpickorder.currentOrder].team ~= PlayerResource:GetTeam(event.PlayerID) then
      -- wrong team
      DebugPrint("This pick is from the wrong team!");
      save()
      return
    end
    if selectedtable[event.PlayerID] and selectedtable[event.PlayerID].selectedhero ~= 'empty' then
      -- already picked a hero
      DebugPrint("This player slready selected!");
      save()
      return
    end
    rankedpickorder.order[rankedpickorder.currentOrder].hero = choice
    rankedpickorder.currentOrder = rankedpickorder.currentOrder + 1
    HeroSelection:UpdateTable(event.PlayerID, choice)
    save()
    return self:RankedTimer(RANKED_PICK_TIME, "PICK")
  end
  if forcestop then
    save()
    return HeroSelection:APTimer(0)
  end
end

function HeroSelection:ChooseBans ()
  local banCount = 0
  local goodBans = 0
  local badBans = 0
  local goodBanChoices = 0
  local badBanChoices = 0
  local playerIDs = {}

  for playerID,choice in pairs(rankedpickorder.banChoices) do
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

  DebugPrint('Choosing bans from ' .. totalChoices .. ' choices...')

  if totalChoices == 1 then
    if RandomInt(0, 1) == 0 then
      -- no bans! choose things!
      DebugPrint('Rolled 0, no bans!')
      return
    end
    for playerID,choice in pairs(rankedpickorder.banChoices) do
      rankedpickorder.bans[1] = choice
      DebugPrint('Only suggestion was ' .. choice)
    end
    return
  else
    local skippedBans = 0
    while banCount < totalChoices / 2 do
      local choiceNum = RandomInt(1, totalChoices - banCount - skippedBans)
      local playerID = playerIDs[choiceNum]
      table.remove(playerIDs, choiceNum)
      local team = PlayerResource:GetTeam(playerID)
      local canBan = true
      if team == DOTA_TEAM_BADGUYS then
        if badBans >= 3 then
          canBan = false
          DebugPrint('Not chosing this ban because we already choose ' .. badBans .. ' bad bans')
        end
        badBans = badBans + 1
      elseif team == DOTA_TEAM_GOODGUYS then
        if goodBans >= 3 then
          canBan = false
          DebugPrint('Not chosing this ban because we already choose ' .. goodBans .. ' good bans')
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
end

function HeroSelection:RankedTimer (time, message)
  HeroSelection:CheckPause()
  if forcestop == true or time < 0 then
    HeroSelection:RankedManager({hero = "forcerandom", isTimeout = true})
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
            if PlayerResource:GetConnectionState(PlayerID) == 2 then
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
      DebugPrintTable(event)
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

      DebugPrint('--')
      DebugPrintTable(event)

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
  if PlayerResource:GetTeam(event.PlayerID) == 2 then
    cmpickorder["captainradiant"] = event.PlayerID
    CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
    if not cmpickorder["captaindire"] == "empty" then
      HeroSelection:CMManager({dummy = "dummy"})
    end
  elseif PlayerResource:GetTeam(event.PlayerID) == 3 then
    cmpickorder["captaindire"] = event.PlayerID
    CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
    if not cmpickorder["captainradiant"] == "empty" then
      HeroSelection:CMManager({dummy = "dummy"})
    end
  end
end

-- start heropick AP timer
function HeroSelection:APTimer (time, message)
  print("APTimer")
  HeroSelection:CheckPause()
  if forcestop == true or time < 0 then
    for key, value in pairs(selectedtable) do
      if value.selectedhero == "empty" then
        -- if someone hasnt selected until time end, random for him
        if GetMapName() == "captains_mode" then
          HeroSelection:UpdateTable(key, cmpickorder[value.team.."picks"][1])
        else
          HeroSelection:UpdateTable(key, HeroSelection:ForceRandomHero(key))
        end
      end
      HeroSelection:SelectHero(key, selectedtable[key].selectedhero)
    end

    -- I don't understand this next chunk of code
    PlayerResource:GetAllTeamPlayerIDs():each(function (playerId)
      if not lockedHeroes[playerId] then
        if GetMapName() == "captains_mode" then
          HeroSelection:UpdateTable(playerId, cmpickorder[PlayerResource:GetTeam(playerId).."picks"][1])
        else
          HeroSelection:UpdateTable(playerId, HeroSelection:ForceRandomHero(playerId))
        end
      end
    end)

    loadingHeroes = loadingHeroes - 1
    -- just incase all the heroes load syncronously
    if loadingHeroes == 0 then
      LoadFinishEvent.broadcast()
    end
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
  lockedHeroes[playerId] = hero
  loadingHeroes = loadingHeroes + 1
  -- LoadFinishEvent
  PrecacheUnitByNameAsync(hero, function()
    loadedHeroes[hero] = true
    loadingHeroes = loadingHeroes - 1
    if loadingHeroes == 0 then
      LoadFinishEvent.broadcast()
    end
    local player = PlayerResource:GetPlayer(playerId)
    if player == nil then -- disconnected! don't give em a hero yet...
      return
    end
    self:GiveStartingHero(playerId, hero)
    DebugPrint('Giving player ' .. playerId .. ' ' .. hero)
  end)
end

function HeroSelection:GiveStartingHero (playerId, heroName)
  if self.spawnedPlayers[playerId] then
    return
  end
  local startingGold = 0
  if self.hasGivenStartingGold then
    startingGold = STARTING_GOLD
  end
  PlayerResource:GetPlayer(playerId):SetSelectedHero(heroName)

  local hero = PlayerResource:GetSelectedHeroEntity(playerId)
  self.spawnedPlayers[playerId] = true
  if hero == nil then
    Timers:CreateTimer(2, function ()
      local loadedHero = PlayerResource:GetSelectedHeroEntity(playerId)
      if not loadedHero then
        return 2
      end
      HeroCosmetics:ApplySelectedArcana(loadedHero, HeroSelection:GetSelectedArcanaForPlayer(playerId)[loadedHero:GetUnitName()])
    end)
    return
  end
end

function HeroSelection:IsHeroDisabled (hero)
  if self.isCM then
    for _,data in ipairs(cmpickorder["order"]) do
      if hero == data.hero then
        return true
      end
    end
  elseif self.isBanning then
    for _,bannedHero in pairs(rankedpickorder.bans) do
      if hero == bannedHero then
        return true
      end
    end
    for _,data in pairs(rankedpickorder.order) do
      if hero == data.hero then
        return true
      end
    end
  else
    for _,data in pairs(selectedtable) do
      if hero == data.selectedhero then
        return true
      end
    end
  end
  return false
end

function HeroSelection:IsHeroChosen (hero)
  for _,data in pairs(selectedtable) do
    if hero == data.selectedhero then
      return true
    end
  end
  return false
end

function HeroSelection:ForceRandomHero (playerId)
  if not playerId then
    return HeroSelection:RandomHero()
  end
  local previewTable = CustomNetTables:GetTableValue('hero_selection', 'preview_table') or {}
  local team = tostring(PlayerResource:GetTeam(playerId))
  local steamid = HeroSelection:GetSteamAccountID(playerId)
  DebugPrint("Force random for " .. playerId .. " on team " .. team)
  if previewTable[team] and previewTable[team][steamid] and not HeroSelection:IsHeroDisabled(previewTable[team][steamid]) then
    return previewTable[team][steamid]
  end

  DebugPrint("Bad preview hero, falling back to normal random")
  return HeroSelection:RandomHero()
end

function HeroSelection:RandomHero ()
  while true do
    local choice = HeroSelection:UnsafeRandomHero()
    if not self:IsHeroDisabled(choice) then
      return choice
    end
  end
end

function HeroSelection:UnsafeRandomHero ()
  local curstate = 0
  local rndhero = RandomInt(0, totalheroes - 1)
  for name, _ in pairs(herolist) do
    if curstate == rndhero then
      return name
    end
    curstate = curstate + 1
  end
end

-- start strategy timer
function HeroSelection:EndStrategyTime ()
  HeroSelection.shouldBePaused = false
  HeroSelection:CheckPause()

  -- GameRules:SetTimeOfDay(0.25)

  if self.isCM then
    PauseGame(true)
  end

  GameMode:OnGameInProgress()
  OnGameInProgressEvent()

  self.hasGivenStartingGold = true
  for _,hero in ipairs(self.spawnedHeroes) do
    Gold:SetGold(hero, STARTING_GOLD)
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = -1, mode = ""})
end

function HeroSelection:StrategyTimer (time)
  HeroSelection:CheckPause()
  if time < 0 then
    if finishedLoading then
      HeroSelection:EndStrategyTime()
    else
      LoadFinishEvent.listen(function()
        HeroSelection:EndStrategyTime()
      end)
    end
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = "STRATEGY"})
    Timers:CreateTimer({
      useGameTime = not HERO_SELECTION_WHILE_PAUSED,
      endTime = 1,
      callback = function()
        HeroSelection:StrategyTimer(time -1)
      end
    })
  end
end

-- receive choise from players about their selection
function HeroSelection:HeroSelected (event)
  DebugPrint("Received Hero Pick")
  DebugPrintTable(event)
  if not event.hero or event.hero == "empty" or (not HeroSelection.isCM and HeroSelection:IsHeroDisabled(event.hero)) then
    Debug:EnableDebugging()
    DebugPrint('Cheater...')
    return
  end
  if HeroSelection.isBanning then
    return HeroSelection:RankedManager(event)
  end
  HeroSelection:UpdateTable(event.PlayerID, event.hero)
end

function HeroSelection:HeroPreview (event)
  local previewTable = CustomNetTables:GetTableValue('hero_selection', 'preview_table') or {}
  local teamID = tostring(PlayerResource:GetTeam(event.PlayerID))
  if not previewTable[teamID] then
    previewTable[teamID] = {}
  end
  previewTable[teamID][HeroSelection:GetSteamAccountID(event.PlayerID)] = event.hero
  CustomNetTables:SetTableValue('hero_selection', 'preview_table', previewTable)
end

-- write new values to table
function HeroSelection:UpdateTable (playerID, hero)
  local teamID = PlayerResource:GetTeam(playerID)
  if hero == "random" then
    hero = self:RandomHero()
  end
  if hero == "forcerandom" then
    hero = self:ForceRandomHero(playerID)
  end

  if lockedHeroes[playerID] then
    hero = lockedHeroes[playerID]
  end

  if selectedtable[playerID] and selectedtable[playerID].selectedhero == hero then
    DebugPrint('Player re-selected their hero again ' .. hero)
    return
  end

  if self:IsHeroChosen(hero) then
    DebugPrint('That hero is already disabled ' .. hero)
    hero = "empty"
  end

  if GetMapName() == "captains_mode" then
    if hero ~= "empty" then
      local cmFound = false
      for k,v in pairs(cmpickorder[teamID.."picks"])do
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
    if selectedtable[playerID] and selectedtable[playerID].selectedhero ~= "empty" then
      table.insert(cmpickorder[teamID.."picks"], selectedtable[playerID].selectedhero)
    end
  end

  selectedtable[playerID] = {selectedhero = hero, team = teamID, steamid = HeroSelection:GetSteamAccountID(playerID)}

  -- DebugPrintTable(selectedtable)
  -- if everyone has picked, stop
  local isanyempty = false
  for key, value in pairs(selectedtable) do --pseudocode
    if GetMapName() ~= "captains_mode" and value.steamid == "0" then
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

local playerToSteamMap = {}
function HeroSelection:GetSteamAccountID(playerID)
  local steamid = PlayerResource:GetSteamAccountID(playerID)
  if steamid == 0 then
    if playerToSteamMap[playerID] then
      return playerToSteamMap[playerID]
    else
      steamid = #playerToSteamMap + 1
      playerToSteamMap[playerID] = tostring(steamid)
    end
  end
  return tostring(steamid)
end

function HeroSelection:ForceAssignHeroes()
	for nPlayerID = 0, ( DOTA_MAX_TEAM_PLAYERS - 1 ) do
		local hPlayer = PlayerResource:GetPlayer( nPlayerID )
		if hPlayer and not PlayerResource:HasSelectedHero( nPlayerID ) then
			hPlayer:MakeRandomHeroSelection()
		end
	end
end
