boss_slime_jump = class(AbilityBaseClass)

function boss_slime_jump:IsStealable()
	return true
end

function boss_slime_jump:IsHiddenWhenStolen()
	return false
end

function boss_slime_jump:GetCastRange(target, position)
	return self:GetTalentSpecialValueFor("jump_distance")
end

function boss_slime_jump:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_boss_slime_jump_movement", {duration = self:GetTalentSpecialValueFor("jump_duration") + 0.01})
end

function boss_slime_jump:JumpLand(position, radius, damage)
	local caster = self:GetCaster()
	local team = self:GetTeamNumber()
	local data = hData or {}
	local iTeam = data.team or DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = data.type or DOTA_UNIT_TARGET_ALL
	local iFlag = data.flag or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = data.order or FIND_ANY_ORDER
	local enemies = FindUnitsInRadius(team, position, nil, radius, iTeam, iType, iFlag, iOrder, false)
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
		enemy:AddNewModifier(caster, self, "modifier_boss_slime_jump_slow", {duration = self:GetSpecialValueFor("slow_duration")} )
	end
end

modifier_boss_slime_jump_movement = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_jump_movement", "abilities/boss_slime_jump.lua", LUA_MODIFIER_MOTION_BOTH)

if IsServer() then
	function modifier_boss_slime_jump_movement:OnCreated()
		if not self:ApplyHorizontalMotionController() then
			self:Destroy()
		end
		if not self:ApplyVerticalMotionController() then
			self:Destroy()
		end
		self.distance = self:GetAbility():GetSpecialValueFor("push_length")
		self.airTime = self:GetAbility():GetSpecialValueFor("air_time")
		self.speed = self.distance / self.airTime
		self.direction = (self:GetParent():GetAbsOrigin() - self:GetCaster():GetAbsOrigin()):Normalized()
		self.initHeight = GetGroundHeight(self:GetParent():GetAbsOrigin(), self:GetParent())
		self.distanceTravelled = 0
	end
	
	function modifier_boss_slime_jump_movement:OnRemoved()
		self:GetAbility():JumpLand(self:GetParent():GetAbsOrigin(), self:GetSpecialValueFor("land_radius"), self:GetSpecialValueFor("land_damage"))
	end

	function modifier_boss_slime_jump_movement:UpdateHorizontalMotion( me, dt )
		local parent = self:GetParent()
		if self.distance > self.distanceTravelled and self:GetParent():IsAlive() then
			parent:SetAbsOrigin(parent:GetAbsOrigin() + self.direction * self.speed*dt)
			self.distanceTravelled = self.distanceTravelled + self.speed*dt
			GridNav:DestroyTreesAroundPoint(parent:GetAbsOrigin(), parent:GetHullRadius() + parent:GetCollisionPadding(), true)
		else
			parent:InterruptMotionControllers(true)
			FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
			self:Destroy()
		end
	end

	function modifier_boss_slime_jump_movement:UpdateVerticalMotion( me, dt )
		local parent = self:GetParent()
		local position = parent:GetAbsOrigin()
		position.z = self.height + self.maxHeight * math.sin( (self.distanceTraveled/self.distance) * math.pi )
		parent:SetAbsOrigin( position )
	end
end


function modifier_boss_slime_jump_movement:IsHidden()
	return true
end

function modifier_boss_slime_jump_movement:GetEffectName()
	return "particles/units/heroes/hero_tusk/tusk_walruskick_tgt.vpcf"
end

function modifier_boss_slime_jump_movement:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true}
end

modifier_boss_slime_jump_slow = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_jump_slow", "abilities/slime/boss_slime_jump", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_slime_jump_slow:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff.vpcf"
end

------------------------------------------------------------------------------------

function modifier_boss_slime_jump_slow:OnCreated( kv )
	self.movement_speed_slow = self:GetAbility():GetSpecialValueFor( "jump_slow" )
end

------------------------------------------------------------------------------------

function modifier_boss_slime_jump_slow:DeclareFunctions()
	local funcs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_jump_slow:GetModifierMoveSpeedBonus_Percentage( params )
	return self.movement_speed_slow
end