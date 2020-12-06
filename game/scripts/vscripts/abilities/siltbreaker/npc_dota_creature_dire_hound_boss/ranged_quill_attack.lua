ranged_quill_attack = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function ranged_quill_attack:OnSpellStart()
	if IsServer() then
		self.attack_speed = self:GetSpecialValueFor( "attack_speed" )
		self.attack_width_initial = self:GetSpecialValueFor( "attack_width_initial" )
		self.attack_width_end = self:GetSpecialValueFor( "attack_width_end" )
		self.attack_distance = self:GetSpecialValueFor( "attack_distance" )
    self.attack_damage = self:GetSpecialValueFor( "attack_damage" )
    local caster = self:GetCaster()

		local vPos = nil
		if self:GetCursorTarget() then
			vPos = self:GetCursorTarget():GetOrigin()
		else
			vPos = self:GetCursorPosition()
		end

		local vDirection = vPos - caster:GetOrigin()
		vDirection.z = 0.0
		vDirection = vDirection:Normalized()

		self.attack_speed = self.attack_speed * ( self.attack_distance / ( self.attack_distance - self.attack_width_initial ) )

		local info = {
			EffectName = "particles/test_particle/test_model_cluster_linear_projectile.vpcf",
			Ability = self,
			vSpawnOrigin = caster:GetOrigin(),
			fStartRadius = self.attack_width_initial,
			fEndRadius = self.attack_width_end,
			vVelocity = vDirection * self.attack_speed,
			fDistance = self.attack_distance,
			Source = caster,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		}

		ProjectileManager:CreateLinearProjectile( info )
		caster:EmitSound("Hound.QuillAttack.Cast")
	end
end

--------------------------------------------------------------------------------

function ranged_quill_attack:OnProjectileHit( hTarget, vLocation )
	if IsServer() then
		if hTarget ~= nil and ( not hTarget:IsMagicImmune() ) and ( not hTarget:IsInvulnerable() ) then
			local damage = {
				victim = hTarget,
				attacker = self:GetCaster(),
				damage = self.attack_damage,
				damage_type = DAMAGE_TYPE_PHYSICAL,
				ability = self
			}

			ApplyDamage( damage )

			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_bristleback/bristleback_quill_spray_impact.vpcf", PATTACH_CUSTOMORIGIN, hTarget )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 1, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 2, self:GetCaster(), PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), true )
			ParticleManager:ReleaseParticleIndex( nFXIndex )

			hTarget:EmitSound("Hound.QuillAttack.Target")
		end

		return true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
