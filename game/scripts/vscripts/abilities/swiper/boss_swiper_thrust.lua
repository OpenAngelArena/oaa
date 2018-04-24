-- require('abilities/swiper/boss_swiper_swipe')

boss_swiper_thrust = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_thrust:OnAbilityPhaseStart()
	if IsServer() then
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("width")
		local target = GetGroundPosition(self:GetCursorPosition(), caster)
		local distance = (target - caster:GetAbsOrigin()):Length()
		local castTime = self:GetCastPoint()
		local direction = (target - caster:GetAbsOrigin()):Normalized()

		DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width / 2,0), Vector(distance,width / 2,50), direction, Vector(255,0,0), 1, castTime)
	end
	return true
end

--------------------------------------------------------------------------------

function boss_swiper_thrust:GetPlaybackRateOverride()
	return 0.275
end

--------------------------------------------------------------------------------

function boss_swiper_thrust:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("width")
		local target = GetGroundPosition(self:GetCursorPosition(), caster)
		local distance = (target - caster:GetAbsOrigin()):Length()
		local direction = ((target - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
		local velocity = direction * 2000

		local info = {
			EffectName = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf",
			Ability = self,
			vSpawnOrigin = caster:GetAbsOrigin(),
			fStartRadius = width,
			fEndRadius = width,
			vVelocity = velocity,
			fDistance = distance,
			Source = self:GetCaster(),
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP,
		}

		ProjectileManager:CreateLinearProjectile( info )
	end
end

function boss_swiper_thrust:OnProjectileHit( target, location )
	if IsServer() then
		if target ~= nil then
			DebugDrawSphere(target:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 0.3)

			target:EmitSound("hero_ursa.attack")

			local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, target)
			ParticleManager:ReleaseParticleIndex(impact)

			local damageTable = {
				victim = target,
				attacker = self:GetCaster(),
				damage = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType(),
				ability = self
			}
			ApplyDamage(damageTable)
		end

		return false
	end
end