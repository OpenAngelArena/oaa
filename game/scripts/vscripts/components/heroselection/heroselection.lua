if HeroSelection == nil then
  Debug.EnabledModules['heroselection:*'] = true
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

-- available heroes
local herolist = {}
local totalheroes = 0
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
  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', herolist)

  CustomGameEventManager:RegisterListener('hero_selected', Dynamic_Wrap(HeroSelection, 'HeroSelected'))
end

-- set "empty" hero for every player and start picking phase
function HeroSelection:StartSelection ()
  DebugPrint("Starting HeroSelection Process")
  DebugPrint(GetMapName())
  if GetMapName() == "oaa_captains_mode" then
    GameRules:SetPreGameTime(CM_GAME_TIME + 3)
    HeroSelection:RunTimer(CM_GAME_TIME)
  else
    GameRules:SetPreGameTime(AP_GAME_TIME + 3)
    HeroSelection:RunTimer(AP_GAME_TIME)
  end

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    HeroSelection:UpdateTable(playerID, "empty")
  end)

end

-- start heropick timer
function HeroSelection:RunTimer (time)
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
      PlayerResource:ReplaceHeroWith(key, selectedtable[key].selectedhero, 625, 0)
    end
    HeroSelection:StrategyTimer(3)
  else
    CustomNetTables:SetTableValue( 'hero_selection', 'time', {time = time, mode = "ALL PICK"})
    Timers:CreateTimer(1, function()
      HeroSelection:RunTimer(time -1)
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
  selectedtable[playerID] = {selectedhero = hero, team = teamID, steamid = PlayerResource:GetSteamAccountID(playerID)}

  DebugPrintTable(selectedtable)

  CustomNetTables:SetTableValue( 'hero_selection', 'data', selectedtable)

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
