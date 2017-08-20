if HeroSelection == nil then
  Debug.EnabledModules['heroselection:*'] = true
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

local selectedtable = {}

function HeroSelection:Init ()
  DebugPrint("Initializing HeroSelection")

  local allheroes = LoadKeyValues('scripts/npc/npc_heroes.txt')
  local herolist = {}
  for key,value in pairs(LoadKeyValues('scripts/npc/herolist.txt')) do
    if value == 1 then
      herolist[key] = allheroes[key].AttributePrimary
    end
  end
  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', herolist)

  CustomGameEventManager:RegisterListener('hero_selected', Dynamic_Wrap(HeroSelection, 'HeroSelected'))
end

function HeroSelection:StartSelection ()
  DebugPrint("Starting HeroSelection Process")

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    HeroSelection:UpdateTable(playerID, "empty")
  end)
end

function HeroSelection:HeroSelected (event)
  DebugPrint("Received Hero Pick")
  HeroSelection:UpdateTable(event.PlayerID, event.hero)
end

function HeroSelection:UpdateTable (playerID, hero)
  local teamID = PlayerResource:GetTeam(playerID)
  selectedtable[playerID] = {selectedhero = hero, team = teamID, steamid = PlayerResource:GetSteamAccountID(playerID)}

  DebugPrintTable(selectedtable)

  CustomNetTables:SetTableValue( 'hero_selection', 'data', selectedtable)
end
