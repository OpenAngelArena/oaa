if GameStateSave == nil then
  GameStateSave = class({})
  ChatCommand:LinkCommand("-save", Dynamic_Wrap(GameStateSave, "EnableSaveState"), GameStateSave)
end
SAVE_INTERVAL = 20

function GameStateSave:EnableSaveState()
  if IsServer() then
    if not self.IsSaveSchedule then
      GameStateSave:InitKillList()
      Timers:CreateTimer(SAVE_INTERVAL, function ()
        GameStateSave:SaveState()
        return SAVE_INTERVAL
      end)

      GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
      self.IsSaveSchedule = true
    end

    GameStateSave:SaveState()
    HudTimer:SetGameTime(6000)
    CreepCamps:SetPowerLevel(100)
  end

end

function GameStateSave:InitKillList()
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

function GameStateSave:HeroDeathHandler(keys)
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

function GameStateSave:SaveState()
  local newState = {}
  self:SaveCreeps(newState)
  self:SaveHerosPicks(newState)
  self:SaveBossPitLvls(newState)
  DevPrintTable(newState)
end

function GameStateSave:SaveHerosPicks(newState)
  newState.Heroes = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      local heroTable = {}
      heroTable.SteamId = steamid
      local hHero = player:GetAssignedHero()
      self:SaveHero(heroTable, hHero)
      newState.Heroes[heroTable.HeroName] = heroTable
    end
  end
end

function GameStateSave:SaveHero(heroTable, hHero)
  heroTable.HeroName = hHero:GetUnitName()
  heroTable.XP = hHero:GetCurrentXP()
  self:SaveHeroKDA(heroTable, hHero)
  self:SaveHeroAbilities(heroTable, hHero)
  self:SaveHeroItems(heroTable, hHero)
end

function GameStateSave:SaveHeroKDA(heroTable, hHero)
  heroTable.KDA = {}
  heroTable.KDA.Kills = self.KillList[heroTable.SteamId]
  heroTable.KDA.Deaths = hHero:GetDeaths()
  heroTable.KDA.Assists = hHero:GetAssists()
end

function GameStateSave:SaveHeroAbilities(heroTable, hHero)
  print('SaveHeroAbilities============')
  heroTable.abilities = {}
  for index = 0, hHero:GetAbilityCount()-1, 1 do
    local hAbility = hHero:GetAbilityByIndex( index )
    if hAbility then
      local ability = {}
      ability.Index = index
      ability.Name = hAbility:GetAbilityName( )
      ability.Lvl = hAbility:GetLevel( )
      heroTable.abilities[index] = ability
    end
  end
end

function GameStateSave:SaveHeroItems(heroTable, hHero)
  heroTable.Items = {}
  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hHero:GetItemInSlot(i)
    if item ~= nil then
      heroTable.Items[i] = item:GetName()
    end
  end
end


function GameStateSave:SaveCreeps(newState)
  print('SaveCreeps============')
  newState.CreepPower = CreepCamps:GetPowerLevel()
  newState.Caves = CaveHandler:GetCaveClears()
end

function GameStateSave:SaveGameTime(newState)
  print('SaveGameTime============')
  newState.GameTime = HudTimer:GetGameTime()
end

function GameStateSave:SaveBossPitLvls(newState)
  print('SaveBossPitLvls============')
  newState.BossPits = {}
  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    -- 1 index because lua is that person from the internet who doesn't look like their pictures
    local boss = bossPit:GetAbsOrigin()
    local vectorStr = "[ " .. boss.x .. " , " .. boss.y .. " , " .. boss.z .. " ]"
    newState.BossPits[vectorStr] = bossPit.killCount
  end
end
