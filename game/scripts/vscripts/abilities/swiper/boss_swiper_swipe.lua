boss_swiper_backswipe_base = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:DebugRange(caster, range)
	for i=1,8 do
		local point = caster:GetAbsOrigin() + self:PointOnCircle(range, 360 / 16 * i)
		DebugDrawSphere(RotatePosition(caster:GetAbsOrigin(), caster:GetAngles() + QAngle(0,-90,0), point), Vector(255,0,0), 255, 32, true, self:GetCastPoint())
	end
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:FindUnitsInCone(position, coneDirection, coneLength, coneWidth, teamNumber, teamFilter, typeFilter, flagFilter, order)
	local units = FindUnitsInRadius(teamNumber, position, nil, coneLength, teamFilter, typeFilter, flagFilter, order, false)

	coneDirection = coneDirection:Normalized()

	local output = {}

	for _, unit in pairs(units) do
		local direction = (unit:GetAbsOrigin() - position):Normalized()
		if direction:Dot(coneDirection) >= math.cos(coneWidth/2) then
			table.insert(output, unit)
		end
	end

	return output
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:PointOnCircle(radius, angle)
	local x = radius * math.cos(angle * math.pi / 180)
	local y = radius * math.sin(angle * math.pi / 180)
	return Vector(x,y,0)
end

--------------------------------------------------------------------------------

function boss_swiper_backswipe_base:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local range = self:GetCastRange(caster:GetAbsOrigin(), caster)

		caster:EmitSound("Hero_Juggernaut.BladeDance")

		local swipe = ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_ti6/invoker_deafening_blast_swipe_right_ti6.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(swipe, 3, caster:GetAbsOrigin() + (caster:GetForwardVector() * 100))
		ParticleManager:SetParticleControlForward(swipe, 3, caster:GetForwardVector())

		local units = self:FindUnitsInCone(
			caster:GetAbsOrigin(),
			caster:GetForwardVector(),
			range,
			range*2,
			caster:GetTeamNumber(),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_CLOSEST
		)

		for k,v in pairs(units) do
			DebugDrawSphere(v:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 0.3)

			v:EmitSound("hero_ursa.attack")

			local impact = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", PATTACH_POINT_FOLLOW, v)
			local damageTable = {
				victim = v,
				attacker = caster,
				damage = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType(),
				ability = self
			}
			ApplyDamage(damageTable)
		end
	end
end