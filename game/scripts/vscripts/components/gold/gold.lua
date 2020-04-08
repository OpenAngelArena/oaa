--[[
  Author:
    Angel Arena Blackstars
    Chronophylos
  Credits:
    Angel Arena Blackstars
]]

if Gold == nil then
  DebugPrint ( '[gold/gold] creating new Gold object' )
  Gold = class({})
end

local GOLD_CAP = 50000
local GPM_TICK_INTERVAL = GOLD_TICK_TIME or 1  -- GOLD_TICK_TIME is located in settings.lua
local GOLD_PER_INTERVAL = GOLD_PER_TICK or 1   -- GOLD_PER_TICK is located in settings.lua

function Gold:Init()
  -- a table for every player
  PlayerTables:CreateTable('gold', {
    gold = {}
  }, totable(PlayerResource:GetAllTeamPlayerIDs()))

  -- start think timer
  Timers:CreateTimer(1, Dynamic_Wrap(Gold, 'Think'))
  --Timers:CreateTimer(GPM_TICK_INTERVAL, Dynamic_Wrap(Gold, 'PassiveGPM'))

  -- Set Bonus Passive GPM for each hero; vanilla gpm is always active (it was tied to couriers in 7.23 but not anymore)
  LinkLuaModifier("modifier_oaa_passive_gpm", "components/gold/gold.lua", LUA_MODIFIER_MOTION_NONE)
  Gold.hasPassiveGPM = {}
  GameEvents:OnHeroInGame(Gold.HeroSpawn)
end

function Gold:GetState ()
  local state = {}
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    state[steamid] = self:GetGold(playerID)
  end

  return state
end

function Gold:LoadState (state)
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))
    if state[steamid] then
      self:SetGold(playerID, state[steamid])
    end
  end
end

function Gold:UpdatePlayerGold(unitvar, newGold)
  local playerID = UnitVarToPlayerID(unitvar)
  if playerID and playerID > -1 then
    -- get full tree,
    --[[local allgold = PlayerTables:GetTableValue("gold", "gold")
    allgold[playerID] = PLAYER_GOLD[playerID].SavedGold

    PlayerTables:SetTableValue("gold", "gold", allgold)

    local player = PlayerResource:GetPlayer(playerID)
    CustomGameEventManager:Send_ServerToAllClients("oaa_update_gold", {
      gold = allgold
    })]]--
    local tableGold = PlayerTables:GetTableValue("gold", "gold")
    tableGold[playerID] = newGold
    PlayerTables:SetTableValue("gold", "gold", tableGold)

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
    if PlayerResource:IsValidPlayerID(i) then
      local gameState = GameRules:State_Get()
      if gameState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS or gameState == DOTA_GAMERULES_STATE_PRE_GAME then

        local currentGold = Gold:GetGold(i)
        local currentDotaGold = PlayerResource:GetGold(i)

        local newGold = currentGold
        local newDotaGold = currentDotaGold

        if currentGold > GOLD_CAP then
          newGold = currentGold + currentDotaGold - GOLD_CAP
        else
          newGold = currentDotaGold
        end

        if newGold > GOLD_CAP then
          newDotaGold = GOLD_CAP
        else
          newDotaGold = newGold
        end

        if newGold ~= currentGold or newDotaGold ~= currentDotaGold then
          Gold:SetGold(i, newGold)
          PlayerResource:SetGold(i, newDotaGold, false)
          PlayerResource:SetGold(i, 0, true)
        end
      end
    end
  end, PlayerResource:GetAllTeamPlayerIDs())
  return 0.2
end


function Gold:ClearGold(unitvar)
  Gold:SetGold(unitvar, 0)
end

function Gold:SetGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  --PLAYER_GOLD[playerID].SavedGold = math.floor(gold)
  local newGold = math.floor(gold)
  Gold:UpdatePlayerGold(playerID, newGold)
end

-- bReliable and iReason don't do anything
function Gold:ModifyGold(unitvar, gold, bReliable, iReason)
  if gold > 0 then
    Gold:AddGold(unitvar, gold)
  elseif gold < 0 then
    Gold:RemoveGold(unitvar, -gold)
  end
end

function Gold:RemoveGold(unitvar, gold)
  local playerID = UnitVarToPlayerID(unitvar)
  self:Think()
  --  PLAYER_GOLD[playerID].SavedGold = math.max((PLAYER_GOLD[playerID].SavedGold or 0) - math.ceil(gold), 0)
  local oldGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  local newGold = math.max((oldGold or 0) - math.ceil(gold), 0)
  Gold:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGold(unitvar, gold)
  --[[DebugPrint("[Gold] AddGold")
  DebugPrint("arg.unitvar: " .. unitvar)
  DebugPrint("arg.gold: " .. gold)
  DebugPrintTable(PLAYER_GOLD)]]
  local playerID = UnitVarToPlayerID(unitvar)
  self:Think()
  --PLAYER_GOLD[playerID].SavedGold = (PLAYER_GOLD[playerID].SavedGold or 0) + math.floor(gold)
  local oldGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  local newGold = (oldGold or 0) + math.floor(gold)
  Gold:UpdatePlayerGold(playerID, newGold)
end

function Gold:AddGoldWithMessage(unit, gold, optPlayerID)
  local player = optPlayerID and PlayerResource:GetPlayer(optPlayerID) or PlayerResource:GetPlayer(UnitVarToPlayerID(unit))
  SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(gold), player)
  Gold:AddGold(optPlayerID or unit, gold)
end

function Gold:GetGold(unitvar)
  local playerID = UnitVarToPlayerID(unitvar)
  local currentGold = PlayerTables:GetTableValue("gold", "gold")[playerID]
  --return math.floor(PLAYER_GOLD[playerID].SavedGold or 0)
  return math.floor(currentGold or 0)
end

function Gold.HeroSpawn(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end
  if Gold.hasPassiveGPM[hero] then
    return
  end
  if hero:IsTempestDouble() or hero:IsClone() then
    return
  end

  Timers:CreateTimer(1.2, function ()
    hero:AddNewModifier(hero, nil, "modifier_oaa_passive_gpm", {})
    Gold.hasPassiveGPM[hero] = true
  end)
end
-- exponential gpm increase
function Gold:PassiveGPM(hero)
  local time = HudTimer:GetGameTime()
  if time and self:IsGoldGenActive() then
    local tick =  math.floor(time/GPM_TICK_INTERVAL)
    local gold_per_tick = math.max(GOLD_PER_INTERVAL, math.floor(GPM_TICK_INTERVAL*(tick*tick - 140*tick + 192200)/115000))
     -- GameRules:SetGoldPerTick doesn't work since 7.23
    self:ModifyGold(hero, gold_per_tick, false, DOTA_ModifyGold_GameTick)
  end
end

-- used to determine whether or not gold generation from farming boots should occur
function Gold:IsGoldGenActive()
  return (not Duels:IsActive()) and HudTimer:GetGameTime() > 0
end

---------------------------------------------------------------------------------------------------

modifier_oaa_passive_gpm = class({})

function modifier_oaa_passive_gpm:IsPermanent()
  return true
end

function modifier_oaa_passive_gpm:IsHidden()
  return true
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
  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() then
    return
  end
  Gold:PassiveGPM(parent)
end
