item_siege_mode = class({})

LinkLuaModifier( "modifier_item_siege_mode_siege", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function item_siege_mode:GetAbilityTextureName()
	local baseName = self.BaseClass.GetAbilityTextureName( self )

	local activeName = ""

	if self.mod and not self.mod:IsNull() then
		activeName = "_active"
	end

	return baseName .. activeName
end

--------------------------------------------------------------------------------

function item_siege_mode:GetIntrinsicModifierName()
	-- we're not modifying the passive benefits at all
	-- ( besides the numbers )
	-- so we can just reuse the normal dragon lance modifier
	return "modifier_item_dragon_lance"
end

--------------------------------------------------------------------------------

function item_siege_mode:OnSpellStart()
	local caster = self:GetCaster()

	-- if we have the modifier while this thing is "toggled"
	-- ( which we should, but 'should' isn't a concept in programming )
	-- remove it
	local mod = caster:FindModifierByName( "modifier_item_siege_mode_siege" )

	if mod and not mod:IsNull() then
		mod:Destroy()

		caster:EmitSound( "OAA_Item.SiegeMode.Deactivate" )
	else
		-- if it isn't toggled, add the modifier and keep track of it
		caster:AddNewModifier( caster, self, "modifier_item_siege_mode_siege", {} )

		caster:EmitSound( "OAA_Item.SiegeMode.Activate" )
	end
end

--------------------------------------------------------------------------------

modifier_item_siege_mode_siege = class({})

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:IsHidden()
	return false
end

function modifier_item_siege_mode_siege:IsDebuff()
	return false
end

function modifier_item_siege_mode_siege:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_fortune_purge_root_pnt.vpcf"
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:OnCreated( event )
	local spell = self:GetAbility()

	spell.mod = self

	self.atkRange = spell:GetSpecialValueFor( "siege_attack_range" )
	self.castRange = spell:GetSpecialValueFor( "siege_cast_range" )
	self.atkDmg = spell:GetSpecialValueFor( "siege_damage_bonus" )
	self.atkSpd = spell:GetSpecialValueFor( "siege_atkspd_bonus" )
	self.splashRadius = spell:GetSpecialValueFor( "siege_aoe" )
	self.splashDmg = spell:GetSpecialValueFor( "siege_splash" )
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:OnRefresh( event )
	local spell = self:GetAbility()

	spell.mod = self

	self.atkRange = spell:GetSpecialValueFor( "siege_attack_range" )
	self.castRange = spell:GetSpecialValueFor( "siege_cast_range" )
	self.atkDmg = spell:GetSpecialValueFor( "siege_damage_bonus" )
	self.atkSpd = spell:GetSpecialValueFor( "siege_atkspd_bonus" )
	self.splashRadius = spell:GetSpecialValueFor( "siege_aoe" )
	self.splashDmg = spell:GetSpecialValueFor( "siege_splash" )
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:OnRemoved()
	local spell = self:GetAbility()

	if spell and not spell:IsNull() then
		spell.mod = nil
	end
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:GetModifierPreAttack_BonusDamage( event )
	local spell = self:GetAbility()

	return self.atkDmg or spell:GetSpecialValueFor( "siege_damage_bonus" )
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:GetModifierAttackSpeedBonus_Constant( event )
	local spell = self:GetAbility()

	return self.atkSpd or spell:GetSpecialValueFor( "siege_atkspd_bonus" )
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:GetModifierAttackRangeBonus( event )
	local spell = self:GetAbility()
	local parent = self:GetParent()

	if parent:IsRangedAttacker() then
		return self.atkRange or spell:GetSpecialValueFor( "siege_attack_range" )
	end

	return 0
end

--------------------------------------------------------------------------------

function modifier_item_siege_mode_siege:GetModifierCastRangeBonus( event )
	local spell = self:GetAbility()

	return self.castRange or spell:GetSpecialValueFor( "siege_cast_range" )
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_item_siege_mode_siege:OnAttackLanded( event )
		local parent = self:GetParent()

		-- i can just use code from greater power treads here!
		-- yaaaaay
		if event.attacker == parent then
			local target = event.target

			-- make sure the initial target is an appropriate unit to split off of
			-- ( so no wards, items, or towers )
			local parentTeam = parent:GetTeamNumber()
			local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local targetType = bit.bor( DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC )
			local targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

			-- if not, cancel
			if UnitFilter( target, targetTeam, targetType, targetFlags, parentTeam ) ~= UF_SUCCESS then
				return
			end

			local spell = self:GetAbility()
			local targetOrigin = target:GetAbsOrigin()

			-- set the targeting requirements for the actual targets
			targetTeam = spell:GetAbilityTargetTeam()
			targetType = spell:GetAbilityTargetType()
			targetFlags = spell:GetAbilityTargetFlags()

			-- get the radius
			local radius = self.splashRadius or spell:GetSpecialValueFor( "siege_aoe" )

			-- find all appropriate targets around the initial target
			local units = FindUnitsInRadius(
				parentTeam,
				targetOrigin,
				nil,
				radius,
				targetTeam,
				targetType,
				targetFlags,
				FIND_ANY_ORDER,
				false
			)

			-- remove the initial target from the list
			for k, unit in pairs( units ) do
				if unit == target then
					table.remove( units, k )
					break
				end
			end

			-- get the wearer's damage
			local damage = event.original_damage

			-- get the damage modifier
			local damageMod = self.splashDmg or spell:GetSpecialValueFor( "siege_splash" )

			damageMod = damageMod * 0.01

			-- apply the damage modifier
			damage = damage * damageMod

			-- iterate through all targets
			for k, unit in pairs( units ) do
				-- inflict damage
				-- DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS prevents spell amp and spell lifesteal
				ApplyDamage( {
					victim = unit,
					attacker = self:GetCaster(),
					damage = damage,
					damage_type = DAMAGE_TYPE_PHYSICAL,
					damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS,
					ability = self,
				} )
			end

			-- play the particle
			local part = ParticleManager:CreateParticle( "particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, target )
			ParticleManager:SetParticleControl( part, 3, targetOrigin )
			ParticleManager:ReleaseParticleIndex( part )

			target:EmitSound( "OAA_Item.SiegeMode.Explosion" )
		end
	end
end

--------------------------------------------------------------------------------

item_siege_mode_2 = item_siege_mode
