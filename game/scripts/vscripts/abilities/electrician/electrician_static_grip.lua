electrician_static_grip = class( AbilityBaseClass )

LinkLuaModifier( "modifier_electrician_static_grip", "abilities/electrician/electrician_static_grip.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_electrician_static_grip_movement", "abilities/electrician/electrician_static_grip.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------

function electrician_static_grip:GetChannelTime()
	if self.modGrip and not self.modGrip:IsNull() then
		return self.modGrip:GetDuration()
	end

	return 0
end

--------------------------------------------------------------------------------

function electrician_static_grip:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- trigger and get blocked by linkens
  if not target:TriggerSpellAbsorb( self ) then
    local durationMax = self:GetSpecialValueFor( "channel_time" )
    durationMax = target:GetValueChangedByStatusResistance( durationMax )

    -- create the stun modifier on target
    target:AddNewModifier( caster, self, "modifier_electrician_static_grip", { duration = durationMax } )

    -- create the movement modifier on caster
    caster:AddNewModifier( caster, self, "modifier_electrician_static_grip_movement", { target = target:entindex(), duration = durationMax } )
  end
end

--------------------------------------------------------------------------------

function electrician_static_grip:OnChannelFinish( interrupted )
	-- destroy the stun modifier if the channel is interrupted
	if self.modGrip and not self.modGrip:IsNull() then
		self.modGrip:Destroy()
	end
end

--------------------------------------------------------------------------------

modifier_electrician_static_grip = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:IsDebuff()
	return true
end

function modifier_electrician_static_grip:IsHidden()
	return false
end

function modifier_electrician_static_grip:IsPurgable()
	return false
end

function modifier_electrician_static_grip:IsPurgeException()
	return true
end

function modifier_electrician_static_grip:IsStunDebuff()
	return true
end

-- necessary to override MODIFIER_STATE_INVISIBLE reliably
function modifier_electrician_static_grip:GetPriority()
	return MODIFIER_PRIORITY_ULTRA
end

function modifier_electrician_static_grip:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_FROZEN] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:DeclareFunctions()
	local func = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}

	return func
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:GetModifierProvidesFOWVision()
	return 1
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:OnCreated( event )
	local spell = self:GetAbility()

	-- link modifier to spell
	-- this can't be done in OnSpellStuff as that's server-side only
	-- so we have to make sure that at least this part of OnCreated
	-- is ran on the client
	spell.modGrip = self

	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()

		-- grab ability specials
		local damageInterval = spell:GetSpecialValueFor( "damage_interval" )
		self.distBreak = spell:GetCastRange( parent:GetAbsOrigin(), parent ) + spell:GetSpecialValueFor( "link_buffer" )
		self.damagePerInterval = spell:GetSpecialValueFor( "damage_per_second" ) * damageInterval
		self.damageType = spell:GetAbilityDamageType()

		-- create the particle
		self.part = ParticleManager:CreateParticle( "particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf", PATTACH_POINT_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt( self.part, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true )
		ParticleManager:SetParticleControlEnt( self.part, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true )

		-- play sound
		parent:EmitSound( "Hero_StormSpirit.ElectricVortex" )

    -- cast animation
    caster:StartGesture( ACT_DOTA_CAST_ABILITY_3 )

		-- start thinking
		self:StartIntervalThink( damageInterval )
	end
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip:OnRefresh( event )
	local spell = self:GetAbility()

	-- link modifier to spell
	-- this can't be done in OnSpellStuff as that's server-side only
	-- so we have to make sure that at least this part of OnRefresh
	-- is ran on the client
	spell.modGrip = self

	if IsServer() then
		local parent = self:GetParent()
		local caster = self:GetCaster()

		-- grab ability specials
		local damageInterval = spell:GetSpecialValueFor( "damage_interval" )
		self.distBreak = spell:GetCastRange( parent:GetAbsOrigin(), parent ) + spell:GetSpecialValueFor( "link_buffer" )
		self.damagePerInterval = spell:GetSpecialValueFor( "damage_per_second" ) * damageInterval
		self.damageType = spell:GetAbilityDamageType()

		-- play sound
		parent:EmitSound( "Hero_StormSpirit.ElectricVortex" )

		-- start thinking
		self:StartIntervalThink( damageInterval )
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_electrician_static_grip:OnDestroy()
		-- clean up the particle
		ParticleManager:DestroyParticle( self.part, false )
		ParticleManager:ReleaseParticleIndex( self.part )

		-- end the sound prematurely
		self:GetParent():StopSound( "Hero_StormSpirit.ElectricVortex" )

		-- remove the movement modifier on caster
		self:GetCaster():RemoveModifierByName( "modifier_electrician_static_grip_movement" )

		-- end the channel
		-- with the new channel duration method this seems superfluous
		-- but i'll leave this commented out in case it isn't
		--self:GetAbility():EndChannel( true )
	end

--------------------------------------------------------------------------------

	function modifier_electrician_static_grip:OnIntervalThink()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local spell = self:GetAbility()

		ApplyDamage( {
			victim = parent,
			attacker = caster,
			damage = self.damagePerInterval,
			damage_type = self.damageType,
			damage_flags = DOTA_DAMAGE_FLAG_NONE,
			ability = spell,
		} )
	end
end

--------------------------------------------------------------------------------

modifier_electrician_static_grip_movement = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_electrician_static_grip_movement:IsDebuff()
	return false
end

function modifier_electrician_static_grip_movement:IsHidden()
	return true
end

function modifier_electrician_static_grip_movement:IsPurgable()
	return false
end

function modifier_electrician_static_grip_movement:GetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

--------------------------------------------------------------------------------

function modifier_electrician_static_grip_movement:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_electrician_static_grip_movement:OnCreated( event )
		local parent = self:GetParent()
		local spell = self:GetAbility()
		self.target = EntIndexToHScript( event.target )
		self.speed = spell:GetSpecialValueFor( "pull_speed" )
		self.pullBuffer = 150 --spell:GetSpecialValueFor( "pull_buffer" )

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end
	end

--------------------------------------------------------------------------------

	function modifier_electrician_static_grip_movement:OnDestroy()
		local parent = self:GetParent()

		parent:RemoveHorizontalMotionController( self )
		ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
	end

--------------------------------------------------------------------------------

	function modifier_electrician_static_grip_movement:UpdateHorizontalMotion( parent, deltaTime )
		-- we're aiming to drag the caster towards a point on the map
		-- which is an offset of the target's location pullBuffer distance away
		-- thus, first we need to get the vector from the target to the caster
		-- man does the use of 3D vectors make 2D math silly
		local parentOrigin = parent:GetAbsOrigin()
		local targetOrigin = self.target:GetAbsOrigin()
		local distance = ( targetOrigin - parentOrigin ):Length2D()

		-- if we're already at or past the buffer, we don't need to do any of this
		if distance > self.pullBuffer then
			local dA = parentOrigin
			dA.z = 0
			local dB = targetOrigin
			dB.z = 0
			-- then we need to create the actual end location, by Normalizing the vector
			-- from target to caster ( setting its distance to 1 ) and then multiplying it
			-- by pullBuffer so that make it the proper length
			-- then we offset it from the target origin by adding it to it
			local endOrigin = dB + ( ( dA - dB ):Normalized() * self.pullBuffer )
			-- now that we know the end location, set up the vector from the parent origin
			-- to it
			local travelVector = endOrigin - dA
			local direction = travelVector:Normalized()
			local distanceBuffer = travelVector:Length2D()

			local tickSpeed = self.speed * deltaTime
			tickSpeed = math.min( tickSpeed, distanceBuffer )
			local tickOrigin = parentOrigin + ( tickSpeed * direction )

			parent:SetAbsOrigin( tickOrigin )
			parent:FaceTowards( targetOrigin )
		end
	end

--------------------------------------------------------------------------------

	function modifier_electrician_static_grip_movement:OnHorizontalMotionInterrupted()
		self:Destroy()
	end
end
