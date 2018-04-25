
spider_boss_summon_eggs_tier5 = class( AbilityBaseClass )

--------------------------------------------------------------------------------

function spider_boss_summon_eggs_tier5:OnAbilityPhaseStart()
	if IsServer() then
		self:PlaySummonEggsSpeech()

		self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 150, 150, 150 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 255, 26, 26 ) )
	end

	return true
end

--------------------------------------------------------------------------------

function spider_boss_summon_eggs_tier5:OnAbilityPhaseInterrupted()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
	end
end

--------------------------------------------------------------------------------

function spider_boss_summon_eggs_tier5:OnSpellStart()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
		self.spider_lifetime = self:GetSpecialValueFor( "spider_lifetime" )
    self.egg_spider_lifetime = self:GetSpecialValueFor( "egg_spider_lifetime" )

    local caster = self:GetCaster()

		caster:EmitSound("LycanBoss.SummonWolves")

		local nEggSpawns = self:GetSpecialValueFor("num_egg_spawn")
		local nPoisonSpiderSpawns = self:GetSpecialValueFor("num_poison_spider_spawn")

		for i = 0, nEggSpawns do
			if #caster.hSummonedUnits + 1 < caster.nMaxSummonedUnits then
				local hEgg = CreateUnitByName( "npc_dota_spider_sack", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber() )
        if hEgg ~= nil then
					hEgg:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
					table.insert( caster.hSummonedUnits, hEgg )
					if caster.zone ~= nil then
						caster.zone:AddEnemyToZone( hEgg )
					end

					local vRandomOffset = Vector( RandomInt( -600, 600 ), RandomInt( -600, 600 ), 0 )
					local vSpawnPoint = caster:GetAbsOrigin() + vRandomOffset
					FindClearSpaceForUnit( hEgg, vSpawnPoint, true )

					local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_visage/visage_summon_familiars.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( nFXIndex, 0, vSpawnPoint )
          ParticleManager:ReleaseParticleIndex( nFXIndex )

          -- Destroy when the boss dies
          caster:OnDeath(function()
            if IsValidEntity(hEgg) then
              hEgg:Destroy()
            end
          end)

				end
			end
		end

		for i = 0, nPoisonSpiderSpawns do
			if #caster.hSummonedUnits + 1 < caster.nMaxSummonedUnits then
				local hPoisonSpider = CreateUnitByName( "npc_dota_creature_spider_medium_tier5", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber() )
				if hPoisonSpider ~= nil then
          hPoisonSpider:AddNewModifier(caster, self, "modifier_kill", {duration = self.spider_lifetime })
					hPoisonSpider:SetInitialGoalEntity( caster:GetInitialGoalEntity() )
					table.insert( caster.hSummonedUnits, hPoisonSpider )
					if caster.zone ~= nil then
						caster.zone:AddEnemyToZone( hPoisonSpider )
					end

					local vRandomOffset = Vector( RandomInt( -600, 600 ), RandomInt( -600, 600 ), 0 )
					local vSpawnPoint = caster:GetAbsOrigin() + vRandomOffset
					FindClearSpaceForUnit( hPoisonSpider, vSpawnPoint, true )

					local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_visage/visage_summon_familiars.vpcf", PATTACH_CUSTOMORIGIN, caster )
					ParticleManager:SetParticleControl( nFXIndex, 0, vSpawnPoint )
          ParticleManager:ReleaseParticleIndex( nFXIndex )

          -- Destroy when the boss dies
          caster:OnDeath(function()
            if IsValidEntity(hPoisonSpider) then
              hPoisonSpider:Destroy()
            end
          end)

				end
			end
		end

		caster.nNumSummonCasts = caster.nNumSummonCasts + 1
	end
end

--------------------------------------------------------------------------------

function spider_boss_summon_eggs_tier5:GetCooldown( iLevel )
	if self:GetCaster().nNumSummonCasts == nil then
		self:GetCaster().nNumSummonCasts = 0
	end
	local fReducedCD = self.BaseClass.GetCooldown( self, self:GetLevel() ) - ( self:GetCaster().nNumSummonCasts * 5 )
	local fMinCD = ( self.BaseClass.GetCooldown( self, self:GetLevel() ) / 2 ) + 5
	local fNewCD = math.max( fMinCD, fReducedCD )
	--print( string.format( "spider_boss_summon_eggs:GetCooldown - fReducedCD: %d, fMinCD: %d, fNewCD: %d", fReducedCD, fMinCD, fNewCD ) )

	return fNewCD
end

--------------------------------------------------------------------------------

function spider_boss_summon_eggs_tier5:PlaySummonEggsSpeech()
	if IsServer() then
    local caster = self:GetCaster()

		if caster.nLastSummonEggsSound == nil then
			caster.nLastSummonEggsSound = -1
		end

		local nSound = RandomInt( 1, 12 )
		while nSound == caster.nLastSummonEggsSound do
			nSound = RandomInt( 1, 12 )
		end

		if nSound == 1 then
			caster:EmitSound("broodmother_broo_ability_spawn_01")
		end
		if nSound == 2 then
			caster:EmitSound("broodmother_broo_ability_spawn_02")
		end
		if nSound == 3 then
			caster:EmitSound("broodmother_broo_ability_spawn_03")
		end
		if nSound == 4 then
			caster:EmitSound("broodmother_broo_ability_spawn_04")
		end
		if nSound == 5 then
			caster:EmitSound("broodmother_broo_ability_spawn_05")
		end
		if nSound == 6 then
			caster:EmitSound("broodmother_broo_ability_spawn_06")
		end
		if nSound == 7 then
			caster:EmitSound("broodmother_broo_ability_spawn_07")
		end
		if nSound == 8 then
			caster:EmitSound("broodmother_broo_ability_spawn_08")
		end
		if nSound == 9 then
			caster:EmitSound("broodmother_broo_ability_spawn_09")
		end
		if nSound == 10 then
			caster:EmitSound("broodmother_broo_ability_spawn_10")
		end
		if nSound == 11 then
			caster:EmitSound("broodmother_broo_ability_spawn_11")
		end
		if nSound == 12 then
			caster:EmitSound("broodmother_broo_ability_spawn_12")
		end

		caster.nLastSummonEggsSound = nSound
	end
end

--------------------------------------------------------------------------------

