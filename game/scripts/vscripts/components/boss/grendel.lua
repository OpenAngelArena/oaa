
Grendel = Components:Register('Grendel', COMPONENT_STRATEGY)

function Grendel:Init()
  self.moduleName = "Grendel Spawner"
  local spawn_time = 16 * 60
  HudTimer:At(spawn_time, partial(Grendel.SpawnGrendel, Grendel))
  ChatCommand:LinkDevCommand("-spawngrendel", Dynamic_Wrap(self, 'SpawnGrendel'), self)
  self.level = 0
  self.nextSpawn = spawn_time
  self.respawn_time = 4 * 60
  self.respawned = false
  self.xp_reward_per_hero = 2500
end

function Grendel:GetState()
  local isAlive = self.grendel and not self.grendel:IsNull() and self.grendel:IsAlive()
  return {
    level = self.level,
    nextSpawn = self.nextSpawn,
    respawn_time = self.respawn_time,
    respawned = self.respawned,
    xp_reward_per_hero = self.xp_reward_per_hero,
    isAlive = isAlive
  }
end

function Grendel:LoadState(state)
  if not state then
    -- Grendel didn't exist when state was saved
    return
  end
  self.level = state.level
  self.respawn_time = state.respawn_time
  self.respawned = state.respawned
  self.xp_reward_per_hero = state.xp_reward_per_hero
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

  self.level = self.level + 1

  if self.level > 5 then
    return
  end

  local location = self:FindWhereToSpawn()
  local bossHandle = CreateUnitByName("npc_dota_boss_grendel", location, true, nil, nil, DOTA_TEAM_NEUTRALS)
  bossHandle.BossTier = 2
  self.grendel = bossHandle

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
    Grendel.nextSpawn = HudTimer:GetGameTime() + Grendel.respawn_time

    if not Grendel.respawned then
      Grendel.respawned = true
      HudTimer:At(Grendel.nextSpawn, partial(Grendel.SpawnGrendel, Grendel))
    end

    local xp_reward = Grendel.xp_reward_per_hero * Grendel.level
    local attacker_index = keys.entindex_attacker
    local killer
    if attacker_index then
      killer = EntIndexToHScript(attacker_index)
    end
    if killer then
      local allied_team = killer:GetTeamNumber()
      -- If boss died to self damage somehow
      if allied_team == DOTA_TEAM_NEUTRALS then
        local boss_enemies = FindUnitsInRadius(
          allied_team,
          bossHandle:GetAbsOrigin(),
          nil,
          1600,
          DOTA_UNIT_TARGET_TEAM_ENEMY,
          DOTA_UNIT_TARGET_HERO,
          bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
          FIND_CLOSEST,
          false
        )
        local closest_hero
        if #boss_enemies ~= 0 then
          closest_hero = boss_enemies[1]
        end
        if closest_hero then
          allied_team = closest_hero:GetTeamNumber()
        end
      end

      -- Grant the same reward as tier 1 boss
      BossAI:RewardBossKill(1, allied_team)

      local allied_player_ids = PlayerResource:GetPlayerIDsForTeam(allied_team)

      -- Give xp to every hero on the killing team
      allied_player_ids:each(function (playerid)
        local hero = PlayerResource:GetSelectedHeroEntity(playerid)

        if hero and xp_reward > 0 then
          hero:AddExperience(xp_reward, DOTA_ModifyXP_Unspecified, false, true)
          SendOverheadEventMessage(PlayerResource:GetPlayer(playerid), OVERHEAD_ALERT_XP, hero, xp_reward, nil)
        end
      end)

      local opposite_team
      if allied_team == DOTA_TEAM_GOODGUYS then
        opposite_team = DOTA_TEAM_BADGUYS
      elseif allied_team == DOTA_TEAM_BADGUYS then
        opposite_team = DOTA_TEAM_GOODGUYS
      end

      local difference = PointsManager:GetPoints(allied_team) - PointsManager:GetPoints(opposite_team)
      if difference < 0 then
        -- Increase the score limit only if the team that killed Grendel is losing
        PointsManager:IncreaseLimit("grendel")
      end
    end

    -- Remove Grendel calls
    Grendel:GoNearTeam(nil)
  end)
end

function Grendel:FindWhereToSpawn()
  local center = GetMapCenterOAA()
  local XBounds = GetMainAreaBoundsX()
  local YBounds = GetMainAreaBoundsY()

  local maxY = math.ceil(YBounds.maxY)
  local maxX = math.ceil(XBounds.maxX)
  local minY = math.floor(YBounds.minY)
  local minX = math.floor(XBounds.minX)

  -- Get distances from the fountains because they can be different
  local RadiantFountainFromCenter = DistanceFromFountainOAA(center, DOTA_TEAM_GOODGUYS)
  local DireFountainFromCenter = DistanceFromFountainOAA(center, DOTA_TEAM_BADGUYS)

  local scoreDiff = math.abs(PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS))
  local isGoodLead = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) > PointsManager:GetPoints(DOTA_TEAM_BADGUYS)

  -- The following code assumes that:
  -- 1) real center (0.0) is between the fountains somewhere
  -- 2) radiant fountain x coordinate is < 0
  -- 3) dire fountain x coordinate is > 0
  -- 4) fountains don't share the same y coordinate
  if isGoodLead then
    if scoreDiff >= 20 then
      minX = math.floor(center.x + DireFountainFromCenter * 3 / 5)
    elseif scoreDiff >= 15 then
      minX = math.floor(center.x + DireFountainFromCenter * 2 / 5)
      maxX = math.ceil(center.x + DireFountainFromCenter * 3 / 5)
    elseif scoreDiff >= 10 then
      minX = math.floor(center.x + DireFountainFromCenter * 1 / 5)
      maxX = math.ceil(center.x + DireFountainFromCenter * 2 / 5)
    elseif scoreDiff >= 5 then
      minX = math.floor(center.x)
      maxX = math.ceil(center.x + DireFountainFromCenter * 1 / 5)
    else
      minX = math.floor(center.x - RadiantFountainFromCenter * 1 / 5)
      maxX = math.ceil(center.x + DireFountainFromCenter * 1 / 5)
    end
  else
    if scoreDiff >= 20 then
      maxX = math.ceil(center.x - RadiantFountainFromCenter * 3 / 5)
    elseif scoreDiff >= 15 then
      minX = math.floor(center.x - RadiantFountainFromCenter * 3 / 5)
      maxX = math.ceil(center.x - RadiantFountainFromCenter * 2 / 5)
    elseif scoreDiff >= 10 then
      minX = math.floor(center.x - RadiantFountainFromCenter * 2 / 5)
      maxX = math.ceil(center.x - RadiantFountainFromCenter * 1 / 5)
    elseif scoreDiff >= 5 then
      minX = math.floor(center.x - RadiantFountainFromCenter * 1 / 5)
      maxX = math.ceil(center.x)
    else
      minX = math.floor(center.x - RadiantFountainFromCenter * 1 / 5)
      maxX = math.ceil(center.x + DireFountainFromCenter * 1 / 5)
    end
  end

  local position = Vector(RandomInt(minX, maxX), RandomInt(minY, maxY), 100)

  return GetGroundPosition(position, nil)
end

function Grendel:GoNearTeam(team)
  local difference = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS) - PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
  if team == DOTA_TEAM_GOODGUYS and difference <= 0 then
    self.was_called = true
    self.to_location = PointsManager.radiant_shrine_location + 200 * Vector(0, 1, 0)
  elseif team == DOTA_TEAM_BADGUYS and difference >= 0 then
    self.was_called = true
    self.to_location = PointsManager.dire_shrine_location + 200 * Vector(0, 1, 0)
  elseif team == nil then
    self.was_called = false
    self.to_location = nil
  end
end
