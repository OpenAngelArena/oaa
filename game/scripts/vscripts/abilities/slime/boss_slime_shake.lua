boss_slime_shake = class(AbilityBaseClass)

function boss_slime_shake:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("shake_duration")
	caster:AddNewModifier(caster, self, "modifier_stunned", {duration = duration / 0.75}) -- 0.75 disable resistance so they're all the same duration
	caster:AddNewModifier(caster, self, "modifier_invulnerable", {duration = duration})
	CreateModifierThinker(caster, self, "modifier_boss_slime_shake_thinker", {duration = duration}, caster:GetAbsOrigin, caster:GetTeam(), false)
end

function boss_slime_shake:CreateProjectile(delay, radius, damage, position)
	Timers:CreateTimer(delay, function()
			local team = self:GetTeamNumber()
			local data = hData or {}
			local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = data.type or DOTA_UNIT_TARGET_ALL
			local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = data.order or FIND_ANY_ORDER
			local enemies = FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
			for _, enemy in ipairs( enemies ) do
				ApplyDamage({victim = enemy, attacker = caster, ability = self, damage_type = self:GetAbilityDamageType(), damage = damage})
				enemy:AddNewModifier(caster, self, "modifier_boss_slime_shake_slow", {duration = self:GetSpecialValueFor("slow_duration")})
			end
		)
end

modifier_boss_slime_shake_thinker = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_shake_thinker", "abilities/slime/boss_slime_shake", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_boss_slime_shake_thinker:OnCreated()
		self.damage = self:GetSpecialValueFor("projectile_damage")
		self.shakeRadius = self:GetSpecialValueFor("shake_radius")
		
		self.minRadius = self:GetSpecialValueFor("projectile_min_radius")
		self.maxRadius = self:GetSpecialValueFor("projectile_max_radius")
		
		self.minDelay = self:GetSpecialValueFor("projectile_min_delay")
		self.maxDelay = self:GetSpecialValueFor("projectile_max_delay")
		
		self.min_think = self:GetSpecialValueFor("min_think")
		self.max_think = self:GetSpecialValueFor("max_think")
		self:StartIntervalThink( RandomFloat(self.min_think, self.max_think) )
	function modifier_boss_slime_shake_thinker:OnIntervalThink()
		self:GetAbility():CreateProjectile( RandomFloat(self.minDelay, self.maxDelay), RandomInt(self.minRadius, self.maxRadius), self.damage, self:GetParent():GetAbsOrigin() + RandomVector( RandomInt(shakeRadius, 1) ) )
		self:StartIntervalThink( RandomFloat(self.min_think, self.max_think) )
	end
end


modifier_boss_slime_shake_slow = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_shake_slow", "abilities/slime/boss_slime_shake", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_slime_shake_slow:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

------------------------------------------------------------------------------------

function modifier_boss_slime_shake_slow:OnCreated( kv )
	self.movement_speed_slow = self:GetAbility():GetSpecialValueFor( "slam_slow" )
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

function modifier_boss_slime_shake_slow:GetModifierMoveSpeedBonus_Percentage( params )
	return self.movement_speed_slow
end
