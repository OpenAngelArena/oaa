LinkLuaModifier("modifier_boss_capture_point", "modifiers/modifier_boss_capture_point.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_team_buff", "modifiers/modifier_wanderer_team_buff.lua", LUA_MODIFIER_MOTION_NONE)

Wanderer = Components:Register('Wanderer', COMPONENT_STRATEGY)

function Wanderer:Init ()
  HudTimer:At(BOSS_WANDERER_SPAWN_START, partial(Wanderer.SpawnWanderer, Wanderer))
  ChatCommand:LinkDevCommand("-spawnwanderer", Dynamic_Wrap(self, 'SpawnWanderer'), self)
  self.level = 0
  self.nextSpawn = BOSS_WANDERER_SPAWN_START
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

  local bossHandle = CreateUnitByName("npc_dota_boss_wanderer_" .. math.min(3, self.level), Vector(0, 0, 0), true, nil, nil, DOTA_TEAM_NEUTRALS)
  self.wanderer = bossHandle

  -- reward handling
  bossHandle:OnDeath(function ()
    self.nextSpawn = HudTimer:GetGameTime() + BOSS_WANDERER_RESPAWN

    -- create capture point
    local capturePointThinker = CreateModifierThinker(nil, nil, "modifier_boss_capture_point", nil, self.wanderer:GetAbsOrigin(), DOTA_TEAM_SPECTATOR, false)
    local capturePointModifier = capturePointThinker:FindModifierByName("modifier_boss_capture_point")
    capturePointModifier:SetCallback(function (teamId)
      -- give reward to capturing team
      self.nextSpawn = HudTimer:GetGameTime() + BOSS_WANDERER_RESPAWN
      HudTimer:At(self.nextSpawn, partial(Wanderer.SpawnWanderer, Wanderer))

      if self.level == 1 then
        BossAI:RewardBossKill(2, teamId)
        BossAI:RewardBossKill(2, teamId)
      elseif self.level == 2 then
        BossAI:RewardBossKill(3, teamId)
        BossAI:RewardBossKill(3, teamId)
      elseif self.level > 2 then
        PointsManager:AddPoints(teamId, 10)
      end

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

    end)
    -- Give the thinker some vision so that spectators can always see the capture point
    capturePointThinker:SetDayTimeVisionRange(1)
    capturePointThinker:SetNightTimeVisionRange(1)
  end)
end
