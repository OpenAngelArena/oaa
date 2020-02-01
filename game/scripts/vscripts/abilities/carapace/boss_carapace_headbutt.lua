LinkLuaModifier("modifier_boss_carapace_headbutt_slow", "abilities/carapace/boss_carapace_headbutt.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_carapace_headbutt = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_carapace_headbutt:GetPlaybackRateOverride()
	return 0.25
end

--------------------------------------------------------------------------------

if IsServer() then
	function boss_carapace_headbutt:OnAbilityPhaseStart()
		local caster = self:GetCaster()
		local width = self:GetSpecialValueFor("width")
		local damage_range = self:GetSpecialValueFor("damage_range")
		local castTime = self:GetCastPoint()
		local direction = caster:GetForwardVector()

		DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width,0), Vector(damage_range*2,width,50), direction, Vector(255,0,0), 1, castTime)
		return true
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function boss_carapace_headbutt:GetEnemies()
		local caster = self:GetCaster()
		local damage_range = self:GetSpecialValueFor("damage_range")

		local startPoint = caster:GetAbsOrigin()
		local endPoint = caster:GetAbsOrigin() + (caster:GetForwardVector() * damage_range)

		local enemies = FindUnitsInLine(
			caster:GetTeamNumber(),
			startPoint,
			endPoint,
			caster,
			self:GetSpecialValueFor("width"),
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)

		return enemies
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function boss_carapace_headbutt:OnSpellStart()
		local caster = self:GetCaster()
		local range = self:GetSpecialValueFor("range")
		local target = (caster:GetForwardVector() * range) + caster:GetAbsOrigin()

		caster:EmitSound("Hero_Juggernaut.BladeDance")

		local smoke = ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_ti7_golden/antimage_blink_start_ti7_golden_smoke.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(smoke, 0, caster:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(smoke)

		local enemies = self:GetEnemies()

		for k,victim in pairs(enemies) do
			DebugDrawSphere(victim:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 5.3)

			victim:EmitSound("Hero_Ursa.Attack")

			local impact = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", PATTACH_POINT_FOLLOW, victim)
			ParticleManager:ReleaseParticleIndex(impact)

			local damageTable = {
				victim = victim,
				attacker = caster,
				damage = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType(),
				ability = self
			}
			ApplyDamage(damageTable)

			local knockbackModifierTable = {
				should_stun = 0,
				knockback_duration = 0.5,
				duration = 0.5,
				knockback_distance = range,
				knockback_height = 50,
				center_x = target.x,
				center_y = target.y,
				center_z = target.z
			}
			victim:AddNewModifier( caster, self, "modifier_knockback", knockbackModifierTable )

			victim:AddNewModifier( caster, self, "modifier_boss_carapace_headbutt_slow", {duration=self:GetSpecialValueFor("slow_duration")} )
		end

		caster:SetAbsOrigin(target)
		caster:Stop()
		caster:AddNewModifier( caster, self, "modifier_stunned", {duration=self:GetSpecialValueFor("self_stun")} )
	end
end

--------------------------------------------------------------------------------

modifier_boss_carapace_headbutt_slow = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:IsDebuff()
	return true
end

function modifier_boss_carapace_headbutt_slow:IsPurgable()
  return true
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:DeclareFunctions()
	local funcs =
	{
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")
end

function modifier_boss_carapace_headbutt_slow:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("attack_speed_slow")
end
