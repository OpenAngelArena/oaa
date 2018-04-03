LinkLuaModifier("boss_swiper_reapers_rush_active", "abilities/swiper/boss_swiper_reapers_rush.lua", LUA_MODIFIER_MOTION_NONE)

boss_swiper_reapers_rush = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:OnAbilityPhaseStart()
	if IsServer() then
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("radius")
		local target = self:GetCursorPosition()
		local distance = (target - caster:GetAbsOrigin()):Length2D()
		local castTime = self:GetCastPoint()
		local direction = (target - caster:GetAbsOrigin()):Normalized()

		DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width / 2,0), Vector(distance,width / 2,50), direction, Vector(255,0,0), 1, castTime) 
		DebugDrawCircle(target, Vector(255,0,0), 255, width, false, castTime + 2.0)
	end
	return true
end

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:GetPlaybackRateOverride()
	return 0.275
end

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorPosition()
		local distance = (target - caster:GetAbsOrigin()):Length2D()
		local direction = (target - caster:GetAbsOrigin()):Normalized()

		caster:Stop()

		local modifier = caster:AddNewModifier(caster, self, "boss_swiper_reapers_rush_active", {})
		local modifierTable = {}
		modifierTable.speed = self:GetSpecialValueFor("speed")
		modifierTable.distance = distance
		modifier:InitRush(modifierTable)
	end
end

------------------------------------------------------------------------------------

boss_swiper_reapers_rush_active = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:IsPurgable()
	return false
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:GetActivityTranslationModifiers()
    return "haste"
end

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:GetOverrideAnimationRate()
	return 2.0
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:GetOverrideAnimation()
	return ACT_DOTA_RUN
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:GetOverrideAnimationWeight(params)
    return 1.0
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:DeclareFunctions()
	local funcs = {
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
        MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
	}

	return funcs
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_STUNNED] = true,
        [MODIFIER_STATE_MAGIC_IMMUNE] = true,
        -- [MODIFIER_STATE_INVULNERABLE] = true,
    }

    return state
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:OnDestroy()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")

	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	for k,v in pairs(units) do
		local damageTable = {
			victim = v,
			attacker = caster,
			damage = ability:GetSpecialValueFor("max_damage"),
			damage_type = ability:GetAbilityDamageType(),
			ability = ability
		}
		ApplyDamage(damageTable)

		local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, v)

		v:EmitSound("hero_ursa.attack")
	end

	ParticleManager:CreateParticle("particles/econ/items/lich/frozen_chains_ti6/lich_frozenchains_frostnova_swipe.vpcf", PATTACH_POINT, caster)

	caster:Stop()
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:InitRush(keys)
	self.speed = keys.speed
	self.distance = keys.distance
	self.traveled = 0
	self.step = self.speed / 30
	self.hit = {}

	self:SetDuration(self.distance / self.speed, false)

	self:StartIntervalThink(0.03)
end

------------------------------------------------------------------------------------

function boss_swiper_reapers_rush_active:OnIntervalThink()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")

	self.traveled = self.traveled + self.step

	if self.traveled >= self.distance then
		self:Destroy()
		return
	end

	caster:SetAbsOrigin(caster:GetAbsOrigin() + (caster:GetForwardVector() * self.step))

	DebugDrawSphere(caster:GetAbsOrigin(), Vector(255,0,0), 255, radius, false, 0.03)

	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	for k,v in pairs(units) do
		if not self.hit[v:entindex()] then
			self.hit[v:entindex()] = true

			local point = caster:GetAbsOrigin()
			local knockbackModifierTable = {
				should_stun = 1,
				knockback_duration = 1.0,
				duration = 1.0,
				knockback_distance = radius - (v:GetAbsOrigin() - point):Length2D(),
				knockback_height = ability:GetSpecialValueFor("push_length"),
				center_x = point.x,
				center_y = point.y,
				center_z = point.z
			}
			v:AddNewModifier( caster, ability, "modifier_knockback", knockbackModifierTable )

			local damageTable = {
				victim = v,
				attacker = caster,
				damage = ability:GetSpecialValueFor("min_damage"),
				damage_type = ability:GetAbilityDamageType(),
				ability = ability
			}
			ApplyDamage(damageTable)

			v:EmitSound("hero_ursa.attack")

			local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, v)
		end
	end
end