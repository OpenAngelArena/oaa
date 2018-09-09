RespawnManager = RespawnManager or {}

function RespawnManager:Init()
  GameEvents:OnHeroKilled(partial(self.OnHeroKilled, self))
end

function RespawnManager:OnHeroKilled(keys)
  local killer = keys.killer
  local killed = keys.killed
  local killerTeam = DOTA_TEAM_NEUTRALS
  if killer then
    killerTeam = killer:GetTeam()
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
