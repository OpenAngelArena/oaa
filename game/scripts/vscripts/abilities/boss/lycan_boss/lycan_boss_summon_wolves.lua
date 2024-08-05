
lycan_boss_summon_wolves = class(AbilityBaseClass)

function lycan_boss_summon_wolves:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf", context)
  PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_lycan.vsndevts", context)
  --PrecacheResource("soundfile", "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts", context)
end

function lycan_boss_summon_wolves:OnAbilityPhaseStart()
  if IsServer() then
    local nSound = RandomInt( 1, 3 )
    local caster = self:GetCaster()
    if nSound == 1 then
      caster:EmitSound("lycan_lycan_ability_summon_02")
    elseif nSound == 2 then
      caster:EmitSound("lycan_lycan_ability_summon_03")
    elseif nSound == 3 then
      caster:EmitSound("lycan_lycan_ability_summon_06")
    end
  end
  return true
end

--------------------------------------------------------------------------------

function lycan_boss_summon_wolves:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("LycanBoss.SummonWolves")
  local nHoundSpawns = self:GetSpecialValueFor("num_hound_spawn")
  local nHoundBossSpawns = self:GetSpecialValueFor("num_hound_boss_spawn")
  local nWerewolves = self:GetSpecialValueFor("num_werewolf_spawn")
  local summon_duration = self:GetSpecialValueFor("wolf_duration")

  if caster:FindModifierByName( "modifier_lycan_boss_shapeshift" ) ~= nil then
    nHoundSpawns = self:GetSpecialValueFor("num_ss_hound_spawn")
    nHoundBossSpawns = self:GetSpecialValueFor("num_ss_hound_boss_spawn")
    nWerewolves = self:GetSpecialValueFor("num_ss_werewolf_spawn")
  end

  -- Helper function that creates a particle for one unit (wolf)
  local function lycan_boss_summon_wolves_particles(unit)
    local spawn_particle = "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf"
    local index = ParticleManager:CreateParticle(spawn_particle, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:ReleaseParticleIndex(index)
  end

  local caster_loc = caster:GetAbsOrigin()

  -- Ability cast particle - particle on the caster (Lycan Boss)
  local summon_particle = "particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf"
  local nFXIndex = ParticleManager:CreateParticle(summon_particle, PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster_loc, true )
  ParticleManager:ReleaseParticleIndex( nFXIndex )

  for i = 0, nHoundSpawns do
    if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
      local hHound = CreateUnitByName( "npc_dota_creature_dire_hound", caster_loc, true, caster, caster, caster:GetTeamNumber() )
      if hHound then
        hHound:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hHound:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hHound:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
        table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hHound )

        local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
        local vSpawnPoint = caster_loc + vRandomOffset
        FindClearSpaceForUnit( hHound, vSpawnPoint, true )

        lycan_boss_summon_wolves_particles(hHound)
      end
    end
  end

  for i = 0, nHoundBossSpawns do
    if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
      local hHoundBoss = CreateUnitByName( "npc_dota_creature_dire_hound_boss", caster_loc, true, caster, caster, caster:GetTeamNumber() )
      if hHoundBoss then
        hHoundBoss:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hHoundBoss:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hHoundBoss:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
        table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hHoundBoss )

        local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
        local vSpawnPoint = caster_loc + vRandomOffset
        FindClearSpaceForUnit( hHoundBoss, vSpawnPoint, true )

        lycan_boss_summon_wolves_particles(hHoundBoss)
      end
    end
  end

  for i = 0, nWerewolves do
    if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
      local hWerewolf = CreateUnitByName( "npc_dota_creature_werewolf", caster_loc, true, caster, caster, caster:GetTeamNumber() )
      if hWerewolf then
        hWerewolf:AddNewModifier(caster, self, "modifier_kill", {duration = summon_duration})
        hWerewolf:AddNewModifier(caster, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hWerewolf:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
        table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hWerewolf )

        local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
        local vSpawnPoint = caster_loc + vRandomOffset
        FindClearSpaceForUnit( hWerewolf, vSpawnPoint, true )

        lycan_boss_summon_wolves_particles(hWerewolf)
      end
    end
  end

  caster.nCAST_SUMMON_WOLVES_COUNT = caster.nCAST_SUMMON_WOLVES_COUNT + 1
end

--------------------------------------------------------------------------------

function lycan_boss_summon_wolves:GetCooldown( iLevel )
  local caster = self:GetCaster()
  local baseCD = self.BaseClass.GetCooldown(self, self:GetLevel())
  local fReducedCD = baseCD - 3
  if caster.nCAST_SUMMON_WOLVES_COUNT then
    fReducedCD = baseCD - caster.nCAST_SUMMON_WOLVES_COUNT * 3
  end
  local fMinCD = baseCD/2 + 5
  local fNewCD = math.max(fMinCD, fReducedCD)

  return fNewCD
end
