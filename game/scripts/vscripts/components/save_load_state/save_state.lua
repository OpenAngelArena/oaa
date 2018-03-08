
SAVE_INTERVAL = 60

if GameStateLoadSave == nil then
  GameStateLoadSave = class({})
  ChatCommand:LinkCommand("-save", Dynamic_Wrap(GameStateLoadSave, "EnableSaveState"), GameStateLoadSave)
  ChatCommand:LinkCommand("-load", Dynamic_Wrap(GameStateLoadSave, "LoadState"), GameStateLoadSave)
end

function GameStateLoadSave:EnableSaveState()
  if IsServer() then
    if not self.IsSaveSchedule then
      GameStateLoadSave:InitKillList()
      Timers:CreateTimer(SAVE_INTERVAL, function ()
        GameStateLoadSave:SaveState()
        return SAVE_INTERVAL
      end)

      GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
      self.IsSaveSchedule = true
    end

    GameStateLoadSave:SaveState()
  end
end

function GameStateLoadSave:InitKillList()
  if not self.KillList then
    self.KillList = {}
  end
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    if steamid then
      self.KillList[steamid] = {}
    end
  end
end

function GameStateLoadSave:HeroDeathHandler(keys)
  if IsServer() then
    local killerEntity = keys.killer
    local killedHero = keys.killed
    local killerTeam = killerEntity:GetTeamNumber()
    local killedTeam = killedHero:GetTeamNumber()
    if killerTeam == killedTeam then
      return
    end
    if killedHero:IsReincarnating() then
      return
    end
    if killerTeam == DOTA_TEAM_NEUTRALS or killedTeam == DOTA_TEAM_NEUTRALS then
      return
    end

    local killerSteamID = PlayerResource:GetSteamAccountID(killerEntity:GetPlayerOwnerID())
    local killedSteamID = PlayerResource:GetSteamAccountID(killedHero:GetPlayerOwnerID())

    if self.KillList[killerSteamID] == nil then
      self.KillList[killerSteamID] = {}
    end
    table.insert(self.KillList[killerSteamID], killedSteamID)
  end
end

function GameStateLoadSave:SaveState()
  if not self.KillList then
    self:InitKillList()
  end
  local newState = {}
  self:SaveGameTime(newState)
  self:SaveCave(newState)
  self:SaveHerosPicks(newState)
  self:SaveBossPitLvls(newState)
  self:SaveScore(newState)
  DevPrintTable(newState)
  return newState
end

function GameStateLoadSave:LoadState()
  if IsServer() then
    local state = GameStateLoadSave:SaveState()
    state.Heroes[53999591].HeroName = "npc_dota_hero_axe"
    state.Heroes[53999591].XP = 1600
    self:LoadCave(state)
    self:LoadHerosPicks(state)
    self:LoadBossPitLvls(state)
    self:LoadScore(state)
    self:LoadGameTime(state)

    print("@@@@@@@@@@@@@@@")
    print(json.encode(state))
    DevPrintTable( json.decode(json.encode(state)))
  end
end

function GameStateLoadSave:SaveHerosPicks(newState)
  newState.Heroes = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      local heroTable = {}
      heroTable.SteamId = steamid
      local hHero = player:GetAssignedHero()
      self:SaveHero(heroTable, hHero)
      newState.Heroes[steamid] = heroTable
    end
  end
end

function GameStateLoadSave:LoadHerosPicks(state)
  HeroSelection:Init()
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      local heroTable = state.Heroes[steamid]
      state.Heroes[steamid].CurrentPlayerId = playerID
      PlayerResource:ClearKillsMatrix( playerID )
    end
  end
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      local heroTable = state.Heroes[steamid]
      PrecacheUnitByNameAsync(heroTable.HeroName, function() end)
      HeroSelection:GiveStartingHero(playerID, "npc_dota_hero_dummy_dummy")
      HeroSelection:GiveStartingHero(playerID, heroTable.HeroName)
      self:LoadHero(state,heroTable, PlayerResource:GetSelectedHeroEntity(playerID))
    end
  end
end

function GameStateLoadSave:SaveHero(heroTable, hHero)
  heroTable.HeroName = hHero:GetUnitName()
  heroTable.XP = hHero:GetCurrentXP()
  heroTable.Gold = hHero:GetGold()
  heroTable.AbilityPoits = hHero:GetAbilityPoints()
  self:SaveHeroKDA(heroTable, hHero)
  self:SaveHeroAbilities(heroTable, hHero)
  self:SaveHeroItems(heroTable, hHero)
end

function GameStateLoadSave:LoadHero(state, heroTable, hHero)
  self:LoadHeroXP(heroTable, hHero)

  Timers:CreateTimer(0.2, function()
    self:LoadHeroAbilities(heroTable, hHero)
  end)

  hHero:SetGold(heroTable.Gold, true)
  self:LoadHeroItems(heroTable, hHero)
  --self:LoadHeroKDA(state, heroTable, hHero)
  -- self:SaveHeroItems(heroTable, hHero)
end

function GameStateLoadSave:LoadHeroXP(heroTable, hHero)

  hHero:AddExperience( heroTable.XP, DOTA_ModifyXP_Unspecified, false, false )
end

function GameStateLoadSave:SaveHeroKDA(heroTable, hHero)
  heroTable.KDA = {}
  heroTable.KDA.Kills = self.KillList[heroTable.SteamId]
  heroTable.KDA.Deaths = hHero:GetDeaths()
  heroTable.KDA.Assists = hHero:GetAssists()
end

function GameStateLoadSave:LoadHeroKDA(state, heroTable, hHero)
  -- for _,victimSteamId in pairs(heroTable.KDA.Kills) do
  --   local victimPlayerId = state.Heroes[victimSteamId].CurrentPlayerId
  --   PlayerResource:IncrementKills( heroTable.CurrentPlayerId, victimPlayerId )
  --   PlayerResource:IncrementDeaths( victimPlayerId, heroTable.CurrentPlayerId )
  -- end
  -- for lvl = 1, heroTable.KDA.Assists, 1 do
  --   hHero:IncrementAssists( heroTable.CurrentPlayerId )
  -- end
end

function GameStateLoadSave:SaveHeroAbilities(heroTable, hHero)
  heroTable.Abilities = {}
  for index = 0, hHero:GetAbilityCount()-1, 1 do
    local hAbility = hHero:GetAbilityByIndex( index )
    if hAbility then
      local ability = {}
      ability.Index = index
      ability.Name = hAbility:GetAbilityName( )
      ability.Lvl = hAbility:GetLevel( )
      heroTable.Abilities[index] = ability
    end
  end
end

function GameStateLoadSave:LoadHeroAbilities(heroTable, hHero)
  for index,tableAbility in pairs(heroTable.Abilities) do
    local hAbility = hHero:GetAbilityByIndex(index)
    if hAbility:GetAbilityName( ) == tableAbility.Name then
      for lvl = 1, tableAbility.Lvl, 1 do
        hAbility:UpgradeAbility( false )
      end
    end
  end
  hHero:SetAbilityPoints(heroTable.AbilityPoits)
end

function GameStateLoadSave:SaveHeroItems(heroTable, hHero)
  heroTable.Items = {}
  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hHero:GetItemInSlot(i)
    if item ~= nil then
      heroTable.Items[i] = item:GetName()
    end
  end
end

function GameStateLoadSave:LoadHeroItems(heroTable, hHero)
  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hHero:GetItemInSlot(i)
    if item ~= nil then
      hHero:TakeItem(item)
    end
    hHero:AddItemByName( heroTable.Items[i] )
  end
end

function GameStateLoadSave:SaveCave(newState)
  newState.Caves = CaveHandler:GetCaveClears()
end

function GameStateLoadSave:LoadCave(newState)
  -- TODO: clear current creeps and respawn
  CaveHandler:SetCaveClears(newState.Caves)
end

function GameStateLoadSave:SaveGameTime(newState)
  newState.GameTime = HudTimer:GetGameTime()
end

function GameStateLoadSave:LoadGameTime(newState)
  HudTimer:SetGameTime(newState.GameTime)
end

function GameStateLoadSave:SaveBossPitLvls(newState)
  newState.BossPits = {}
  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    local boss = bossPit:GetAbsOrigin()
    local vectorStr = "[ " .. boss.x .. " , " .. boss.y .. " , " .. boss.z .. " ]"
    newState.BossPits[vectorStr] = bossPit.killCount
  end
end

function GameStateLoadSave:LoadBossPitLvls(newState)
  -- TODO: clear current Bosses and respawn
end

function GameStateLoadSave:SaveScore(newState)
  newState.Score = {}
  newState.Score[DOTA_TEAM_GOODGUYS]= PointsManager:GetPoints(DOTA_TEAM_GOODGUYS)
  newState.Score[DOTA_TEAM_BADGUYS]= PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
end

function GameStateLoadSave:LoadScore(newState)
  PointsManager:SetPoints(DOTA_TEAM_GOODGUYS, newState.Score[DOTA_TEAM_GOODGUYS])
  PointsManager:SetPoints(DOTA_TEAM_BADGUYS, newState.Score[DOTA_TEAM_BADGUYS])
end
