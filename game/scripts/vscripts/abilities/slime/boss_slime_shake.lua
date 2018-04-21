LinkLuaModifier("modifier_boss_slime_shake_slow", "abilities/slime/boss_slime_shake.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

boss_slime_shake = class(AbilityBaseClass)

------------------------------------------------------------------------------------

function boss_slime_shake:GetPlaybackRateOverride()
	return 2.0
end

------------------------------------------------------------------------------------

local function RandomPointInsideCircle(x, y, radius, minLength)
	local dist = math.random((minLength or 0), radius)
	local angle = math.random(0, math.pi * 2)

	local xOffset = dist * math.cos(angle)
	local yOffset = dist * math.sin(angle)

	return Vector(x + xOffset, y + yOffset, 0)
end

------------------------------------------------------------------------------------

local function RandomPointsInsideCircleUniform( pos, radius, count, uniform, minLength )
	local points = {}

	local function CheckPoint( v )
		for i=1,#points do
			if (points[i] - v):Length2D() < uniform then return false end
		end
		return true
	end

	local fallback = 150

	for i=1,count do
		local point

		repeat 
			point = RandomPointInsideCircle(pos.x, pos.y, radius, minLength)
			fallback = fallback - 1
			if fallback == 0 then
				return points
			end
		until CheckPoint(point)
			point.z = pos.z
			table.insert(points, point)
	end

	return points
end

------------------------------------------------------------------------------------

function boss_slime_shake:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_invulnerable", {duration = self:GetCastPoint()})
	return true
end

------------------------------------------------------------------------------------

function boss_slime_shake:OnSpellStart()
	local caster = self:GetCaster()
	local minSize = self:GetSpecialValueFor("projectile_min_size")
	local maxSize = self:GetSpecialValueFor("projectile_max_size")
	local points = RandomPointsInsideCircleUniform( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("projectile_count"), maxSize * 2, maxSize)

	for k,v in pairs(points) do
		local size = RandomInt(minSize, maxSize)
		local pos = GetGroundPosition(v, caster)
		DebugDrawCircle(pos, Vector(255,0,0), 55, size, false, 1.0)

		local wave = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(wave, 0, pos)

		Timers:CreateTimer(0.4, function ()
			local units = FindUnitsInRadius(
				caster:GetTeamNumber(),
				pos,
				nil,
				size,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_CLOSEST,
				false
			)

			for _,victim in pairs(units) do
				victim:AddNewModifier( caster, self, "modifier_boss_slime_shake_slow", { duration = self:GetSpecialValueFor("slow_duration") })

				local damageTable = {
					victim = victim,
					attacker = caster,
					damage = self:GetSpecialValueFor("damage"),
					damage_type = self:GetAbilityDamageType(),
					ability = self
				}
				ApplyDamage(damageTable)
			end
		end)
	end
end

------------------------------------------------------------------------------------

modifier_boss_slime_shake_slow = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_slime_shake_slow:IsDebuff()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_slime_shake_slow:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_shake_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow")
end