viper_viper_strike_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_viper_viper_strike_silence", "abilities/oaa_viper_strike.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function viper_viper_strike_oaa:GetCastRange( loc, target )
	local caster = self:GetCaster()

	if caster:HasScepter() then
		return self:GetSpecialValueFor( "cast_range_scepter" )
	end

	return self.BaseClass.GetCastRange( self, loc, target )
end

function viper_viper_strike_oaa:GetManaCost( level )
	local caster = self:GetCaster()

	if caster:HasScepter() then
		return self:GetSpecialValueFor( "mana_cost_scepter" )
	end

	return self.BaseClass.GetManaCost( self, level )
end

function viper_viper_strike_oaa:GetCooldown( level )
	local caster = self:GetCaster()

	if caster:HasScepter() then
		return self:GetSpecialValueFor( "cooldown_scepter" )
	end

	return self.BaseClass.GetCooldown( self, level )
end

--------------------------------------------------------------------------------

function viper_viper_strike_oaa:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local originCaster = caster:GetAbsOrigin()

	-- show the particle
	self.partCast = ParticleManager:CreateParticle( "particles/units/heroes/hero_viper/viper_viper_strike_warmup.vpcf", PATTACH_POINT_FOLLOW, caster )
	for i = 1, 4 do
		ParticleManager:SetParticleControlEnt( self.partCast, i, caster, PATTACH_POINT_FOLLOW, "attach_wing_barb_" .. i, originCaster, true )
	end

	return true
end

function viper_viper_strike_oaa:OnAbilityPhaseInterrupted()
	if self.partCast then
		ParticleManager:DestroyParticle( self.partCast, false )
		ParticleManager:ReleaseParticleIndex( self.partCast )
	end
end

--------------------------------------------------------------------------------

function viper_viper_strike_oaa:OnProjectileHit_ExtraData( target, loc, data )
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor( "duration" )

	-- make sure the projectile actually hit the target
	-- and the target is still valid
	-- before applying the rest of the effects
	if target and UnitFilter( target, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), caster:GetTeamNumber() ) and not target:TriggerSpellAbsorb( self ) then
		-- play the sound
		target:EmitSound( "Hero_Viper.ViperStrike.Target" )

		-- apply the standard viper strike modifier
		target:AddNewModifier( caster, self, "modifier_viper_viper_strike_slow", {
			duration = duration,
		} )

		-- apply the silence modifier if the talent is picked
		local talent = caster:FindAbilityByName( "special_bonus_unique_viper_3_oaa" )

		if talent and talent:GetLevel() > 0 then
			target:AddNewModifier( caster, self, "modifier_viper_viper_strike_silence", {
				duration = duration,
			} )
		end
	end

	-- due to the unique way the projectile part works
	-- we manually destroy and clean it up here
	ParticleManager:DestroyParticle( data.part, false )
	ParticleManager:ReleaseParticleIndex( data.part )

	return true
end

--------------------------------------------------------------------------------

function viper_viper_strike_oaa:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local originCaster = caster:GetAbsOrigin()

	-- clean up cast particle
	if self.partCast then
		ParticleManager:ReleaseParticleIndex( self.partCast )
	end

	-- play the sounds
	caster:EmitSound( "Hero_Viper.ViperStrike" )

	local speed = self:GetSpecialValueFor( "projectile_speed" )

	-- show the particle
	-- due to the nature of viper strike's projectile, its particle is handled this way
	local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_viper/viper_viper_strike_beam.vpcf", PATTACH_CUSTOMORIGIN, target )
	ParticleManager:SetParticleControlEnt( part, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true )
	for i = 1, 4 do
		ParticleManager:SetParticleControlEnt( part, i + 1, caster, PATTACH_POINT, "attach_wing_barb_" .. i, originCaster, true )
	end
	ParticleManager:SetParticleControl( part, 6, Vector( speed, 0, 0 ) )

	-- make the projectile
	ProjectileManager:CreateTrackingProjectile( {
		Target = target,
		Source = caster,
		Ability = self,
		--EffectName = "particles/units/heroes/hero_viper/viper_viper_strike.vpcf",
		iMoveSpeed = speed,
		vSourceLoc = originCaster,
		bDodgeable = true,
		ExtraData = {
			part = part,
		},
	} )
end

--------------------------------------------------------------------------------

-- this could probably be the basic silence modifier
-- but this makes it easier to decide on whether or not it should be purgable
modifier_viper_viper_strike_silence = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_viper_viper_strike_silence:IsHidden()
	return false
end

function modifier_viper_viper_strike_silence:IsDebuff()
	return true
end

function modifier_viper_viper_strike_silence:IsStunDebuff()
  return true
end

function modifier_viper_viper_strike_silence:IsPurgable()
	return true
end

--------------------------------------------------------------------------------

function modifier_viper_viper_strike_silence:GetEffectName()
	return "particles/generic_gameplay/generic_silenced.vpcf"
end

function modifier_viper_viper_strike_silence:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------

function modifier_viper_viper_strike_silence:CheckState()
	local state = {
		[MODIFIER_STATE_SILENCED] = true,
	}

	return state
end