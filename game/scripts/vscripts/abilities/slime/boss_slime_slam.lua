boss_slime_slam = class(AbilityBaseClass)

function boss_slime_slam:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPoint()
	
	local team = caster:GetTeamNumber()
	local data = caster or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local enemies = FindUnitsInLine(team, caster:GetAbsOrigin(), (caster:GetAbsOrigin(), point):Normalized() * self:GetSpecialValueFor("slam_range"), nil, self:GetSpecialValueFor("slam_width"), iTeam, iType, iFlag)

	}
	for _, enemy in ipairs( enemies ) do
		ApplyDamage({victim = enemy, attacker = caster, damage = damage, damage_type = self:GetAbilityDamageType(), ability = self})
		local position = enemy:GetAbsOrigin()
		local modifierKnockback = {
			center_x = position.x,
			center_y = position.y,
			center_z = position.z,
			duration = self:GetSpecialValueFor("knockback_duration"),
			knockback_duration = self:GetSpecialValueFor("knockback_duration"),
			knockback_distance = self:GetSpecialValueFor("knockback_distance"),
			knockback_height = 0,
		enemy:AddNewModifier(caster, self, "modifier_knockback", modifierKnockback )
		enemy:AddNewModifier(caster, self, "modifier_boss_slime_slam_slow", {duration = self:GetSpecialValueFor("slow_duration")} )
	end
end

modifier_boss_slime_slam_slow = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_slam_slow", "abilities/slime/boss_slime_slam", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_slime_slam_slow:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

------------------------------------------------------------------------------------

function modifier_boss_slime_slam_slow:OnCreated( kv )
	self.movement_speed_slow = self:GetAbility():GetSpecialValueFor( "slam_slow" )
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

function modifier_boss_slime_slam_slow:GetModifierMoveSpeedBonus_Percentage( params )
	return self.movement_speed_slow
end
