LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_capture_point", "modifiers/modifier_boss_capture_point.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_team_buff", "modifiers/modifier_wanderer_team_buff.lua", LUA_MODIFIER_MOTION_NONE)

Wanderer = Components:Register('Wanderer', COMPONENT_STRATEGY)

function Wanderer:Init ()
  if self.initialized then
    print("Wanderer Spawner is already initialized and there was an attempt to initialize it again -> preventing")
    return nil
  end
  local min_time = BOSS_WANDERER_MIN_SPAWN_TIME * 60
  local max_time = BOSS_WANDERER_MAX_SPAWN_TIME * 60
  local spawn_time = RandomInt(min_time, max_time)
  HudTimer:At(spawn_time, partial(Wanderer.SpawnWanderer, Wanderer))
  ChatCommand:LinkDevCommand("-spawnwanderer", Dynamic_Wrap(self, 'SpawnWanderer'), self)
  self.level = 0
  self.nextSpawn = spawn_time

  self.initialized = true
end

function Wanderer:GetState ()
  local isAlive = self.wanderer and not self.wanderer:IsNull() and self.wanderer:IsAlive()
  return {
    level = self.level,
    nextSpawn = self.nextSpawn,
    isAlive = isAlive
  }
end

function Wanderer:LoadState (state)
  self.level = state.level
  if state.isAlive then
    self:SpawnWanderer()
  else
    self.nextSpawn = state.nextSpawn
    HudTimer:At(self.nextSpawn, partial(Wanderer.SpawnWanderer, Wanderer))
  end
end

function Wanderer:SpawnWanderer ()
  if self.wanderer and not self.wanderer:IsNull() and self.wanderer:IsAlive() then
    return
  end

  if self.wanderer and not self.wanderer:IsNull() then
    UTIL_Remove(self.wanderer)
    self.wanderer = nil
  end

  self.level = self.level + 1

  local location = self:FindWhereToSpawn()
  local bossHandle = CreateUnitByName("npc_dota_boss_wanderer_" .. math.min(3, self.level), location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  bossHandle.BossTier = math.min(5, self.level + 2)
  self.wanderer = bossHandle

  -- reward handling
  bossHandle:OnDeath(function ()
    local min_respawn_time = BOSS_WANDERER_MIN_RESPAWN_TIME * 60
    local max_respawn_time = BOSS_WANDERER_MAX_RESPAWN_TIME * 60
    local respawn_time = RandomInt(min_respawn_time, max_respawn_time)

    -- Storing for savestate (in an edge case if teams never captured the Wanderer's capture point but the game crashed)
    self.nextSpawn = HudTimer:GetGameTime() + respawn_time

    Notifications:BottomToAll({text=("#wanderer_slain_message"), duration=5.0})

    -- Create a capture point
    --local capturePointThinker = CreateModifierThinker(nil, nil, "modifier_boss_capture_point", nil, self.wanderer:GetAbsOrigin(), DOTA_TEAM_SPECTATOR, false)
    local capturePointThinker = CreateUnitByName("npc_dota_custom_dummy_unit", self.wanderer:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_SPECTATOR)
    capturePointThinker:AddNewModifier(capturePointThinker, nil, "modifier_oaa_thinker", {})
    --local capturePointModifier = capturePointThinker:FindModifierByName("modifier_boss_capture_point")
    local capturePointModifier = capturePointThinker:AddNewModifier(capturePointThinker, nil, "modifier_boss_capture_point", {})
    capturePointModifier:SetCallback(function (teamId)
      -- Storing for savestate ...
      self.nextSpawn = HudTimer:GetGameTime() + respawn_time
      -- Spawn the next wanderer at ...
      HudTimer:At(self.nextSpawn, partial(Wanderer.SpawnWanderer, Wanderer))

      -- Give cores and points to the capturing team
      if self.level == 1 then
        BossAI:RewardBossKill(1, teamId)
        BossAI:RewardBossKill(2, teamId)
      elseif self.level == 2 then
        BossAI:RewardBossKill(2, teamId)
        BossAI:RewardBossKill(3, teamId)
      elseif self.level > 2 then
        BossAI:RewardBossKill(4, teamId)
        PointsManager:AddPoints(teamId, 1)
      end

      -- Apply Wanderer buff to the capturing team
      PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
        local hero = PlayerResource:GetSelectedHeroEntity(playerId)

        if hero then
          if hero:IsAlive() then
            hero:AddNewModifier(hero, nil, "modifier_wanderer_team_buff", {})
          else
            Timers:CreateTimer(0.1, function()
              if hero:IsAlive() then
                hero:AddNewModifier(hero, nil, "modifier_wanderer_team_buff", {})
              else
                return 0.1
              end
            end)
          end
        end
      end)

      -- Enable offsides if any was disabled
      Wanderer:DisableOffside("Enable")
    end)
    -- Give the thinker some vision so that spectators can always see the capture point
    capturePointThinker:SetDayTimeVisionRange(1)
    capturePointThinker:SetNightTimeVisionRange(1)
  end)
end

function Wanderer:FindWhereToSpawn ()
  local maxY = 4000
  local maxX = 500
  local minY = 0
  local minX = 0
  local scoreDiff = math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS))
  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)

  if scoreDiff >= 5 then
    maxX = 1000
    minX = 500
  end
  if scoreDiff >= 10 then
    maxX = 1500
    minX = 1000
  end
  if scoreDiff >= 15 then
    maxX = 2500
    minX = 1500
  end
  if scoreDiff >= 20 then
    maxX = 5500
  end

  local position
  local isValidPosition = false

  while not isValidPosition do
    if position then
      print('Got a bad Wanderer spawn point: ' .. tostring(position))
    end
    position = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), 100)
    if RandomInt(0, 1) == 0 then
      position.y = 0 - position.y
    end
    if not isGoodLead then
      position.x = 0 - position.x
    end
    isValidPosition = true
    if IsLocationInOffside(position) then
      isValidPosition = false
    end
  end

  return GetGroundPosition(position, nil)
end

function Wanderer:DisableOffside(side)
  if side == "Radiant" then
    self.radiant_offside_disabled = true
    self.dire_offside_disabled = false
  elseif side == "Dire" then
    self.radiant_offside_disabled = false
    self.dire_offside_disabled = true
  else
    self.radiant_offside_disabled = false
    self.dire_offside_disabled = false
  end
end
