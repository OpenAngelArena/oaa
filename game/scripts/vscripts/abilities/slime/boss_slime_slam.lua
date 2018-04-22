LinkLuaModifier("modifier_boss_slime_slam_slow", "abilities/slime/boss_slime_slam.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_slime_slam = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_slime_slam:OnAbilityPhaseStart()
	if IsServer() then
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("width")
		local target = GetGroundPosition(self:GetCursorPosition(), caster)
		local distance = self:GetCastRange(target, caster)
		local castTime = self:GetCastPoint()
		local direction = (target - caster:GetAbsOrigin()):Normalized()

		DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width,0), Vector(distance,width,50), direction, Vector(255,0,0), 1, castTime)
	end
	return true
end

--------------------------------------------------------------------------------

function boss_slime_slam:GetPlaybackRateOverride()
	return 0.3
end

--------------------------------------------------------------------------------

function boss_slime_slam:FindTargets(position)
	local caster = self:GetCaster()
	local width = self:GetSpecialValueFor("width")
	local target = GetGroundPosition(position or self:GetCursorPosition(), caster)
	local distance = self:GetCastRange(target, caster)
	local castTime = self:GetCastPoint()
	local direction = (target - caster:GetAbsOrigin()):Normalized()
	target = GetGroundPosition(caster:GetAbsOrigin() + (direction * distance), caster)

	return FindUnitsInLine(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		target,
		caster,
		width,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE)
end

--------------------------------------------------------------------------------

function boss_slime_slam:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("width")
		local target = GetGroundPosition(self:GetCursorPosition(), caster)
		local distance = self:GetCastRange(target, caster)
		local castTime = self:GetCastPoint()
		local direction = (target - caster:GetAbsOrigin()):Normalized()
		target = GetGroundPosition(caster:GetAbsOrigin() + (direction * distance), caster)
		local selfStun = self:GetSpecialValueFor("self_stun")

		caster:EmitSound("Hero_Juggernaut.BladeDance")

		local fissure = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_fissure.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(fissure, 0, caster:GetAbsOrigin() + (direction * 64))
		ParticleManager:SetParticleControl(fissure, 1, target)
		ParticleManager:SetParticleControl(fissure, 2, Vector(selfStun,0,0))
		ParticleManager:ReleaseParticleIndex(fissure)

		local shakeAbility = caster:FindAbilityByName("boss_slime_shake")
		if shakeAbility and RandomInt(1, 100) > shakeAbility:GetSpecialValueFor("chance") then
			ExecuteOrderFromTable({
				UnitIndex = caster:entindex(),
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				AbilityIndex = shakeAbility:entindex(),
			})
		else
			caster:AddNewModifier(caster, self, "modifier_stunned", {duration = selfStun})
		end

		local units = self:FindTargets()

		for k,v in pairs(units) do
			DebugDrawSphere(v:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 0.3)

			v:EmitSound("hero_ursa.attack")

			local impact = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", PATTACH_POINT_FOLLOW, v)
			ParticleManager:ReleaseParticleIndex(impact)

			local origin = caster:GetAbsOrigin()
			local point = DotProduct(target - origin, v:GetAbsOrigin() - origin) * (target - origin) / (distance * distance) + origin
			point.z = target.z
			local knockbackModifierTable = {
				should_stun = 1,
				knockback_duration = 1.0,
				duration = 1.0,
				knockback_distance = self:GetSpecialValueFor("knockback"),
				knockback_height = 80,
				center_x = point.x,
				center_y = point.y,
				center_z = point.z
			}
			v:AddNewModifier( caster, self, "modifier_knockback", knockbackModifierTable )
			v:AddNewModifier( caster, self, "modifier_boss_slime_slam_slow", { duration = self:GetSpecialValueFor("slow_duration") })

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

modifier_boss_slime_slam_slow = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_slime_slam_slow:IsDebuff()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_slime_slam_slow:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_slam_slow:GetModifierMoveSpeedBonus_Percentage()
	if not self:GetAbility() then return end
	return self:GetAbility():GetSpecialValueFor("slow")
end