sohei_dash = class( AbilityBaseClass )

LinkLuaModifier( "modifier_sohei_dash_free_turning", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sohei_dash_movement", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_HORIZONTAL )
LinkLuaModifier( "modifier_sohei_dash_charges", "abilities/sohei/sohei_dash.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function sohei_dash:GetIntrinsicModifierName()
	return "modifier_sohei_dash_free_turning"
end

--------------------------------------------------------------------------------

if IsServer() then
	function sohei_dash:OnUpgrade()
		local caster = self:GetCaster()
		local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )

		if not modifier_charges then
			modifier_charges = caster:AddNewModifier( self:GetCaster(), self, "modifier_sohei_dash_charges", {} )
			modifier_charges:SetStackCount( self:GetSpecialValueFor( "max_charges" ) )
		elseif modifier_charges:GetDuration() <= 0 then
			modifier_charges:SetDuration( self:GetChargeRefreshTime(), true )
			modifier_charges:StartIntervalThink( 0.1 )
		end
	end

--------------------------------------------------------------------------------

	function sohei_dash:GetChargeRefreshTime()
		-- Reduce the charge recovery time if the appropriate talent is learned
		local refreshTime = self:GetSpecialValueFor( "charge_restore_time" )
		local talent = self:GetCaster():FindAbilityByName( "special_bonus_sohei_dash_recharge" )

		if talent and talent:GetLevel() > 0 then
			refreshTime = math.max( refreshTime - talent:GetSpecialValueFor( "value" ), 1 )
		end

		-- put the unit cdr stuff here if we ever get it

		return refreshTime
	end

--------------------------------------------------------------------------------

	function sohei_dash:PerformDash()
		local caster = self:GetCaster()
		local distance = self:GetSpecialValueFor( "dash_distance" )
		local speed = self:GetSpecialValueFor( "dash_speed" )
		local treeRadius = self:GetSpecialValueFor( "tree_radius" )
		local duration = distance / speed

		caster:RemoveModifierByName( "modifier_sohei_dash_movement" )
		caster:EmitSound( "Sohei.Dash" )
		caster:StartGesture( ACT_DOTA_RUN )
		caster:AddNewModifier( nil, nil, "modifier_sohei_dash_movement", {
			duration = duration,
			distance = distance,
			tree_radius = treeRadius,
			speed = speed
		} )
	end

--------------------------------------------------------------------------------

	function sohei_dash:OnSpellStart()
		local caster = self:GetCaster()
		local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )
		local dashDistance = self:GetSpecialValueFor( "dash_distance" )
		local dashSpeed = self:GetSpecialValueFor( "dash_speed" )

		-- since changing stack count deals with cooldown anyway
		-- let's remove the default one
		self:EndCooldown()

		if modifier_charges and not modifier_charges:IsNull() then
			-- Perform the dash if there is at least one charge remaining
			if modifier_charges:GetStackCount() >= 1 then
				modifier_charges:SetStackCount( modifier_charges:GetStackCount() - 1 )

				local shortCD = dashDistance / dashSpeed
				if self:GetCooldownTimeRemaining() < shortCD then
					self:EndCooldown()
					self:StartCooldown( dashDistance / dashSpeed )
				end
			end
		else
			caster:AddNewModifier( caster, self, "modifier_sohei_dash_charges", {
				duration = self:GetChargeRefreshTime()
			} )

			self:EndCooldown()
			self:StartCooldown( self:GetChargeRefreshTime() )
		end

		-- i commented on this in guard but
		-- faking not casting is really just not a great solution
		-- especially if something breaks due to dev fault and suddenly a bread and butter ability isn't
		-- usable
		-- so let's instead give the player some let in this regard and let 'em dash anyway

		self:PerformDash()

		-- cd refund for momentum
		local cdRefund = self:GetSpecialValueFor( "momentum_cd_refund" )

		if cdRefund > 0 then
			local momentum = caster:FindAbilityByName( "sohei_momentum" )

			if momentum and not momentum:IsCooldownReady() then
				local momentumCooldown = momentum:GetCooldownTimeRemaining()
				local refundCooldown = momentumCooldown * ( cdRefund / 100.0 )

				momentum:EndCooldown()
				momentum:StartCooldown( momentumCooldown - refundCooldown )
			end
		end
	end

--------------------------------------------------------------------------------

	function sohei_dash:OnRefresh()
		local modifier_charges = self:GetCaster():FindModifierByName( "modifier_sohei_dash_charges" )

		modifier_charges:SetStackCount( math.min( modifier_charges:GetStackCount() + 1, self:GetSpecialValueFor( "max_charges" ) ) )
	end
end

--------------------------------------------------------------------------------

-- Dash free turning modifier
modifier_sohei_dash_free_turning = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_dash_free_turning:IsDebuff()
	return false
end

function modifier_sohei_dash_free_turning:IsHidden()
	return true
end

function modifier_sohei_dash_free_turning:IsPurgable()
	return false
end

function modifier_sohei_dash_free_turning:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

function modifier_sohei_dash_free_turning:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_sohei_dash_free_turning:GetModifierIgnoreCastAngle()
	return 1
end

--------------------------------------------------------------------------------

-- Dash charges modifier
modifier_sohei_dash_charges = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_dash_charges:IsDebuff()
	return false
end

function modifier_sohei_dash_charges:IsDebuff()
	return false
end

function modifier_sohei_dash_charges:IsHidden()
	return false
end

function modifier_sohei_dash_charges:IsPurgable()
	return false
end

function modifier_sohei_dash_charges:RemoveOnDeath()
	return false
end

function modifier_sohei_dash_charges:DestroyOnExpire()
	return false
end

function modifier_sohei_dash_charges:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sohei_dash_charges:OnCreated()
		self:StartIntervalThink( 0.1 )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_charges:OnRefresh()
		self:StartIntervalThink( 0.1 )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_charges:OnIntervalThink()
		if self:GetRemainingTime() <= 0 then
			self:OnExpire()
		end
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_charges:OnExpire()
		local caster = self:GetCaster()
		local spell = self:GetAbility()

		-- If the maximum charges are reached, stop the modifier's timer
		local max_charges = spell:GetSpecialValueFor( "max_charges" )
		if self:GetStackCount() >= ( max_charges - 1 ) then
			self:SetStackCount( max_charges )
			self:SetDuration( -1, true )
			self:StartIntervalThink( -1 )
		else
			-- Reduce the charge recovery time if the appropriate talent is learned
			local duration = spell:GetChargeRefreshTime()

			self:SetStackCount( self:GetStackCount() + 1 )
			self:SetDuration( duration, true )
			self:StartIntervalThink( 0.1 )
		end
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_charges:OnStackCountChanged( oldCount )
		-- don't bother to run any of this if we're not subtracting stacks
		-- ( adding stacks handles itself )
		local newCount = self:GetStackCount()

		if newCount < oldCount then
			-- we're just starting the thinking again
			-- so we don't bother doing anything if that's already happening
			-- ( otherwise, we'll end up restarting the recharge time )
			if self:GetDuration() <= 0 then
				local duration = self:GetAbility():GetChargeRefreshTime()

				self:SetDuration( duration, true )
				self:StartIntervalThink( 0.1 )
			end

			-- also do cooldown if the count is dead
			-- rip dracula
			if newCount <= 0 then
				local spell = self:GetAbility()
				local remainingTime = self:GetRemainingTime()

				if remainingTime > spell:GetCooldownTimeRemaining() then
					spell:EndCooldown()
					spell:StartCooldown( remainingTime )
				end

				local spellPalm = self:GetParent():FindAbilityByName( "sohei_palm_of_life" )

				if remainingTime > spellPalm:GetCooldownTimeRemaining() then
					spellPalm:EndCooldown()
					spellPalm:StartCooldown( remainingTime )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------

-- Dash movement modifier
modifier_sohei_dash_movement = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_dash_movement:IsDebuff()
	return false
end

function modifier_sohei_dash_movement:IsHidden()
	return true
end

function modifier_sohei_dash_movement:IsPurgable()
	return false
end

function modifier_sohei_dash_movement:IsStunDebuff()
	return false
end

function modifier_sohei_dash_movement:GetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

--------------------------------------------------------------------------------

function modifier_sohei_dash_movement:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}

	return state
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sohei_dash_movement:OnCreated( event )
		-- Movement parameters
		local parent = self:GetParent()
		self.direction = parent:GetForwardVector()
		self.distance = event.distance
		self.speed = event.speed
		self.tree_radius = event.tree_radius

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end

		-- Trail particle
		local trail_pfx = ParticleManager:CreateParticle( "particles/econ/items/juggernaut/bladekeeper_omnislash/_dc_juggernaut_omni_slash_trail.vpcf", PATTACH_CUSTOMORIGIN, parent )
		ParticleManager:SetParticleControl( trail_pfx, 0, parent:GetAbsOrigin() )
		ParticleManager:SetParticleControl( trail_pfx, 1, parent:GetAbsOrigin() + parent:GetForwardVector() * 300 )
		ParticleManager:ReleaseParticleIndex( trail_pfx )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_movement:OnDestroy()
		local parent = self:GetParent()

		parent:FadeGesture( ACT_DOTA_RUN )
		parent:RemoveHorizontalMotionController( self )
		ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_dash_movement:UpdateHorizontalMotion( parent, deltaTime )
		local parentOrigin = parent:GetAbsOrigin()

		local tickSpeed = self.speed * deltaTime
		tickSpeed = math.min( tickSpeed, self.distance )
		local tickOrigin = parentOrigin + ( tickSpeed * self.direction )

		parent:SetAbsOrigin( tickOrigin )

		self.distance = self.distance - tickSpeed

		GridNav:DestroyTreesAroundPoint( tickOrigin, self.tree_radius, false )
	end

--------------------------------------------------------------------------------
	
	function modifier_sohei_dash_movement:OnHorizontalMotionInterrupted()
		self:Destroy()
	end
end