if HeroSelection == nil then
  Debug.EnabledModules['heroselection:*'] = true
  DebugPrint ( 'Starteng HeroSelection' )
  HeroSelection = class({})
end

local herotable = {herolist = {}, current = {}}

function HeroSelection:Init ()
  DebugPrint("Initializing HeroSelection")
  herotable.herolist = LoadKeyValues('scripts/npc/herolist.txt')

  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    DebugPrint(playerID)
    local teamID = PlayerResource:GetTeam(playerID)
    herotable.current ={[playerID] = {selectedhero = "empty", team = teamID, steamid = PlayerResource:GetSteamAccountID(playerID)}}
  end)

  DebugPrintTable(herotable)

  CustomNetTables:SetTableValue( 'hero_selection', 'data', herotable)
end
