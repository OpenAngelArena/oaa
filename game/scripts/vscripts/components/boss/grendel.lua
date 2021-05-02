LinkLuaModifier("modifier_provides_vision_oaa", "modifiers/modifier_provides_vision_oaa.lua", LUA_MODIFIER_MOTION_NONE)

Grendel = Components:Register('Grendel', COMPONENT_STRATEGY)

function Grendel:Init()
  if self.initialized then
    print("Grendel Spawner is already initialized and there was an attempt to initialize it again -> preventing")
    return nil
  end
  local spawn_time = 12 * 60
  HudTimer:At(spawn_time, partial(Grendel.SpawnGrendel, Grendel))
  ChatCommand:LinkDevCommand("-spawngrendel", Dynamic_Wrap(self, 'SpawnGrendel'), self)
  self.nextSpawn = spawn_time
  self.respawn_time = 5 * 60
  self.initialized = true
end

function Grendel:GetState()
  local isAlive = self.grendel and not self.grendel:IsNull() and self.grendel:IsAlive()
  return {
    level = self.level,
    nextSpawn = self.nextSpawn,
    isAlive = isAlive
  }
end

function Grendel:LoadState(state)
  self.level = state.level
  if state.isAlive then
    self:SpawnGrendel()
  else
    self.nextSpawn = state.nextSpawn
    HudTimer:At(self.nextSpawn, partial(Grendel.SpawnGrendel, Grendel))
  end
end

function Grendel:SpawnGrendel()
  local grendel = self.grendel
  if grendel and not grendel:IsNull() and grendel:IsAlive() then
    return
  end

  if grendel and not grendel:IsNull() then
    UTIL_Remove(grendel)
    self.grendel = nil
  end

  if not self.spawn_counter then
    self.spawn_counter = 0
  end

  if self.spawn_counter > 2 then
    return
  end

  local location = self:FindWhereToSpawn()
  local bossHandle = CreateUnitByName("npc_dota_boss_grendel", location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  bossHandle.BossTier = 2
  self.grendel = bossHandle

  self.spawn_counter = self.spawn_counter + 1

  -- Give everyone vision over Grendel
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero then
      bossHandle:AddNewModifier(hero, nil, "modifier_provides_vision_oaa", {})
    end
  end)

  --bossHandle:OnHurt(function (keys)
    --bossHandle:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 5)
    --bossHandle:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 5)
  --end)

  -- reward handling
  bossHandle:OnDeath(function (keys)
    self.nextSpawn = HudTimer:GetGameTime() + self.respawn_time

    if self.spawn_counter <= 2 then
      HudTimer:At(self.nextSpawn, partial(Grendel.SpawnGrendel, Grendel))
    end

    local xp_reward = 3000 * self.spawn_counter
    local attacker_index = keys.entindex_attacker
    local killer
    if attacker_index then
      killer = EntIndexToHScript(attacker_index)
    end
    local allied_team = killer:GetTeamNumber()
    local allied_player_ids = PlayerResource:GetPlayerIDsForTeam(allied_team)

    -- Give xp to every hero on the killing team
    allied_player_ids:each(function (playerid)
      local hero = PlayerResource:GetSelectedHeroEntity(playerid)

      if hero and xp_reward > 0 then
        hero:AddExperience(xp_reward, DOTA_ModifyXP_Unspecified, false, true)
        SendOverheadEventMessage(PlayerResource:GetPlayer(playerid), OVERHEAD_ALERT_XP, hero, xp_reward, nil)
      end
    end)

    -- Increase the score limit
    local scoreLimitIncrease = PlayerResource:SafeGetTeamPlayerCount() * KILL_LIMIT_INCREASE
    PointsManager:IncreaseLimit(scoreLimitIncrease)
  end)
end

function Grendel:FindWhereToSpawn()
  local maxY = 4100
  local maxX = 5500
  local minY = 0
  local minX = 0

  local position = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), 100)

  if RandomInt(1, 2) == 1 then
    position.y = 0 - position.y
  end

  if RandomInt(1, 2) == 1 then
    position.x = 0 - position.x
  end

  return GetGroundPosition(position, nil)
end
