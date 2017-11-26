LinkLuaModifier("modifier_out_of_duel", "modifiers/modifier_out_of_duel.lua", LUA_MODIFIER_MOTION_NONE)

if HeroSelection == nil then
  Debug.EnabledModules['heroselection:*'] = true
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

HERO_SELECTION_WHILE_PAUSED = false

-- available heroes
local herolist = {}
local totalheroes = 0

local cmtimer = nil

-- storage for this game picks
local selectedtable = {}
-- force stop handle for timer, when all picked before time end
local forcestop = false

-- list all available heroes and get their primary attrs, and send it to client
function HeroSelection:Init ()
  DebugPrint("Initializing HeroSelection")

  local allheroes = LoadKeyValues('scripts/npc/npc_heroes.txt')
  for key,value in pairs(LoadKeyValues('scripts/npc/herolist.txt')) do
    if value == 1 then
      herolist[key] = allheroes[key].AttributePrimary
      totalheroes = totalheroes + 1
    end
  end
  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', {gametype = GetMapName(), herolist = herolist})

  GameEvents:OnHeroInGame(function (npc)
    local playerId = npc:GetPlayerID()
    if selectedtable[playerId].selectedhero == "empty" then
      npc:AddNewModifier(nil, nil, "modifier_out_of_duel", nil)
    end
  end)

  GameEvents:OnPreGame(function (keys)
    HeroSelection:StartSelection()
  end)
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

  if GetMapName() == "oaa_captains_mode" then
    HeroSelection:CMManager(nil)
  else
    HeroSelection:APTimer(AP_GAME_TIME, "ALL PICK")
  end
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
      Timers:RemoveTimer(cmtimer)
      --random if not selected
      if event.hero == "random" then
        event.hero = HeroSelection:RandomHero()
      end

      if cmpickorder["order"][cmpickorder["currentstage"]].type == "Pick" then
        table.insert(cmpickorder[cmpickorder["order"][cmpickorder["currentstage"]].side.."picks"], 1, event.hero)
      end
      cmpickorder["order"][cmpickorder["currentstage"]].hero = event.hero
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      cmpickorder["currentstage"] = cmpickorder["currentstage"] + 1

      DebugPrintTable(cmpickorder)
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
function HeroSelection:CMTimer (time, message)
  HeroSelection:CheckPause()
  CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = message})

  if cmpickorder["currentstage"] > 0 and forcestop == false then
    if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_GOODGUYS and cmpickorder["captainradiant"] == "empty" then
      HeroSelection:CMManager({hero = "random"})
      return
    end

    if cmpickorder["order"][cmpickorder["currentstage"]].side == DOTA_TEAM_BADGUYS and cmpickorder["captaindire"] == "empty" then
      HeroSelection:CMManager({hero = "random"})
      return
    end
  end

  if time < 0 then
    HeroSelection:CMManager({hero = "random"})
    return
  end

  cmtimer = Timers:CreateTimer({
    useGameTime = not HERO_SELECTION_WHILE_PAUSED,
    endTime = 1,
    callback = function()
      HeroSelection:CMTimer(time -1, message)
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
  HeroSelection:CheckPause()
  if forcestop == true then
    for key, value in pairs(selectedtable) do
      HeroSelection:SelectHero(key, value.selectedhero)
    end
    HeroSelection:StrategyTimer(3)
  elseif time < 0 then
    for key, value in pairs(selectedtable) do
      if value.selectedhero == "empty" then
        -- if someone hasnt selected until time end, random for him
        if GetMapName() == "oaa_captains_mode" then
          HeroSelection:UpdateTable(key, cmpickorder[value.team.."picks"][1])
        else
          HeroSelection:UpdateTable(key, HeroSelection:RandomHero())
        end
      end
      HeroSelection:SelectHero(key, selectedtable[key].selectedhero)
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
  PrecacheUnitByNameAsync(hero, function()
    PlayerResource:ReplaceHeroWith(playerId, hero, STARTING_GOLD, 0)
  end)
end

function HeroSelection:RandomHero ()
  while true do
    local choice = HeroSelection:UnsafeRandomHero()
    local safe = true
    if GetMapName() == "oaa_captains_mode" then
      for _,data in ipairs(cmpickorder["order"]) do
        if choice == data.hero then
          safe = false
        end
      end
    else
      for _,data in pairs(selectedtable) do
        if choice == data.selectedhero then
          safe = false
        end
      end
    end
    if safe then
      return choice
    end
  end
end
function HeroSelection:UnsafeRandomHero ()
  local curstate = 0
  local rndhero = RandomInt(0, totalheroes)
  for name, _ in pairs(herolist) do
    if curstate == rndhero then
      return name
    end
    curstate = curstate + 1
  end
end

-- start strategy timer
function HeroSelection:StrategyTimer (time)
  HeroSelection:CheckPause()
  if time < 0 then
    HeroSelection.shouldBePaused = false
    HeroSelection:CheckPause()
    GameMode:OnGameInProgress()
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = ""})
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = "GAME STARTING"})
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
  HeroSelection:UpdateTable(event.PlayerID, event.hero)
end

-- write new values to table
function HeroSelection:UpdateTable (playerID, hero)
  local teamID = PlayerResource:GetTeam(playerID)
  if hero == "random" then
    hero = self:RandomHero()
  end
  selectedtable[playerID] = {selectedhero = hero, team = teamID, steamid = tostring(PlayerResource:GetSteamAccountID(playerID))}

  if GetMapName() == "oaa_captains_mode" then
    for k,v in pairs(cmpickorder[teamID.."picks"])do
      if v == hero then
        table.remove(cmpickorder[teamID.."picks"], k)
      end
    end
  end

  DebugPrintTable(selectedtable)
  -- if everyone has picked, stop
  local isanyempty = false
  for key, value in pairs(selectedtable) do --pseudocode
    if value.steamid == "0" then
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
