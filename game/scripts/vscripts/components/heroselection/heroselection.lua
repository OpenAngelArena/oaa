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

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    DebugPrint(playerID)
    local teamID = PlayerResource:GetTeam(playerID)
    selectedtable[playerID] = {selectedhero = "empty", team = teamID, steamid = PlayerResource:GetSteamAccountID(playerID)}
  end)

  DebugPrintTable(selectedtable)

  CustomNetTables:SetTableValue( 'hero_selection', 'data', selectedtable)
end
