LinkLuaModifier("modifier_divine_intervention", "scripts/vscripts/abilities/lathaal/divine_intervention.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_divine_intervention_armor", "scripts/vscripts/abilities/lathaal/divine_intervention.lua", LUA_MODIFIER_MOTION_NONE)

lathaal_divine_intervention = class({})


function lathaal_divine_intervention:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	if target:TriggerSpellAbsorb(self) then
		caster:InterruptChannel()
		caster:Interrupt()
		return
	end

	target:TriggerSpellReflect(self)
	-- add cast range increase here for break
	local modifier = target:AddNewModifier(caster, self, "modifier_divine_intervention", {duration = self:GetSpecialValueFor("channel_time"), break_distance = self:GetSpecialValueFor("break_distance")})

	local ministun = target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.25})

	local particle = ParticleManager:CreateParticle("particles/hero/lathaal/divine_intervention.vpcf", PATTACH_POINT_FOLLOW, caster)
 	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_weapon", Vector(0,0,0), true)
 	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
 	--ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())
 	--ParticleManager:SetParticleControl(particle, 4, target:GetAbsOrigin())
 	ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_ABSORIGIN, "follow_origin", Vector(0,0,0), true)
 	ParticleManager:SetParticleControlEnt(particle, 4, target, PATTACH_ABSORIGIN, "follow_origin", Vector(0,0,0), true)


 	target:EmitSound("Hero_Lathaal.DivineIntervention.Loop")
 	modifier:AddParticle(particle, false, true, 1, true, false)
 	self.currentTarget = target


 	
end

function lathaal_divine_intervention:OnChannelFinish(bInterrupted)
	--print(self.currentTarget)
	if not IsServer() then return end
	if self.currentTarget then
		if not bInterrupted and self.currentTarget:HasModifier("modifier_divine_intervention") then 
			self.currentTarget:FindModifierByName("modifier_divine_intervention"):ApplyDivineEffects()
		end
		self.currentTarget:RemoveModifierByNameAndCaster("modifier_divine_intervention", self:GetCaster())
		self.currentTarget = nil
	end
end

modifier_divine_intervention = class({})

function modifier_divine_intervention:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_divine_intervention:OnCreated( keys )
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.target = self:GetParent()
	self.break_distance = keys.break_distance
	self.damageType = self:GetAbility():GetAbilityDamageType()
	self.armorLossDuration = self:GetAbility():GetSpecialValueFor("debuff_duration")

	local modifier = self.target:FindModifierByName("modifier_divine_intervention_armor")
	if not modifier then 
		modifier = self.target:AddNewModifier(self.caster, self:GetAbility(), "modifier_divine_intervention_armor", {duration = self.armorLossDuration})
		modifier:SetStackCount(0)
	end
	self:StartIntervalThink(1)
end

function modifier_divine_intervention:OnIntervalThink()
	if not self.target:IsAlive() then
		self.caster:InterruptChannel()
	end

	if CalcDistanceBetweenEntityOBB(self.caster, self.target) > self.break_distance then
		self.caster:InterruptChannel()
		self:Destroy()
	end

	if not self.caster:CanEntityBeSeenByMyTeam(self.target) then 
		self.caster:InterruptChannel()
		self:Destroy()
	end

	self:ApplyDivineEffects()
end

function modifier_divine_intervention:ApplyDivineEffects()
	local modifier = self.target:AddNewModifier(self.caster, self:GetAbility(), "modifier_divine_intervention_armor", {duration = self.armorLossDuration})
	modifier:SetStackCount(modifier:GetStackCount() + 1)

	local damage = (self.target:GetMaxHealth() / 100) * self:GetAbility():GetSpecialValueFor("percent_damage")
	ApplyDamage({
		victim = self.target, 
		attacker = self:GetCaster(), 
		damage = damage, 
		damage_type = self.damageType })
end

function modifier_divine_intervention:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Lathaal.DivineIntervention.Loop")
end

modifier_divine_intervention_armor = class({})

function modifier_divine_intervention_armor:OnCreated( keys )
	if not IsServer() then return end
end

function modifier_divine_intervention_armor:DeclareFunctions( )
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_divine_intervention_armor:GetModifierPhysicalArmorBonus( )
	return - self:GetAbility():GetSpecialValueFor("initial_armor") - (self:GetStackCount() * self:GetAbility():GetSpecialValueFor("armor_per_second"))
end

function modifier_divine_intervention_armor:GetModifierMoveSpeedBonus_Percentage( )
	return - self:GetAbility():GetSpecialValueFor("initial_slow") - (self:GetStackCount() * self:GetAbility():GetSpecialValueFor("slow_per_second"))
end