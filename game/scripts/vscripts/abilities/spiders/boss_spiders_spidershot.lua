LinkLuaModifier("modifier_boss_spiders_spiderball_flying", "abilities/spiders/boss_spiders_spidershot.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_spiders_spiderball_slow", "abilities/spiders/boss_spiders_spidershot.lua", LUA_MODIFIER_MOTION_NONE)

boss_spiders_spidershot = class(AbilityBaseClass)

function boss_spiders_spidershot:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

function boss_spiders_spidershot:OnSpellStart(keys)
	local caster = self:GetCaster()
	local target = GetGroundPosition(self:GetCursorPosition(), caster)

 --    local projTable = {
 --        EffectName = GetRangedProjectileName(caster),
 --        Ability = ability,
 --        Target = v,
 --        Source = caster,
 --        bDodgeable = true,
 --        bProvidesVision = false,
 --        vSpawnOrigin = caster:GetAbsOrigin(),
 --        iMoveSpeed = 900,
 --        iVisionRadius = 0,
 --        iVisionTeamNumber = caster:GetTeamNumber(),
 --        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
 --    }

	-- ProjectileManager:CreateTrackingProjectile(projTable)

	if target then
		local indicator = ParticleManager:CreateParticle("particles/ui_mouseactions/range_finder_generic_wardspot_model.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(indicator, 2, target)

		local origin = caster:GetAttachmentOrigin(caster:ScriptLookupAttachment("attach_hitloc")) + (caster:GetForwardVector() * 30)
		-- origin.z = caster:GetAbsOrigin().z

		-- DebugDrawLine(origin, target, 255, 255, 255, true, 5.0) 

		local ball = CreateUnitByName("npc_dota_boss_spiders_spiderball", origin, false, caster, caster, caster:GetTeamNumber())

		ball.leap_direction = caster:GetForwardVector()
		ball.leap_distance = (origin - target):Length()
		ball.leap_speed = 0.05
		ball.leap_traveled = 0
		ball.leap_height = 100

		ball.target = target

		ball.hits = {}

		ball:AddNewModifier(ball, self, "modifier_boss_spiders_spiderball_flying", {})

		caster:EmitSound("hero_ursa.attack")

		Timers:CreateTimer(function (  )
			if ball.leap_traveled < 1 then
				ball.leap_traveled = ball.leap_traveled + ball.leap_speed

				if ball.leap_traveled > 1 then
					ball.leap_traveled = 1
				end

				local z = ball.leap_height * math.sin(math.pi * ball.leap_traveled)

				local step = math.min(ball.leap_speed, (ball:GetAbsOrigin() - ball.target):Length2D())
				local newPosition = LerpVectors(origin, target, ball.leap_traveled)

				newPosition.z = LerpVectors(Vector(0,0,origin.z), Vector(0,0,ball.target.z), ball.leap_traveled).z + z
				ball:SetAbsOrigin(newPosition)

				local units = FindUnitsInRadius(
					caster:GetTeamNumber(),
					ball:GetAbsOrigin(),
					nil,
					128,
					DOTA_UNIT_TARGET_TEAM_ENEMY,
					DOTA_UNIT_TARGET_ALL,
					DOTA_UNIT_TARGET_FLAG_NONE,
					FIND_CLOSEST,
					false
				)

				for k,v in pairs(units) do
					if not ball.hits[v:entindex()] then
						ball.hits[v:entindex()] = true

						v:AddNewModifier(caster, self, "modifier_boss_spiders_spiderball_slow", { duration = self:GetSpecialValueFor("impact_slow_duration") })

						local damageTable = {
							victim = v,
							attacker = caster,
							damage = self:GetSpecialValueFor("impact_damage"),
							damage_type = self:GetAbilityDamageType(),
							ability = self
						}
						ApplyDamage(damageTable)

						local impact = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_base_attack_impact.vpcf", PATTACH_POINT, v)
						ParticleManager:SetParticleControlEnt(impact, 1, v, PATTACH_POINT, "attach_hitloc", v:GetAbsOrigin(), true)

						EmitSoundOn("Hero_Broodmother.SpawnSpiderlingsImpact", v)
					end
				end

				return 0.03
			else
				ball:RemoveModifierByName("modifier_boss_spiders_spiderball_flying")
				ball:SetAbsOrigin(ball.target)

				ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_blast_off_fire_smallmoketrail.vpcf", PATTACH_POINT, ball)

				ParticleManager:DestroyParticle(indicator, true)

				Timers:CreateTimer(self:GetSpecialValueFor("explode_time"), function ()
					if IsValidEntity(ball) and ball:IsAlive() then
						EmitSoundOnLocationWithCaster(ball:GetAbsOrigin(), "Hero_Techies.Suicide", caster)

						local explosion = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControl(explosion, 0, ball:GetAbsOrigin())
						ParticleManager:SetParticleControl(explosion, 3, ball:GetAbsOrigin())

						for i=1,4 do
							local spider = CreateUnitByName("npc_dota_boss_spiders_spider", ball.target, true, caster, caster, caster:GetTeamNumber())
							ParticleManager:CreateParticle("particles/units/heroes/hero_broodmother/broodmother_spiderlings_spawn_b_lv.vpcf", PATTACH_POINT, spider)
						end

						UTIL_Remove(ball)
					end
				end)
			end
		end)
	end
end

modifier_boss_spiders_spiderball_flying = ({})

function modifier_boss_spiders_spiderball_flying:IsHidden()
	return true
end

function modifier_boss_spiders_spiderball_flying:CheckState()
    local state = {
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
        [MODIFIER_STATE_INVULNERABLE] = true,
    }

    return state
end

modifier_boss_spiders_spiderball_slow = ({})

function modifier_boss_spiders_spiderball_slow:IsDebuff()
	return true
end

function modifier_boss_spiders_spiderball_slow:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}

	return funcs
end

function modifier_boss_spiders_spiderball_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("impact_slow_rate")
end