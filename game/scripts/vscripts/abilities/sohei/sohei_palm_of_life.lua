sohei_palm_of_life = class( AbilityBaseClass )

LinkLuaModifier( "modifier_sohei_palm_of_life_movement", "abilities/sohei/sohei_palm_of_life.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------

function sohei_palm_of_life:CastFilterResultTarget( target )
	local caster = self:GetCaster()

	if caster == target then
		return UF_FAIL_CUSTOM
	end

	local ufResult = UnitFilter(
		target,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_FLAG_NONE,
		caster:GetTeamNumber()
	)

	return ufResult
end

--------------------------------------------------------------------------------

function sohei_palm_of_life:GetCustomCastErrorTarget( target )
	if self:GetCaster() == target then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return ""
end

--------------------------------------------------------------------------------

function sohei_palm_of_life:OnHeroCalculateStatBonus()
	local caster = self:GetCaster()

	if caster:HasScepter() or self:IsStolen() then
		self:SetHidden( false )
		if self:GetLevel() <= 0 then
			self:SetLevel( 1 )
		end
	else
		self:SetHidden( true )
	end
end

--------------------------------------------------------------------------------

if IsServer() then
	function sohei_palm_of_life:OnSpellStart()
		local caster = self:GetCaster()
		local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )

		if modifier_charges and not modifier_charges:IsNull() then
			-- Perform the dash if there is at least one charge remaining
			if modifier_charges:GetStackCount() >= 1 and not self:IsStolen() then
				modifier_charges:SetStackCount( modifier_charges:GetStackCount() - 1 )
			end
		end

		-- i commented on this in guard but
		-- faking not casting is really just not a great solution
		-- especially if something breaks due to dev fault and suddenly a bread and butter ability isn't
		-- usable
		-- so let's instead give the player some let in this regard and let 'em dash anyway
		local target = self:GetCursorTarget()
		local speed = self:GetSpecialValueFor( "dash_speed" )
		local treeRadius = self:GetSpecialValueFor( "tree_radius" )
		local duration = self:GetSpecialValueFor( "max_duration" )
		local endDistance = self:GetSpecialValueFor( "end_distance" )
		local doHeal = 0

		local modMomentum = caster:FindModifierByName( "modifier_sohei_momentum_passive" )
		local spellMomentum = caster:FindAbilityByName( "sohei_momentum" )

		if ( ( modMomentum and modMomentum:IsMomentumReady() ) and ( spellMomentum and spellMomentum:IsCooldownReady() ) ) or self:IsStolen() then
			doHeal = 1
		end

		caster:RemoveModifierByName( "modifier_sohei_palm_of_life_movement" )
		caster:RemoveModifierByName( "modifier_sohei_dash_movement" )
		caster:EmitSound( "Sohei.Dash" )
		caster:StartGesture( ACT_DOTA_RUN )
		caster:AddNewModifier( caster, self, "modifier_sohei_palm_of_life_movement", {
			duration = duration,
			target = target:entindex(),
			tree_radius = treeRadius,
			speed = speed,
			endDistance = endDistance,
			doHeal = doHeal
		} )
	end
end

--------------------------------------------------------------------------------

-- Dash movement modifier
modifier_sohei_palm_of_life_movement = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_palm_of_life_movement:IsDebuff()
	return false
end

function modifier_sohei_palm_of_life_movement:IsHidden()
	return true
end

function modifier_sohei_palm_of_life_movement:IsPurgable()
	return false
end

function modifier_sohei_palm_of_life_movement:IsStunDebuff()
	return false
end

function modifier_sohei_palm_of_life_movement:GetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

--------------------------------------------------------------------------------

function modifier_sohei_palm_of_life_movement:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sohei_palm_of_life_movement:OnCreated( event )
		-- Movement parameters
		local parent = self:GetParent()
		self.target = EntIndexToHScript( event.target )
		self.speed = event.speed
		self.tree_radius = event.tree_radius
		self.endDistance = event.endDistance
		self.doHeal = event.doHeal > 0

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end

		-- Trail particle
		local trail_pfx = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/bladekeeper_omnislash/_dc_juggernaut_omni_slash_trail.vpcf", PATTACH_CUSTOMORIGIN, parent )
    ParticleManager:SetParticleControl( trail_pfx, 0, self.target:GetAbsOrigin() )
    ParticleManager:SetParticleControl( trail_pfx, 1, parent:GetAbsOrigin() )
		ParticleManager:ReleaseParticleIndex( trail_pfx )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_palm_of_life_movement:OnDestroy()
		local parent = self:GetParent()

		parent:FadeGesture( ACT_DOTA_RUN )
		parent:RemoveHorizontalMotionController( self )
		ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_palm_of_life_movement:UpdateHorizontalMotion( parent, deltaTime )
		local parentOrigin = parent:GetAbsOrigin()
		local targetOrigin = self.target:GetAbsOrigin()
		local dA = parentOrigin
		dA.z = 0
		local dB = targetOrigin
		dB.z = 0
		local direction = ( dB - dA ):Normalized()

		local tickSpeed = self.speed * deltaTime
		tickSpeed = math.min( tickSpeed, self.endDistance )
		local tickOrigin = parentOrigin + ( tickSpeed * direction )

		parent:SetAbsOrigin( tickOrigin )
		parent:FaceTowards( targetOrigin )

		GridNav:DestroyTreesAroundPoint( tickOrigin, self.tree_radius, false )

		local distance = parent:GetRangeToUnit( self.target )

		if distance <= self.endDistance then
			if self.doHeal then
				-- do the heal
				local spell = self:GetAbility()
				local healAmount = parent:GetHealth() * ( spell:GetSpecialValueFor( "hp_as_heal" ) / 100 )

				self.target:Heal( healAmount, parent )

				self.target:EmitSound( "Sohei.PalmOfLife.Heal" )

				local part = ParticleManager:CreateParticle( "particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.target )
        ParticleManager:SetParticleControl( part, 0, self.target:GetAbsOrigin() )
        ParticleManager:SetParticleControl( part, 1, Vector( self.target:GetModelRadius(), 1, 1 ) )
        ParticleManager:ReleaseParticleIndex( part )

				SendOverheadEventMessage( nil, 10, self.target, healAmount, nil )

				-- undo momentum charge
				local modMomentum = parent:FindModifierByName( "modifier_sohei_momentum_passive" )

				if modMomentum and modMomentum:IsMomentumReady() then
					modMomentum:SetStackCount( 0 )
				end

				local spellMomentum = parent:FindAbilityByName( "sohei_momentum" )

				if spellMomentum then
					spellMomentum:EndCooldown()
					spellMomentum:UseResources( true, true, true )
				end
			end

			-- end it alllllll
			self:Destroy()
		end
	end

--------------------------------------------------------------------------------

	function modifier_sohei_palm_of_life_movement:OnHorizontalMotionInterrupted()
		self:Destroy()
	end
end
