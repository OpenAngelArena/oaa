LinkLuaModifier("modifier_conviction", "scripts/vscripts/abilities/lathaal/conviction.lua", LUA_MODIFIER_MOTION_NONE)

lathaal_conviction = class({})


function lathaal_conviction:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	--add cast range increase for
	local modifier = target:AddNewModifier(caster, self, "modifier_conviction", {duration = self:GetSpecialValueFor("channel_time"), break_distance = self:GetSpecialValueFor("break_distance")})

	local particle = ParticleManager:CreateParticle("particles/hero/lathaal/conviction.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_weapon", Vector(0,0,0), true)
	ParticleManager:SetParticleControlEnt(particle, 4, target, PATTACH_ABSORIGIN_FOLLOW, nil, Vector(0,0,0), true)

	target:EmitSound("Hero_Lathaal.Conviction.Loop")

	modifier:AddParticle(particle, false, true, 1, true, false)
	self.currentTarget = target
end

function lathaal_conviction:OnChannelFinish(bInterrupted)
	--print(self.currentTarget)
	if self.currentTarget then
		self.currentTarget:RemoveModifierByNameAndCaster("modifier_conviction", self:GetCaster())
		self.currentTarget = nil
	end
end

modifier_conviction = class({})

function modifier_conviction:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_conviction:OnCreated(keys)
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.target = self:GetParent()
	self.break_distance = keys.break_distance

	self:StartIntervalThink(1)
end

function modifier_conviction:OnIntervalThink()

	if not self.target:IsAlive() then
		self.caster:InterruptChannel()
	end

	if CalcDistanceBetweenEntityOBB(self.caster, self.target) > self.break_distance then
		self.caster:InterruptChannel()
		self:Destroy()
	end
end

function modifier_conviction:OnDestroy()
	if not IsServer() then return end
	if self:GetParent() and not self:GetParent():HasModifier("modifier_conviction") then
		self:GetParent():StopSound("Hero_Lathaal.Conviction.Loop")
	end
end

function modifier_conviction:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT	
	}

	return funcs
end

function modifier_conviction:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("health_regen")
end

function modifier_conviction:GetCustomTenacity()
	return self:GetAbility():GetSpecialValueFor("status_resistance")
end
