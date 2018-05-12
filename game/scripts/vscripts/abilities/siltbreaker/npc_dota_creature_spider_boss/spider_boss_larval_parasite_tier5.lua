
spider_boss_larval_parasite_tier5 = class( AbilityBaseClass )

LinkLuaModifier( "modifier_spider_boss_larval_parasite", "modifiers/modifier_spider_boss_larval_parasite", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:OnAbilityPhaseStart()
	if IsServer() then
		self:PlayLarvalParasiteSpeech()

		self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster() )
		ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetCaster():GetOrigin(), true )
		ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 175, 175, 175 ) )
		ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 131, 251, 40 ) )
	end

	return true
end

--------------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:OnAbilityPhaseInterrupted()
	if IsServer() then
		ParticleManager:DestroyParticle( self.nPreviewFX, false )
	end
end

-----------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:GetPlaybackRateOverride()
	return 0.3
end

--------------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()
		ParticleManager:DestroyParticle( self.nPreviewFX, false )

		self.projectile_speed = self:GetSpecialValueFor( "projectile_speed" )
		--self.damage = self:GetSpecialValueFor( "damage" )
		self.buff_duration = self:GetSpecialValueFor( "buff_duration" )
		self.projectile_width_initial = self:GetSpecialValueFor( "projectile_width_initial" )
		self.projectile_width_end = self:GetSpecialValueFor( "projectile_width_end" )
		self.projectile_distance = self:GetSpecialValueFor( "projectile_distance" )
		self.spider_lifetime = self:GetSpecialValueFor( "spider_lifetime" )

		local fCastRange = self:GetCastRange( caster:GetOrigin(), nil )
		local hEnemies = FindUnitsInRadius( caster:GetTeamNumber(), caster:GetOrigin(), nil, fCastRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false )

		for _, hEnemy in pairs( hEnemies ) do
			local vPos = hEnemy:GetOrigin()
			local vDirection = vPos - caster:GetOrigin()
			vDirection.z = 0.0
			vDirection = vDirection:Normalized()

			self.projectile_speed = self.projectile_speed * ( self.projectile_distance / ( self.projectile_distance - self.projectile_width_initial ) )

			local info = {
				EffectName = "particles/test_particle/dungeon_broodmother_linear.vpcf",
				Ability = self,
				vSpawnOrigin = caster:GetOrigin(),
				fStartRadius = self.projectile_width_initial,
				fEndRadius = self.projectile_width_end,
				vVelocity = vDirection * self.projectile_speed,
				fDistance = self.projectile_distance,
				Source = caster,
				iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetType = DOTA_UNIT_TARGET_HERO,
			}

			ProjectileManager:CreateLinearProjectile( info )

			local nFXIndex = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_CUSTOMORIGIN, nil )
			ParticleManager:SetParticleControl( nFXIndex, 0, caster:GetOrigin() )
			ParticleManager:SetParticleControl( nFXIndex, 1, info.vVelocity )
			ParticleManager:SetParticleControl( nFXIndex, 2, Vector( self.projectile_width_end, self.projectile_width_end, self.projectile_width_end ) )
      ParticleManager:DestroyParticle( nFXIndex , false)
      ParticleManager:ReleaseParticleIndex( nFXIndex )
		end

		caster:EmitSound("Broodmother.LarvalParasite.Cast")
	end
end

--------------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:OnProjectileHit( hTarget, vLocation )
	if IsServer() then
		if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
			hTarget:AddNewModifier( self:GetCaster(), self, "modifier_spider_boss_larval_parasite", { duration = self.buff_duration } )

			hTarget:EmitSound("Broodmother.LarvalParasite.Impact")
		end

		return true
	end
end

--------------------------------------------------------------------------------

function spider_boss_larval_parasite_tier5:PlayLarvalParasiteSpeech()
  if IsServer() then
    local caster = self:GetCaster()
		if caster.nLastLarvalSound == nil then
			caster.nLastLarvalSound = -1
		end

		local nSound = RandomInt( 1, 3 )
		while nSound == caster.nLastLarvalSound do
			nSound = RandomInt( 1, 3 )
		end

		if nSound == 1 then
			caster:EmitSound("broodmother_broo_attack_06")
		end
		if nSound == 2 then
			caster:EmitSound("broodmother_broo_attack_10")
		end
		if nSound == 3 then
			caster:EmitSound("broodmother_broo_attack_11")
		end
		if nSound == 4 then
			caster:EmitSound("broodmother_broo_attack_12")
		end

		caster.nLastLarvalSound = nSound
	end
end

--------------------------------------------------------------------------------

