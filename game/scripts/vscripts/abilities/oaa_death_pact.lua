clinkz_death_pact_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_clinkz_death_pact_oaa", "abilities/oaa_death_pact.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function clinkz_death_pact_oaa:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local duration = self:GetSpecialValueFor( "duration" )

	-- get the target's current health
	local targetHealth = target:GetHealth()

	-- kill the target
	target:Kill( self, caster )

	-- apply the standard death pact modifier ( does nothing but display duration )
	-- ( and animation too )
	caster:AddNewModifier( caster, self, "modifier_clinkz_death_pact", {
		duration = duration,
	} )

	-- apply the new modifier which actually provides the stats
	-- then set its stack count to the amount of health the target had
	local mod = caster:AddNewModifier( caster, self, "modifier_clinkz_death_pact_oaa", {
		duration = duration,
		stacks = targetHealth,
	} )

	-- play the sounds
	caster:EmitSound( "Hero_Clinkz.DeathPact.Cast" )
	target:EmitSound( "Hero_Clinkz.DeathPact" )

	-- show the particle
	local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_clinkz/clinkz_death_pact.vpcf", PATTACH_ABSORIGIN, target )
	ParticleManager:SetParticleControlEnt( part, 1, caster, PATTACH_ABSORIGIN, "", caster:GetAbsOrigin(), true )
	ParticleManager:ReleaseParticleIndex( part )
end

--------------------------------------------------------------------------------

modifier_clinkz_death_pact_oaa = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:IsHidden()
	return true
end

function modifier_clinkz_death_pact_oaa:IsDebuff()
	return false
end

function modifier_clinkz_death_pact_oaa:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:OnCreated( event )
	local parent = self:GetParent()
	local spell = self:GetAbility()

	-- this has to be done server-side because valve
	if IsServer() then
		-- get the parent's current health before applying anything
		self.parentHealth = parent:GetHealth()

		-- set the modifier's stack count to the target's health, so that we
		-- have access to it on the client
		self:SetStackCount( event.stacks )
	end

	-- get out values
	local healthPct = spell:GetSpecialValueFor( "health_gain_pct" ) * 0.01
	local healthMax = spell:GetSpecialValueFor( "health_gain_max" )
	local damagePct = spell:GetSpecialValueFor( "damage_gain_pct" ) * 0.01
	local damageMax = spell:GetSpecialValueFor( "damage_gain_max" )

	-- retrieve the stack count
	local targetHealth = self:GetStackCount()

	-- make sure the resulting buffs don't exceed the caps
	self.health = targetHealth * healthPct

	if healthMax > 0 then
		self.health = math.min( healthMax, self.health )
	end

	self.damage = targetHealth * damagePct

	if damageMax > 0 then
		self.damage = math.min( damageMax, self.health )
	end

	if IsServer() then
		-- apply the new health and such
		parent:CalculateStatBonus()

		-- add the added health
		parent:SetHealth( self.parentHealth + self.health )
		self.parentHealth = 0
	end
end

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:OnRefresh( event )
	local parent = self:GetParent()
	local spell = self:GetAbility()

	-- this has to be done server-side because valve
	if IsServer() then
		-- get the parent's current health before applying anything
		self.parentHealth = parent:GetHealth()

		-- set the modifier's stack count to the target's health, so that we
		-- have access to it on the client
		self:SetStackCount( event.stacks )
	end

	-- get out values
	local healthPct = spell:GetSpecialValueFor( "health_gain_pct" ) * 0.01
	local healthMax = spell:GetSpecialValueFor( "health_gain_max" )
	local damagePct = spell:GetSpecialValueFor( "damage_gain_pct" ) * 0.01
	local damageMax = spell:GetSpecialValueFor( "damage_gain_max" )

	-- retrieve the stack count
	local targetHealth = self:GetStackCount()

	-- make sure the resulting buffs don't exceed the caps
	self.health = targetHealth * healthPct

	if healthMax > 0 then
		self.health = math.min( healthMax, self.health )
	end

	self.damage = targetHealth * damagePct

	if damageMax > 0 then
		self.damage = math.min( damageMax, self.health )
	end

	if IsServer() then
		-- apply the new health and such
		parent:CalculateStatBonus()

		-- add the added health
		parent:SetHealth( self.parentHealth + self.health )
		self.parentHealth = 0
	end
end

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:GetModifierBaseAttack_BonusDamage( event )
	return self.damage
end

--------------------------------------------------------------------------------

function modifier_clinkz_death_pact_oaa:GetModifierExtraHealthBonus( event )
	return self.health
end