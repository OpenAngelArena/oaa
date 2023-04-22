LinkLuaModifier("modifier_mystic_twister_thinker", "scripts/vscripts/abilities/lathaal/mystic_twister.lua", LUA_MODIFIER_MOTION_NONE)


lathaal_mystic_twister = class({})

function lathaal_mystic_twister:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	caster:EmitSound("Hero_Lathaal.MysticTwister.Cast")
 	self.thinker = CreateModifierThinker(caster, self, "modifier_mystic_twister_thinker", {}, point, caster:GetTeam(), false)
end

function lathaal_mystic_twister:OnChannelFinish(bInterrupted)
	--print(self.thinker)
	if self.thinker then
		self.thinker:StopSound("Hero_Lathaal.MysticTwister.Loop")
		self.thinker:EmitSound("Hero_Lathaal.MysticTwister.End")
		self.thinker:Destroy()
		self.thinker = nil
	end
	self:GetCaster():StopSound("Hero_Lathaal.MysticTwister.Cast")
end

function lathaal_mystic_twister:GetAOERadius()	
	return self:GetSpecialValueFor("radius")
end


modifier_mystic_twister_thinker = class({})

function modifier_mystic_twister_thinker:OnCreated( keys )
	if not IsServer() then return end
	
	local ability = self:GetAbility()
	local interval = ability:GetSpecialValueFor("damage_interval")

	self:GetParent():EmitSound("Hero_Lathaal.MysticTwister.Loop")

	self.caster = self:GetCaster()
	self.damage = (ability:GetAbilityDamage()) * interval
	self.damageType = ability:GetAbilityDamageType()
	self.radius = ability:GetSpecialValueFor("radius")

	local particle = ParticleManager:CreateParticle("particles/hero/lathaal/mystic_twister.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, 0, 0))
	ability:CreateVisibilityNode(self:GetParent():GetAbsOrigin(), self.radius, 0.5)
	self:AddParticle(particle, false, true, 1, true, false)
	self:StartIntervalThink(interval)
end

function modifier_mystic_twister_thinker:OnIntervalThink()

	self:GetAbility():CreateVisibilityNode(self:GetParent():GetAbsOrigin(), self.radius, 0.5)

	local units = FindUnitsInRadius(self.caster:GetTeam(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, 
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for k, unit in pairs(units) do

		local hitParticle = ParticleManager:CreateParticle("particles/hero/lathaal/super_position_base.vpcf", PATTACH_ABSORIGIN, unit)
		EmitSoundOnLocationWithCaster(unit:GetAbsOrigin() + RandomVector(10), "Hero_Lathaal.MysticTwister.Hit", self:GetParent())

		if unit:IsAncient() then 
			ApplyDamage({ 
				victim = unit, 
				attacker = self.caster, 
				damage = self.damage / 2,	
				damage_type = self.damageType })
		else
			--Half Damage to creeps
			ApplyDamage({ 
				victim = unit, 
				attacker = self.caster, 
				damage = self.damage,	
				damage_type = self.damageType })
		end
	end
end

function modifier_mystic_twister_thinker:IsAura() return true end
----------------------------------------------------------------------------------------------------------
function modifier_mystic_twister_thinker:GetModifierAura()  return "modifier_truesight" end
----------------------------------------------------------------------------------------------------------
function modifier_mystic_twister_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
----------------------------------------------------------------------------------------------------------
function modifier_mystic_twister_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
----------------------------------------------------------------------------------------------------------
function modifier_mystic_twister_thinker:GetAuraRadius() return self.radius end