-- Taken from bb template
if HeroKillGold == nil then
  DebugPrint ( 'Creating new HeroKillGold object.' )
  HeroKillGold = class({})
  Debug.EnabledModules['gold:hero_kills'] = true
end

function HeroKillGold:Init()
  GameEvents:OnHeroKilled(partial(self.HeroDeathHandler, self))
end

function HeroKillGold:HeroDeathHandler (keys)
  -- points code for reference
  -- if keys.killer:GetTeam() ~= keys.killed:GetTeam() and not keys.killed:IsReincarnating() and keys.killed:GetTeam() ~= DOTA_TEAM_NEUTRALS then
  --   self:AddPoints(keys.killer:GetTeam())
  -- end
  if keys.killer:GetTeam() == keys.killed:GetTeam() then
    return
  end
  if keys.killed:IsReincarnating() then
    return
  end
  if keys.killed:GetTeam() == DOTA_TEAM_NEUTRALS or keys.killer:GetTeam() == DOTA_TEAM_NEUTRALS then
    return
  end

  local killerPlayer = keys.killer:GetPlayerOwner()
  if not killerPlayer then
    return
  end
  local killedPlayer = keys.killed:GetPlayerOwner()
  if not killedPlayer then
    return
  end

  local killedHero = killedPlayer:GetAssignedHero()
  local killerHero = killerPlayer:GetAssignedHero()

  DebugPrint(GetNetworth(killedHero))
end
