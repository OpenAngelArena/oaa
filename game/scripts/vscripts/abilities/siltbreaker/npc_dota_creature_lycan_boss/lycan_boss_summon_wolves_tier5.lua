
lycan_boss_summon_wolves_tier5 = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function lycan_boss_summon_wolves_tier5:OnAbilityPhaseStart()
	if IsServer() then
    local nSound = RandomInt( 1, 3 )
    local caster = self:GetCaster()
		if nSound == 1 then
			caster:EmitSound("lycan_lycan_ability_summon_02")
		end
		if nSound == 2 then
			caster:EmitSound("lycan_lycan_ability_summon_03")
		end
		if nSound == 3 then
			caster:EmitSound("lycan_lycan_ability_summon_06")
		end
	end
	return true
end

--------------------------------------------------------------------------------

function lycan_boss_summon_wolves_tier5:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()
		caster:EmitSound("LycanBoss.SummonWolves")
		local nHoundSpawns = self:GetSpecialValueFor("num_hound_spawn")
		local nHoundBossSpawns = self:GetSpecialValueFor("num_hound_boss_spawn")
		local nWerewolves = self:GetSpecialValueFor("num_werewolf_spawn")
		if caster:FindModifierByName( "modifier_lycan_boss_shapeshift" ) ~= nil then
			nHoundSpawns = self:GetSpecialValueFor("num_ss_hound_spawn")
			nHoundBossSpawns = self:GetSpecialValueFor("num_ss_hound_boss_spawn")
			nWerewolves = self:GetSpecialValueFor("num_ss_werewolf_spawn")
    end

		for i = 0, nHoundSpawns do
			if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
				local hHound = CreateUnitByName( "npc_dota_creature_dire_hound", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber() )
        if hHound ~= nil then
          hHound:AddNewModifier(caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("wolf_duration") })
					hHound:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
					table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hHound )
					if caster.zone ~= nil then
						caster.zone:AddEnemyToZone( hHound )
					end

					local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
					local vSpawnPoint = caster:GetAbsOrigin() + vRandomOffset
					FindClearSpaceForUnit( hHound, vSpawnPoint, true )

					local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true )
					ParticleManager:ReleaseParticleIndex( nFXIndex )
					ParticleManager:ReleaseParticleIndex(  ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hHound ) )
				end
			end
		end

		for i = 0, nHoundBossSpawns do
			if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
				local hHoundBoss = CreateUnitByName( "npc_dota_creature_dire_hound_boss", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber() )
				if hHoundBoss ~= nil then
          hHoundBoss:AddNewModifier(caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("wolf_duration") })
					hHoundBoss:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
					table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hHoundBoss )
					if caster.zone ~= nil then
						caster.zone:AddEnemyToZone( hHoundBoss )
					end

					local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
					local vSpawnPoint = caster:GetAbsOrigin() + vRandomOffset
					FindClearSpaceForUnit( hHoundBoss, vSpawnPoint, true )

					local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true )
					ParticleManager:ReleaseParticleIndex( nFXIndex )
					ParticleManager:ReleaseParticleIndex(  ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hHoundBoss ) )
				end
			end
		end

		for i = 0, nWerewolves do
			if #caster.LYCAN_BOSS_SUMMONED_UNITS + 1 < caster.LYCAN_BOSS_MAX_SUMMONS then
				local hWerewolf = CreateUnitByName( "npc_dota_creature_werewolf", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber() )
				if hWerewolf ~= nil then
          hWerewolf:AddNewModifier(caster, self, "modifier_kill", {duration = self:GetSpecialValueFor("wolf_duration") })
					hWerewolf:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
					table.insert( caster.LYCAN_BOSS_SUMMONED_UNITS, hWerewolf )
					if caster.zone ~= nil then
						caster.zone:AddEnemyToZone( hWerewolf )
					end

					local vRandomOffset = Vector( RandomInt( -300, 300 ), RandomInt( -300, 300 ), 0 )
					local vSpawnPoint = caster:GetAbsOrigin() + vRandomOffset
					FindClearSpaceForUnit( hWerewolf, vSpawnPoint, true )

					local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_cast.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true )
					ParticleManager:ReleaseParticleIndex( nFXIndex )
					ParticleManager:ReleaseParticleIndex(  ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_summon_wolves_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hWerewolf ) )
				end
			end
		end

		caster.nCAST_SUMMON_WOLVES_COUNT = caster.nCAST_SUMMON_WOLVES_COUNT + 1
	end
end

--------------------------------------------------------------------------------

function lycan_boss_summon_wolves_tier5:GetCooldown( iLevel )
	local fReducedCD = self.BaseClass.GetCooldown( self, self:GetLevel() ) - ( self:GetCaster().nCAST_SUMMON_WOLVES_COUNT * 3 )
	local fMinCD = ( self.BaseClass.GetCooldown( self, self:GetLevel() ) / 2 ) + 5
	local fNewCD = math.max( fMinCD, fReducedCD )

	return fNewCD
end

--------------------------------------------------------------------------------

