dragon_knight_elder_dragon_form_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_dragon_knight_elder_dragon_form_oaa", "abilities/oaa_elder_dragon_form.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

-- this should probably be moved elsewhere somewhere down the line
-- probably somewhere where anything prng can access it
dragon_knight_elder_dragon_form_oaa.prngTable = {}
dragon_knight_elder_dragon_form_oaa.prngTable[5] = 0.038
dragon_knight_elder_dragon_form_oaa.prngTable[10] = 0.01475
dragon_knight_elder_dragon_form_oaa.prngTable[15] = 0.03221
dragon_knight_elder_dragon_form_oaa.prngTable[20] = 0.0557
dragon_knight_elder_dragon_form_oaa.prngTable[25] = 0.08475
dragon_knight_elder_dragon_form_oaa.prngTable[30] = 0.11895
dragon_knight_elder_dragon_form_oaa.prngTable[35] = 0.14628
dragon_knight_elder_dragon_form_oaa.prngTable[40] = 0.18128
dragon_knight_elder_dragon_form_oaa.prngTable[45] = 0.21867
dragon_knight_elder_dragon_form_oaa.prngTable[50] = 0.25701
dragon_knight_elder_dragon_form_oaa.prngTable[55] = 0.29509
dragon_knight_elder_dragon_form_oaa.prngTable[60] = 0.33324
dragon_knight_elder_dragon_form_oaa.prngTable[65] = 0.38109
dragon_knight_elder_dragon_form_oaa.prngTable[70] = 0.42448
dragon_knight_elder_dragon_form_oaa.prngTable[75] = 0.46134
dragon_knight_elder_dragon_form_oaa.prngTable[80] = 0.50276

--------------------------------------------------------------------------------

-- this makes the ability passive when it hits level 5
function dragon_knight_elder_dragon_form_oaa:GetBehavior()
	if self:GetLevel() >= 5 then
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end

	return self.BaseClass.GetBehavior( self )
end

--------------------------------------------------------------------------------

-- this is meant to accompany the above, removing the mana cost and cooldown
-- from the tooltip when it becomes passive
function dragon_knight_elder_dragon_form_oaa:GetCooldown( level )
	if self:GetLevel() >= 5 or level >= 5 then
		return 0
	end

	return self.BaseClass.GetCooldown( self, level )
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:GetManaCost( level )
	if self:GetLevel() >= 5 or level >= 5 then
		return 0
	end

	return self.BaseClass.GetManaCost( self, level )
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:OnSpellStart()
	local caster = self:GetCaster()
	local level = self:GetLevel()
	local duration = self:GetSpecialValueFor( "duration" )

	-- apply the standard dragon form modifier ( for movespeed and the model change )
	caster:AddNewModifier( caster, self, "modifier_dragon_knight_dragon_form", { duration = duration, } )

	-- apply the corrosive breath modifier, don't need to check its level really
	caster:AddNewModifier( caster, self, "modifier_dragon_knight_corrosive_breath", { duration = duration, } )

	-- apply the leveled modifiers
	if level >= 2 then
		caster:AddNewModifier( caster, self, "modifier_dragon_knight_splash_attack", { duration = duration, } )
	end

	if level >= 3 then
		caster:AddNewModifier( caster, self, "modifier_dragon_knight_frost_breath", { duration = duration, } )
	end
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:GetIntrinsicModifierName()
	-- adds the modifier in change of automatically transforming dk
	-- when edf hits level 5 actually no level 4
	-- since now this is also in charge of rage
	if self:GetLevel() >= 4 then
		return "modifier_dragon_knight_elder_dragon_form_oaa"
	end
end

--------------------------------------------------------------------------------

function dragon_knight_elder_dragon_form_oaa:OnUpgrade()
	-- we need to refresh the passive modifier to cause it to instantly
	-- transform dk on upgrade
	if self:GetLevel() >= 5 then
		local caster = self:GetCaster()

		-- adding it again works in the off chance the modifier is somehow removed
		caster:AddNewModifier( caster, self, "modifier_dragon_knight_elder_dragon_form_oaa", {} )
	end
end

--------------------------------------------------------------------------------

modifier_dragon_knight_elder_dragon_form_oaa = class( ModifierBaseClass )

-- table of edf modifiers
modifier_dragon_knight_elder_dragon_form_oaa.edfMods = {
	"modifier_dragon_knight_dragon_form",
	"modifier_dragon_knight_corrosive_breath",
	"modifier_dragon_knight_splash_attack",
	"modifier_dragon_knight_frost_breath",
}

--------------------------------------------------------------------------------

function modifier_dragon_knight_elder_dragon_form_oaa:IsHidden()
	return true
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsDebuff()
	return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:IsPurgable()
	return false
end

function modifier_dragon_knight_elder_dragon_form_oaa:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_dragon_knight_elder_dragon_form_oaa:OnCreated( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- apply all the edf modifiers on creation if level 5
		if spell:GetLevel() >= 5 then
			for _, modName in ipairs( self.edfMods ) do
				local mod = parent:FindModifierByName( modName )

				if not mod then
					parent:AddNewModifier( parent, spell, modName, {} )
				else
					-- if dk already has 'em, just set their duration to "permanent"
					-- so no special effect happens on level up if he's already transformed
					mod:SetDuration( -1, true )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnRefresh( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		-- apply all the edf modifiers on creation if level 5
		if spell:GetLevel() >= 5 then
			for _, modName in pairs( self.edfMods ) do
				local mod = parent:FindModifierByName( modName )

				if not mod then
					parent:AddNewModifier( parent, spell, modName, {} )
				else
					-- if dk already has 'em, just set their duration to "permanent"
					-- so no special effect happens on level up if he's already transformed
					mod:SetDuration( -1, true )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:DeclareFunctions()
		local funcs = {
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_EVENT_ON_RESPAWN,
		}

		return funcs
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnAttackLanded( event )
		local parent = self:GetParent()

		if event.attacker == parent then
			local spell = self:GetAbility()

			if spell:GetLevel() == 4 then
				-- no rage while broken
				if parent:PassivesDisabled() then
					return
				end

				local chance = spell:GetSpecialValueFor( "rage_chance" )

				-- we're using the modifier's stack to store the amount of prng failures
				-- this could be something else but since this modifier is hidden anyway ...
				local prngMult = self:GetStackCount() + 1

				-- compared prng to slightly less prng
				if RandomFloat( 0.0, 1.0 ) <= ( spell.prngTable[chance] * prngMult ) then
					-- reset failure count
					self:SetStackCount( 0 )

					local duration = spell:GetSpecialValueFor( "rage_duration" )

					-- check if the ability is already active, and if so, grab the current
					-- duration
					local mod = parent:FindModifierByName( "modifier_dragon_knight_dragon_form" )

					if mod then
						duration = duration + mod:GetRemainingTime()
					end

					-- apply the edf modifiers with the new duration
					for _, modName in pairs( self.edfMods ) do
						parent:AddNewModifier( parent, spell, modName, { duration = duration } )
					end
				else
					-- increment failure count
					self:SetStackCount( prngMult )
				end
			end
		end
	end

--------------------------------------------------------------------------------

	function modifier_dragon_knight_elder_dragon_form_oaa:OnRespawn( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()

		if event.unit == parent and spell:GetLevel() >= 5 then
			-- apply the edf modifiers on respawn
			for _, modName in pairs( self.edfMods ) do
				parent:AddNewModifier( parent, spell, modName, {} )
			end
		end
	end
end