Duel = class({})

function Duel:Init (teams, spawns, zone)
  self.zone = zone
  self.states = {}
  DebugPrint('Starting a duel')
  self.teams = teams
  self.spawns = spawns
  self.scores = {}

  for index, team in pairs(teams) do
    self.scores[index] = {#team}
    for _,player in pairs(team) do
      player.team = index
    end
  end

  GameEvents:OnHeroKilled(function (keys)
    Duel:CheckDuelStatus(keys)
  end)
  Duel:Start()

  self.over = false
end

function Duel:Start()
  for index, team in pairs(self.teams) do
    local teamSpawn = self.spawns[index]
    for _, player in pairs(team) do
      Duel:SpawnPlayer(player, teamSpawn)
    end
  end
end

function Duel.Map(func)
  for _, team in pairs(self.teams) do
    for _, player in pairs(team) do
	      func(player)
	  end
  end
end

function Duel:SpawnPlayer(player, spawn)
  local hero = player:GetAssignedHero()

  self.states[player.id] = Duel:GetPlayerState(hero)
  Duel:ResetPlayerState(hero)

  self.zone.addPlayer(player.id)
  FindClearSpaceForUnit(hero, spawn, true)
  self.MoveCameraToPlayer(player.id, hero)

  hero:SetRespawnsDisabled(true)
end

function Duel:ResetPlayerState (player)
  local hero = player:GetAssignedHero()

  if not hero:IsAlive() then
    hero:RespawnHero(false,false,false)
  end

  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  for abilityIndex = 0,hero:GetAbilityCount() do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      ability:EndCooldown()
    end
  end
end

function Duel:GetPlayerState(hero)
  local state = {
    location = hero:GetAbsOrigin(),
    abilityCount = hero:GetAbilityCount(),
    maxAbility = 0,
    abilities = {},
    hp = hero:GetHealth(),
    mana = hero:GetMana()
  }

  for abilityIndex = 0,state.abilityCount-1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      state.maxAbility = abilityIndex
      state.abilities[abilityIndex] = {
        cooldown = ability:GetCooldownTimeRemaining()
      }
    end
  end
  return state
end

function Duel:RestorePlayerState(player)
  local hero = player:GetAssignedHero()
  local s = self.states[player.id]

  hero.SetAbsOrigin(s.location)
  Duel:MoveCameraToPlayer(player.id, hero)

  if s.hp > 0 then
    hero.SetHealth(s.hp)
  end
  hero:setMana(s.mana)

  for abilityIndex = 0,state.maxAbility-1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil then
      ability:StartCooldown(state.abilities[abilityIndex].cooldown)
    end
  end
  self.zone.removePlayer(player.id)
end

function Duel:MoveCameraToPlayer (playerId, entity)
  PlayerResource:SetCameraTarget(playerId, entity)

  Timers:CreateTimer(1, function ()
    PlayerResource:SetCameraTarget(playerId, nil)
  end)
end

function Duel:CheckDuelStatus (keys)
  if keys.killed:IsReincarnating() then
    return
  end

  local playerId = keys.killed:GetPlayerOwnerID()
  local foundIt = false

  Duel:Map(function (player)
    if foundIt or player.id ~= playerId then
      return
    end
    foundIt = true
    local scoreIndex = player.team
    DebugPrint('Found dead player on team ' .. player.team)

    self.scores[scoreIndex] = Duel.scores[scoreIndex] - 1

    if self.scores[scoreIndex] <= 0 then
      Duel:EndDuel()
    end
  end)
end

function Duel:EndDuel()
  Duel:Map(Duel:RestorePlayerState)
  self.over = true
  --Need to unsubscribe from event manager!
end



