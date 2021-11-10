RespawnManager = RespawnManager or class({})

function RespawnManager:Init()
  self.moduleName = "Player RespawnManager"
  GameEvents:OnHeroKilled(partial(self.OnHeroKilled, self))
end

function RespawnManager:OnHeroKilled(keys)
  local killer = keys.killer
  local killed = keys.killed
  local killerTeam = DOTA_TEAM_NEUTRALS
  if killer then
    killerTeam = killer:GetTeam()
  end

  -- For Meepo when a clone dies and not a primary meepo
  if killed:IsClone() then
    -- Do everything again for the primary Meepo
    keys.killed = killed:GetCloneSource()
    self:OnHeroKilled(keys)
  end

  local respawnTime = RESPAWN_TIME_TABLE[killed:GetLevel()]


  if not Duels:IsActive() then
    killed:SetRespawnsDisabled(false)

    if not killed:IsReincarnating() then
      if killerTeam ~= DOTA_TEAM_NEUTRALS then
        killed:SetTimeUntilRespawn(respawnTime)
      else
        killed:SetTimeUntilRespawn(respawnTime + RESPAWN_NEUTRAL_DEATH_PENALTY)
      end
    end
  end
end
