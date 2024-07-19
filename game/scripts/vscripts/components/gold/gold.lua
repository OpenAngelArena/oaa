--[[
  Author:
    Angel Arena Blackstars
    Chronophylos
  Credits:
    Angel Arena Blackstars
]]

if Gold == nil then
  if Debug == nil or DebugPrint == nil then
    require('internal/util')
  end
  DebugPrint ( '[gold/gold] creating new Gold object' )
  Gold = class({})
end

local GOLD_CAP = 90000
local GPM_TICK_INTERVAL = GOLD_TICK_TIME or 1  -- GOLD_TICK_TIME is located in settings.lua
local GOLD_PER_INTERVAL = GOLD_PER_TICK or 1   -- GOLD_PER_TICK is located in settings.lua

function Gold:Init()
  self.moduleName = "Gold"

  --GameRules:SetGoldPerTick(GOLD_PER_TICK) -- GameRules:SetGoldPerTick doesn't work since 7.23
  --GameRules:SetGoldTickTime(GOLD_TICK_TIME)

  -- Create a table for every player
  PlayerTables:CreateTable('gold', {
    gold = {}
  }, totable(PlayerResource:GetAllTeamPlayerIDs()))

  -- start think timer
  Timers:CreateTimer(1, Dynamic_Wrap(Gold, 'Think'))
  --Timers:CreateTimer(GPM_TICK_INTERVAL, Dynamic_Wrap(Gold, 'PassiveGPM'))

  -- Set Bonus Passive GPM for each hero; vanilla gpm is always active (since patch 7.23 vanilla gpm is tied to couriers, while they shouldn't be)
  self.hasPassiveGPM = {}
  GameEvents:OnHeroInGame(Gold.HeroSpawn)
  --FilterManager:AddFilter(FilterManager.ModifyGold, self, Dynamic_Wrap(Gold, "GoldFilter"))
end

function Gold:GetState ()
  local state = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if steamid ~= "0" then
      state[steamid] = self:GetGold(playerID)
    end
  end

  return state
end

function Gold:LoadState (state)
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if steamid ~= "0" and state[steamid] then
      self:SetGold(playerID, state[steamid])
    end
  end
end

function Gold:UpdatePlayerGold(unitvar, newGold)
  local playerID = UnitVarToPlayerID(unitvar)
  if playerID and playerID > -1 then
    local allgold = PlayerTables:GetTableValue("gold", "gold")
    allgold[playerID] = newGold
    PlayerTables:SetTableValue("gold", "gold", allgold)

    newGold = math.min(GOLD_CAP, newGold)
    PlayerResource:SetGold(playerID, newGold, false)
    PlayerResource:SetGold(playerID, 0, true)
  end
end

--[[
  Author:
    Chronophylos
  Credits:
    Angel Arena Blackstar
  Description:
    Add Gold to all players via our custom Gold API
]]
function Gold:Think()
  foreach(function(i)
    local gameState = GameRules:State_Get()
    if gameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS or gameState == DOTA_GAMERULES_STATE_PRE_GAME then
      local currentGold = Gold:GetGold(i)
      local currentDotaGold = PlayerResource:GetGold(i)

      local newGold
      if currentGold > GOLD_CAP then
        newGold = currentGold + currentDotaGold - GOLD_CAP
      else
        newGold = currentDotaGold
      end

      local newDotaGold = math.min(newGold, GOLD_CAP)

      if newGold ~= currentGold or newDotaGold ~= currentDotaGold then
        Gold:SetGold(i, newGold)
        PlayerResource:SetGold(i, newDotaGold, false)
        PlayerResource:SetGold(i, 0, true)
      end
    end
  end, PlayerResource:GetAllTeamPlayerIDs())
  return 0.2
end

function Gold:ClearGold(unitvar)
  self:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  local newGold = math.floor(gold)
  self:UpdatePlayerGold(playerID, newGold)
end

-- bReliable and iReason don't do anything
function Gold:ModifyGold(unitvar, gold, bReliable, iReason)
  if gold > 0 then
    self:AddGold(unitvar, gold)
  elseif gold < 0 then
    self:RemoveGold(unitvar, -gold)
  end
end

function Gold:RemoveGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  self:Think() -- why?
  local oldGold = self:GetGold(playerID)
  local newGold = math.max((oldGold or 0) - math.ceil(gold), 0)
  self:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  self:Think() -- why?
  local oldGold = self:GetGold(playerID)
  local newGold = (oldGold or 0) + math.floor(gold)
  self:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
  local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
  SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold), player)
  self:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  local currentGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  return math.floor(currentGold or 0)
end

function Gold.HeroSpawn(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end
  if Gold.hasPassiveGPM[hero] then
    return
  end
  if hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
    return
  end

  Timers:CreateTimer(1.2, function ()
    hero:AddNewModifier(hero, nil, "modifier_oaa_passive_gpm", {})
    Gold.hasPassiveGPM[hero] = true
  end)
end
-- exponential gpm increase
function Gold:PassiveGPM(hero)
  local current_time = HudTimer:GetGameTime()
  if current_time and self:IsGoldGenActive() then
    local tick =  math.floor(current_time/GPM_TICK_INTERVAL)
    local gold_per_tick = math.max(GOLD_PER_INTERVAL, math.floor(GPM_TICK_INTERVAL*(tick*tick - 140*tick + 192200)/115000))
    if HeroSelection.is10v10 then
      gold_per_tick = math.floor(gold_per_tick * 1.5)
    end
    self:ModifyGold(hero, gold_per_tick, false, DOTA_ModifyGold_GameTick)
  end
end

-- used to determine whether or not gold generation from sparks should occur
function Gold:IsGoldGenActive()
  return (not Duels:IsActive()) and HudTimer:GetGameTime() > 0
end

-- function Gold:GoldFilter(filter_table)
  -- local gold = filter_table.gold
  -- local playerID = filter_table.player_id_const
  -- local reason = filter_table.reason_const
  -- local reliable = filter_table.reliable == 1

  -- Reasons:
  -- DOTA_ModifyGold_Unspecified = 0
  -- DOTA_ModifyGold_Death = 1
  -- DOTA_ModifyGold_Buyback = 2
  -- DOTA_ModifyGold_PurchaseConsumable = 3
  -- DOTA_ModifyGold_PurchaseItem = 4
  -- DOTA_ModifyGold_AbandonedRedistribute = 5
  -- DOTA_ModifyGold_SellItem = 6                -- doesn't trigger when selling items
  -- DOTA_ModifyGold_AbilityCost = 7
  -- DOTA_ModifyGold_CheatCommand = 8
  -- DOTA_ModifyGold_SelectionPenalty = 9
  -- DOTA_ModifyGold_GameTick = 10               -- additional passive gpm and gpm spark
  -- DOTA_ModifyGold_Building = 11
  -- DOTA_ModifyGold_HeroKill = 12               -- filtered out
  -- DOTA_ModifyGold_CreepKill = 13
  -- DOTA_ModifyGold_NeutralKill = 14
  -- DOTA_ModifyGold_RoshanKill = 15             -- cave
  -- DOTA_ModifyGold_CourierKill = 16
  -- DOTA_ModifyGold_BountyRune = 17             -- doesn't trigger for Bounty Runes
  -- DOTA_ModifyGold_SharedGold = 18             -- creep assist gold
  -- DOTA_ModifyGold_AbilityGold = 19
  -- DOTA_ModifyGold_WardKill = 20
  -- DOTA_ModifyGold_CourierKilledByThisPlayer = 21

  -- This filter seems so useless lmao
  -- return true
-- end

---------------------------------------------------------------------------------------------------

modifier_oaa_passive_gpm = class({})

function modifier_oaa_passive_gpm:IsPermanent()
  return true
end

function modifier_oaa_passive_gpm:IsHidden()
  return true
end

function modifier_oaa_passive_gpm:IsDebuff()
  return false
end

function modifier_oaa_passive_gpm:IsPurgable()
  return false
end

function modifier_oaa_passive_gpm:RemoveOnDeath()
  return false
end

function modifier_oaa_passive_gpm:OnCreated()
  if not IsServer() then
    return
  end
  if GOLD_PER_INTERVAL <= 0 or GPM_TICK_INTERVAL <= 0 then
    self:Destroy()
  end
  self:StartIntervalThink(GPM_TICK_INTERVAL)
end

function modifier_oaa_passive_gpm:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
    self:Destroy()
    return
  end
  Gold:PassiveGPM(parent)
end
