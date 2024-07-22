
dire_tower_boss_summon_wave = class(AbilityBaseClass)

function dire_tower_boss_summon_wave:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("LycanBoss.SummonWolves")
  -- -- TODO: find better sound
  local nMeleeSpawns = self:GetSpecialValueFor("num_melee_spawn")
  local nRangedSpawns = self:GetSpecialValueFor("num_ranged_spawn")
  local nSiegeSpawns = self:GetSpecialValueFor("num_siege_spawn")
  local summon_duration = self:GetSpecialValueFor("wave_duration")
  local waveNumber = caster.nCAST_SUMMON_WAVE_ROUND

  --local function boss_summon_particles(unit)
    --local spawn_particle = "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf"
    --local index = ParticleManager:CreateParticle(spawn_particle, PATTACH_ABSORIGIN_FOLLOW, unit)
    --ParticleManager:ReleaseParticleIndex(index)
  --end

  local function AttackTarget(attacker, target)
    if attacker and not attacker:IsNull() and target and not target:IsNull() then
      if attacker:CanEntityBeSeenByMyTeam(target) then
        ExecuteOrderFromTable({
          UnitIndex = attacker:entindex(),
          OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
          TargetIndex = target:entindex(),
          Queue = false,
        })
      else
        ExecuteOrderFromTable({
          UnitIndex = attacker:entindex(),
          OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
          Position = target:GetAbsOrigin(),
          Queue = false,
        })
      end
    end
  end

  local caster_loc = caster:GetAbsOrigin()

  for i = 0, nMeleeSpawns - 1 do
    if #caster.DIRE_TOWER_BOSS_SUMMONED_UNITS + 1 < caster.DIRE_TOWER_BOSS_MAX_SUMMONS then
      local vSpawnPoint = caster_loc + Vector( RandomInt( -450, 450 ), RandomInt( -450, 450 ), 0 )
      local meleeCreepName = "npc_dota_creature_melee_wave" .. waveNumber .. "_creep"
      local hMelee = CreateUnitByName( meleeCreepName, vSpawnPoint, true, caster, caster, caster:GetTeamNumber() )
      if hMelee then
        hMelee:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hMelee:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hMelee:SetAggroTarget(caster:GetAggroTarget())
        table.insert( caster.DIRE_TOWER_BOSS_SUMMONED_UNITS, hMelee )
        hMelee:SetOwner(caster)
        --boss_summon_particles(hMelee)
      end
    end
  end

  for i = 0, nRangedSpawns - 1 do
    if #caster.DIRE_TOWER_BOSS_SUMMONED_UNITS + 1 < caster.DIRE_TOWER_BOSS_MAX_SUMMONS then
      local vSpawnPoint = caster_loc + Vector( RandomInt( -450, 450 ), RandomInt( -450, 450 ), 0 )
      local rangedCreepName = "npc_dota_creature_ranged_wave" .. waveNumber .. "_creep"
      local hRanged = CreateUnitByName( rangedCreepName, vSpawnPoint, true, caster, caster, caster:GetTeamNumber() )
      if hRanged then
        hRanged:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hRanged:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hRanged:SetAggroTarget(caster:GetAggroTarget())
        table.insert( caster.DIRE_TOWER_BOSS_SUMMONED_UNITS, hRanged )
        hRanged:SetOwner(caster)
        --boss_summon_particles(hRanged)
      end
    end
  end

  for i = 0, nSiegeSpawns - 1 do
    if #caster.DIRE_TOWER_BOSS_SUMMONED_UNITS + 1 < caster.DIRE_TOWER_BOSS_MAX_SUMMONS then
      local vSpawnPoint = caster_loc + Vector( RandomInt( -450, 450 ), RandomInt( -450, 450 ), 0 )
      local siegeCreepName = "npc_dota_creature_siege_wave" .. waveNumber .. "_creep"
      local hSiege = CreateUnitByName( siegeCreepName, vSpawnPoint, true, caster, caster, caster:GetTeamNumber() )
      if hSiege then
        hSiege:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hSiege:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hSiege:SetAggroTarget(caster:GetAggroTarget())
        table.insert( caster.DIRE_TOWER_BOSS_SUMMONED_UNITS, hSiege )
        hSiege:SetOwner(caster)
        --boss_summon_particles(hSiege)
      end
    end
  end

  Timers:CreateTimer(0.1, function()
    if caster and not caster:IsNull() then
      if caster.DIRE_TOWER_BOSS_SUMMONED_UNITS then
        for _, unit in pairs(caster.DIRE_TOWER_BOSS_SUMMONED_UNITS) do
          AttackTarget(unit, caster.minion_target)
        end
      end
    end
  end)
end

--------------------------------------------------------------------------------

function dire_tower_boss_summon_wave:GetCooldown( iLevel )
  local caster = self:GetCaster()
  local baseCD = self.BaseClass.GetCooldown(self, self:GetLevel())
  local fReducedCD = baseCD - 3
  if caster.nCAST_SUMMON_WAVE_COUNT then
    fReducedCD = baseCD - caster.nCAST_SUMMON_WAVE_ROUND * 2
  end
  local fMinCD = baseCD/2 + 5
  local fNewCD = math.max(fMinCD, fReducedCD)

  return fNewCD
end
