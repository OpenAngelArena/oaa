electrician_energy_absorption = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_energy_absorption", "abilities/electrician/electrician_energy_absorption.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function electrician_energy_absorption:OnSpellStart()
	local caster = self:GetCaster()
	local casterOrigin = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor( "radius" )

	-- grab all enemes around the caster
	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		casterOrigin,
		nil,
		radius,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		FIND_ANY_ORDER,
		false
	)

	-- make the aoe particle, it's dumbshit as of this comment's writing because
	--
	-- i don't need an excuse i'm not doing aesthetics
	local part = ParticleManager:CreateParticle( "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", PATTACH_ABSORIGIN, caster )
	ParticleManager:SetParticleControl( part, 1, Vector( radius, radius, radius ) )
	ParticleManager:SetParticleControl( part, 2, Vector( 1, 1, 1 ) )
	ParticleManager:ReleaseParticleIndex( part )

	-- play sound
	caster:EmitSound( "Hero_StormSpirit.StaticRemnantPlant" )

  -- make particle
--  caster:AddNewModifier( caster, self, "modifier_electrician_shell", {
--    duration = self:GetSpecialValueFor( "move_speed_duration" )
--  } )

	-- don't bother with anything after this if we didnt' hit a single enemy
	if #units > 0 then
		-- grab abilityspecials
		local damage = self:GetSpecialValueFor( "damage" )
		local damageType = self:GetAbilityDamageType()
		local manaBreak = self:GetSpecialValueFor( "mana_break" ) * 0.01
		local manaRestoreCreep = self:GetSpecialValueFor( "creep_mana_restore" )
		local manaRestoreHero = self:GetSpecialValueFor( "hero_mana_restore" )

		-- talent integration
		local talent = self:GetCaster():FindAbilityByName( "special_bonus_electrician_absorption_hero_mana_restore" )

		if talent and talent:GetLevel() > 0 then
			manaRestoreHero = manaRestoreHero * talent:GetSpecialValueFor( "value" )
		end

		-- set up the amount of mana restored by this cast
		local manaRestored = 0

		-- iterate through each unit struck
		for _, target in pairs( units ) do
			-- deal damage
			ApplyDamage( {
				victim = target,
				attacker = caster,
				damage = damage,
				damage_type = damageType,
				damage_flags = DOTA_DAMAGE_FLAG_NONE,
				ability = self,
			} )

			-- track the starting mana
			local manaStart = target:GetMana()

			-- don't bother breaking mana if they have none
			if manaStart > 0 then
				target:ReduceMana( target:GetMaxMana() * manaBreak )

				-- for the mana burn number; restricting to heroes as to
				-- reduce spam, can't ignore illusions tho because
				-- that'd make it too obvious
				if target:IsHero() then
					local manaBurnt = math.floor( manaStart - target:GetMana() )

					local numLength = tostring( manaBurnt ):len() + 1

					local partNum = ParticleManager:CreateParticle( "particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn_msg.vpcf", PATTACH_OVERHEAD_FOLLOW, target )
					ParticleManager:SetParticleControl( partNum, 1, Vector( 1, manaBurnt, 0 ) )
					ParticleManager:SetParticleControl( partNum, 2, Vector( 1, numLength, 0 ) )
					ParticleManager:ReleaseParticleIndex( partNum )
				end
			end

			-- figure out the mana restore amount for this unit
			if target:IsRealHero() then
				manaRestored = manaRestored + manaRestoreHero
			else
				manaRestored = manaRestored + manaRestoreCreep
			end

			-- create a projectile that's just for visual effect
			-- would like to just have a particle here that hits the caster
			-- after like ~0.25 seconds
			ProjectileManager:CreateTrackingProjectile( {
				Ability = self,
				Target = caster,
				Source = target,
				EffectName = "particles/units/heroes/hero_zuus/zuus_base_attack.vpcf",
				iMoveSpeed = caster:GetRangeToUnit( target ) / 0.25,
				iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
				bDodgeable = false,
				flExpireTime = GameRules:GetGameTime() + 10,
			} )

			-- play hit sound
			target:EmitSound( "Hero_StormSpirit.Attack" )
		end

		-- now that we're done with all the hit units
		-- add the mana restored to the caster and
		-- do a number for all mana restored
		caster:GiveMana( manaRestored )
		SendOverheadEventMessage( caster:GetPlayerOwner(), OVERHEAD_ALERT_MANA_ADD, caster, manaRestored, nil )

		-- give the speed modifier
		caster:AddNewModifier( caster, self, "modifier_electrician_energy_absorption", {
			duration = self:GetSpecialValueFor( "move_speed_duration" )
		} )
	end
end

--------------------------------------------------------------------------------

modifier_electrician_energy_absorption = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:IsDebuff()
	return false
end

function modifier_electrician_energy_absorption:IsHidden()
	return false
end

function modifier_electrician_energy_absorption:IsPurgable()
	return true
end

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:OnCreated( event )
  local parent = self:GetParent()
  self.partShell = ParticleManager:CreateParticle( "particles/hero/electrician/electrician_energy_absorbtion.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
  ParticleManager:SetParticleControlEnt( self.partShell, 1, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true )

	self.moveSpeed = self:GetAbility():GetSpecialValueFor( "move_speed_bonus" )
end

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:OnRefresh( event )
	self.moveSpeed = self:GetAbility():GetSpecialValueFor( "move_speed_bonus" )
  -- destroy the shield particles
  ParticleManager:DestroyParticle( self.partShell, false )
  ParticleManager:ReleaseParticleIndex( self.partShell )
end

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:OnDestroy()
  -- destroy the shield particles
  ParticleManager:DestroyParticle( self.partShell, false )
  ParticleManager:ReleaseParticleIndex( self.partShell )
end

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:DeclareFunctions()
	local func = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	}

	return func
end

--------------------------------------------------------------------------------

function modifier_electrician_energy_absorption:GetModifierMoveSpeedBonus_Constant( event )
	return self.moveSpeed
end
