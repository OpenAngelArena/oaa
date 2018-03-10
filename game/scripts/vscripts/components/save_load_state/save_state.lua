
SAVE_INTERVAL = 60

if GameStateLoadSave == nil then
  GameStateLoadSave = class({})
  ChatCommand:LinkCommand("-save", Dynamic_Wrap(GameStateLoadSave, "EnableSaveState"), GameStateLoadSave)
  ChatCommand:LinkCommand("-load", Dynamic_Wrap(GameStateLoadSave, "LoadState"), GameStateLoadSave)
end

function GameStateLoadSave:Init()
  GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
end

function GameStateLoadSave:EnableSaveState()
  if IsServer() then
    if not self.IsSaveSchedule then
      GameStateLoadSave:InitKillList()
      Timers:CreateTimer(SAVE_INTERVAL, function ()
        GameStateLoadSave:SaveState()
        return SAVE_INTERVAL
      end)

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
  return newState
end

function GameStateLoadSave:LoadState()
  if IsServer() then

    local state = GameStateLoadSave:SaveState()
    local loadState = json.decode(json.encode(state), 1, nil)

    self:LoadCave(loadState)
    self:LoadHerosPicks(loadState)
    self:LoadBossPitLvls(loadState)
    self:LoadScore(loadState)
    self:LoadGameTime(loadState)

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

function GameStateLoadSave:SaveHeroKDA(heroTable, hHero)
  heroTable.KDA = {}
  heroTable.KDA.KillList = self.KillList[heroTable.SteamId]
  heroTable.KDA.Kills = hHero:GetKills()
  heroTable.KDA.Deaths = hHero:GetDeaths()
  heroTable.KDA.Assists = hHero:GetAssists()
end

function GameStateLoadSave:LoadHeroKDA(state, heroTable, hHero)
  for _,victimSteamId in pairs(heroTable.KDA.KillList) do
    if hHero:GetKills() < heroTable.KDA.Kills then
      local victimPlayerId = state.Heroes[victimSteamId].CurrentPlayerId
      PlayerResource:IncrementKills( heroTable.CurrentPlayerId, victimPlayerId )
    end
  end

  for lvl = 1, heroTable.KDA.Assists, 1 do
    if hHero:GetAssists() < heroTable.KDA.Assists then
      hHero:IncrementAssists( heroTable.CurrentPlayerId )
    end
  end

  for lvl = 1, heroTable.KDA.Deaths, 1 do
    if hHero:GetDeaths() < heroTable.KDA.Deaths then
      hHero:IncrementDeaths( heroTable.CurrentPlayerId )
    end
  end
end


function GameStateLoadSave:LoadHerosPicks(state)
  HeroSelection:Init()
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      state.Heroes[tostring(steamid)].CurrentPlayerId = playerID
      PlayerResource:ClearKillsMatrix( playerID )
    end
  end
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = PlayerResource:GetSteamAccountID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      if steamid ~= 0 then
        -- Precache the new hero
        PrecacheUnitByNameAsync(state.Heroes[tostring(steamid)].HeroName, function() end)
        HeroSelection:GiveStartingHero(playerID, "npc_dota_hero_dummy_dummy")
        HeroSelection:GiveStartingHero(playerID, state.Heroes[tostring(steamid)].HeroName)
        self:LoadHero(state,state.Heroes[tostring(steamid)], PlayerResource:GetSelectedHeroEntity(playerID))
      end
    end
  end
end

function GameStateLoadSave:SaveHero(heroTable, hHero)
  heroTable.HeroName = hHero:GetUnitName()
  heroTable.XP = hHero:GetCurrentXP()
  heroTable.Gold = hHero:GetGold()
  heroTable.AbilityPoits = hHero:GetAbilityPoints()

  self:SaveHeroAbilities(heroTable, hHero)
  self:SaveHeroItems(heroTable, hHero)
  self:SaveHeroKDA(heroTable, hHero)
end

function GameStateLoadSave:LoadHero(state, heroTable, hHero)
  self:LoadHeroXP(heroTable, hHero)

  -- loading the abilities in the same frame is causing
  -- the modifiers to fail when applied
  Timers:CreateTimer(0.2, function()
    self:LoadHeroAbilities(heroTable, hHero)
  end)

  hHero:SetGold(heroTable.Gold, true)
  self:LoadHeroItems(heroTable, hHero)
  self:LoadHeroKDA(state, heroTable, hHero)

  -- Delay the modifiers setup for a second
  Timers:CreateTimer(1, function()
    self:LoadHeroAbilitiesModifiers(heroTable, hHero)
  end)
end

function GameStateLoadSave:LoadHeroXP(heroTable, hHero)
  hHero:AddExperience( heroTable.XP, DOTA_ModifyXP_Unspecified, false, false )
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
  self:SaveHeroAbilitiesModifiers(heroTable, hHero)
end

function GameStateLoadSave:LoadHeroAbilities(heroTable, hHero)
  for index,tableAbility in pairs(heroTable.Abilities) do
    local hAbility = hHero:GetAbilityByIndex(tonumber(index))
    if hAbility:GetAbilityName( ) == tableAbility.Name then
      if hAbility:IsAttributeBonus() and tableAbility.Lvl>0 then
        -- Refunding the Ability Points for talents because setting talent level does not update properly
        heroTable.AbilityPoits = heroTable.AbilityPoits + 1
      else
        hAbility:SetLevel( tableAbility.Lvl )
      end
    end
  end
  hHero:SetAbilityPoints(heroTable.AbilityPoits)
end

function GameStateLoadSave:SaveHeroAbilitiesModifiers(heroTable, hHero)
  heroTable.Modifiers = {}
  if hHero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ) then
    heroTable.Modifiers['modifier_legion_commander_duel_damage_boost'] = hHero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ):GetStackCount()
  end
  if hHero:FindModifierByName('modifier_oaa_int_steal' ) then
    heroTable.Modifiers['modifier_oaa_int_steal'] = hHero:FindModifierByName('modifier_oaa_int_steal' ):GetStackCount()
  end
  if hHero:FindModifierByName('modifier_pudge_flesh_heap' ) then
    heroTable.Modifiers['modifier_pudge_flesh_heap'] = hHero:FindModifierByName('modifier_pudge_flesh_heap' ):GetStackCount()
  end
end

function GameStateLoadSave:LoadHeroAbilitiesModifiers(heroTable, hHero)

  if hHero:HasAbility( 'legion_commander_duel' ) then
    if not hHero:HasModifier('modifier_legion_commander_duel_damage_boost' ) then
      hHero:AddNewModifier( hHero, hHero:FindAbilityByName('legion_commander_duel'), 'modifier_legion_commander_duel_damage_boost', {} )
    end
    hHero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ):SetStackCount(heroTable.Modifiers['modifier_legion_commander_duel_damage_boost'])
  end
  if hHero:HasModifier('modifier_oaa_int_steal' ) then
    hHero:FindModifierByName('modifier_oaa_int_steal' ):SetStackCount(heroTable.Modifiers['modifier_oaa_int_steal'])
  end
  if hHero:HasModifier('modifier_pudge_flesh_heap' ) then
    -- Not Working. But is should!
    hHero:FindModifierByName('modifier_pudge_flesh_heap' ):SetStackCount(heroTable.Modifiers['modifier_pudge_flesh_heap'])
  end
end

function GameStateLoadSave:SaveHeroItems(heroTable, hHero)
  heroTable.Items = {}
  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hHero:GetItemInSlot(i)
    if item ~= nil then
      heroTable.Items[i] = {}
      heroTable.Items[i]['Name'] = item:GetName()
      if item.GetCurrentCharges then
        heroTable.Items[i]['Charges'] = item:GetCurrentCharges()
      end
    end
  end
end

function GameStateLoadSave:LoadHeroItems(heroTable, hHero)

  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do

    if heroTable.Items[tostring(i)] then
      local tableItem = heroTable.Items[tostring(i)]
      local item = hHero:GetItemInSlot(i)
      if item ~= nil then
        hHero:TakeItem(item)
      end
      local newItem = hHero:AddItemByName( tableItem['Name'] )
      if newItem and newItem.SetCurrentCharges and tableItem['Charges'] then
        newItem:SetCurrentCharges(tableItem['Charges'])
      end
    end
  end
end

function GameStateLoadSave:SaveCave(newState)
  newState.Caves = CaveHandler:GetCaveClears()
end

function GameStateLoadSave:LoadCave(state)
  CaveHandler:SetCaveClears(state.Caves)
  CaveHandler:ResetCaveAndNotify(DOTA_TEAM_GOODGUYS, 0)
  CaveHandler:ResetCaveAndNotify(DOTA_TEAM_BADGUYS, 0)
end

function GameStateLoadSave:SaveGameTime(newState)
  newState.GameTime = HudTimer:GetGameTime()
end

function GameStateLoadSave:LoadGameTime(state)
  HudTimer:SetGameTime(state.GameTime)
end

function GameStateLoadSave:SaveBossPitLvls(newState)
  newState.BossPits = {}
  local bossPits = Entities:FindAllByName('boss_pit')

  for _,bossPit in ipairs(bossPits) do
    local boss = bossPit:GetAbsOrigin()
    local vectorStr = "[ " .. boss.x .. " , " .. boss.y .. " , " .. boss.z .. " ]"
    table.insert(newState.BossPits, {X = boss.x, Y = boss.y, Z = boss.z, KillCount = bossPit.killCount})
  end
end

function GameStateLoadSave:LoadBossPitLvls(state)

  for _,bossPit in ipairs(state.BossPits) do
    local pos = Vector(bossPit.X, bossPit.Y, bossPit.Z)
    -- Clear the bosses at the pit location
    local bosses = FindUnitsInRadius(
      DOTA_TEAM_NEUTRALS,
      pos,
      nil,
      2000,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      DOTA_UNIT_TARGET_ALL,
      DOTA_UNIT_TARGET_FLAG_NONE ,
      FIND_ANY_ORDER,
      false )
    for _,friendly in pairs ( bosses ) do
      if  friendly ~= nil and not friendly:IsNull() and friendly:FindAbilityByName("boss_resistance") ~= nil  then
        friendly.Suicide = true
        if friendly:GetUnitName() == "npc_dota_creature_ogre_tank_boss" then
          for _,summon in pairs ( friendly.OgreSummonSeers ) do
            summon:ForceKill(false)
          end
        end
        friendly:ForceKill( false )
      end
    end

    Timers:CreateTimer(1, function()
      -- Spawn at the pit
      for _,pit in ipairs(Entities:FindAllByName('boss_pit')) do
        local pitPos = pit:GetAbsOrigin()
        if pitPos == pos  then
          pit.killCount = 3
          BossSpawner:SpawnBossAtPit(pit)
        end
      end
    end)

  end
end

function GameStateLoadSave:SaveScore(newState)
  newState.Score = {}
  newState.Score[DOTA_TEAM_GOODGUYS]= PointsManager:GetPoints(DOTA_TEAM_GOODGUYS)
  newState.Score[DOTA_TEAM_BADGUYS]= PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
end

function GameStateLoadSave:LoadScore(state)
  PointsManager:SetPoints(DOTA_TEAM_GOODGUYS, state.Score[DOTA_TEAM_GOODGUYS])
  PointsManager:SetPoints(DOTA_TEAM_BADGUYS, state.Score[DOTA_TEAM_BADGUYS])
end
