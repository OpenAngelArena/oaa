if HeroSelection == nil then
  Debug.EnabledModules['heroselection:*'] = true
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

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

end

-- set "empty" hero for every player and start picking phase
function HeroSelection:StartSelection ()
  DebugPrint("Starting HeroSelection Process")
  DebugPrint(GetMapName())

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    HeroSelection:UpdateTable(playerID, "empty")
  end)

  if GetMapName() == "oaa_captains_mode" then
    GameRules:SetPreGameTime(CM_GAME_TIME + 10)
    CustomGameEventManager:RegisterListener('cm_become_captain', Dynamic_Wrap(HeroSelection, 'CMBecomeCaptain'))
    CustomGameEventManager:RegisterListener('cm_hero_selected', Dynamic_Wrap(HeroSelection, 'CMManager'))
    HeroSelection:CMManager(nil)
  else
    GameRules:SetPreGameTime(AP_GAME_TIME + 3)
    CustomGameEventManager:RegisterListener('hero_selected', Dynamic_Wrap(HeroSelection, 'HeroSelected'))
    HeroSelection:APTimer(AP_GAME_TIME)
  end

end

-- start heropick CM timer
function HeroSelection:CMManager (event)

  if forcestop == false then
    forcestop = true

    if event == nil then
      DebugPrint("test")
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      HeroSelection:CMTimer(20, "CHOOSE CAPTAIN")

    elseif cmpickorder["currentstage"] == 0 then
      Timers:RemoveTimer(cmtimer)
      --set captani here
      if cmpickorder["captainradiant"] == "empty" then
        --random captain
      end
      if cmpickorder["captaindire"] == "empty" then
        --random captain
      end
      cmpickorder["currentstage"] = cmpickorder["currentstage"] + 1
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      HeroSelection:CMTimer(20, "CAPTAINS MODE")

    elseif cmpickorder["currentstage"] <= cmpickorder["totalstages"] then
      Timers:RemoveTimer(cmtimer)
      if event.hero == "random" then
        --random if not selected
      end
      cmpickorder["order"][cmpickorder["currentstage"]].hero = event.hero
      CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      cmpickorder["currentstage"] = cmpickorder["currentstage"] + 1
      if cmpickorder["currentstage"] <= cmpickorder["totalstages"] then
        HeroSelection:CMTimer(20, "CAPTAINS MODE")
      else
        --start selection of selected
        CustomNetTables:SetTableValue( 'hero_selection', 'CMdata', cmpickorder)
      end
    end
    forcestop = false

  end
end

-- manage cm timer
function HeroSelection:CMTimer (time, message)
  if time < 0 then
    HeroSelection:CMManager({hero = "random"})
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = message})
    cmtimer = Timers:CreateTimer(1, function()
      HeroSelection:CMTimer(time -1, message)
    end)
  end
end

-- become a captain, go to next stage, if both captains are selected
function HeroSelection:CMBecomeCaptain (event)
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
function HeroSelection:APTimer (time)
  if forcestop == true then
    for key, value in pairs(selectedtable) do
      PlayerResource:ReplaceHeroWith(key, value.selectedhero, 625, 0)
    end
    HeroSelection:StrategyTimer(3)
  elseif time < 0 then
    for key, value in pairs(selectedtable) do
      if value.selectedhero == "empty" then
        -- if someone hasnt selected until time end, random for him
        local curstate = 0
        local rndhero = RandomInt(0, totalheroes)
        for name, _ in pairs(herolist) do
          if curstate == rndhero then
            HeroSelection:UpdateTable(key, name)
          end
          curstate = curstate + 1
        end
      end
      PlayerResource:ReplaceHeroWith(key, selectedtable[key].selectedhero, STARTING_GOLD, 0)
    end
    HeroSelection:StrategyTimer(3)
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = "ALL PICK"})
    Timers:CreateTimer(1, function()
      HeroSelection:APTimer(time -1)
    end)
  end
end

-- start strategy timer
function HeroSelection:StrategyTimer (time)
  if time < 0 then
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = ""})
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = "GAME STARTING"})
    Timers:CreateTimer(1, function()
      HeroSelection:StrategyTimer(time -1)
    end)
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
  selectedtable[playerID] = {selectedhero = hero, team = teamID, steamid = tostring(PlayerResource:GetSteamAccountID(playerID))}

  DebugPrintTable(selectedtable)

  CustomNetTables:SetTableValue( 'hero_selection', 'APdata', selectedtable)

  -- if everyone has picked, stop
  local isanyempty = false
  for key, value in pairs(selectedtable) do --pseudocode
    if value.selectedhero == "empty" then
      isanyempty = true
    end
  end
  if isanyempty == false then
    forcestop = true
  end

end
