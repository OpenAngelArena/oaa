sohei_guard = class( AbilityBaseClass )

LinkLuaModifier( "modifier_sohei_guard_reflect", "abilities/sohei/sohei_guard.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_sohei_guard_knockback", "abilities/sohei/sohei_guard.lua", LUA_MODIFIER_MOTION_HORIZONTAL )

--------------------------------------------------------------------------------

-- unfinished talent stuff
function sohei_guard:CastFilterResultTarget( target )
	local caster = self:GetCaster()

	if ( target ~= caster ) and caster:IsStunned() then
		return UF_FAIL_CUSTOM
	end

	local ufResult = UnitFilter(
		target,
		self:GetAbilityTargetTeam(),
		self:GetAbilityTargetType(),
		self:GetAbilityTargetFlags(),
		caster:GetTeamNumber()
	)

	return ufResult
end

--------------------------------------------------------------------------------

-- unfinished talent stuff
function sohei_guard:GetCustomCastErrorTarget( target )
	local caster = self:GetCaster()

	if ( target ~= caster ) and caster:IsStunned() then
		return "#dota_hud_error_cant_cast_on_ally_while_stunned"
	end

	return ""
end

--------------------------------------------------------------------------------

if IsServer() then
	-- always preferrable to stop a cast instead of faking not casting
	function sohei_guard:GetBehavior()
		local behavior = self.BaseClass.GetBehavior( self )
		local caster = self:GetCaster()
		local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )
		local talent = caster:FindAbilityByName( "special_bonus_sohei_guard_allycast" )

		-- unfinished talent stuff
		if talent and talent:GetLevel() > 0 then
			behavior = bit.bor( DOTA_ABILITY_BEHAVIOR_UNIT_TARGET, DOTA_ABILITY_BEHAVIOR_IMMEDIATE, DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL )
		end

		if modifier_charges and modifier_charges:GetStackCount() >= 2 then
			behavior = bit.bor( behavior, DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE )
		end

		return behavior
	end

--------------------------------------------------------------------------------

	function sohei_guard:OnSpellStart()
		local caster = self:GetCaster()
		local target = self:GetCursorTarget() or caster

		-- Check if there are enough charges to cast the ability, if the caster is stunned

		if caster:IsStunned() then
			local modifier_charges = caster:FindModifierByName( "modifier_sohei_dash_charges" )

			if modifier_charges then
				modifier_charges:SetStackCount( modifier_charges:GetStackCount() - 2 )
			end
			-- there could be the whole thing about faking the ability not casting here
			-- if there aren't enough charges
			-- but really, that still procs magic wand and stuff
		end

		-- Hard Dispel
		target:Purge( false, true, false, true, true )

		-- Start an animation
    caster:StartGestureWithPlaybackRate( ACT_DOTA_OVERRIDE_ABILITY_1 , 1)

		-- Play guard sound
		target:EmitSound( "Sohei.Guard" )

		--Apply Linken's + Lotus Orb + Attack reflect modifier for 2 seconds
		local duration = self:GetSpecialValueFor("guard_duration")
		target:AddNewModifier(caster, self, "modifier_item_lotus_orb_active", { duration = duration })
		target:AddNewModifier(caster, self, "modifier_sohei_guard_reflect", { duration = duration })

		-- Stop the animation when it's done
		Timers:CreateTimer(duration, function()
			caster:FadeGesture( ACT_DOTA_OVERRIDE_ABILITY_1 )
		end)

		-- If there is at least one target to attack, hit it
		local talent = caster:FindAbilityByName("special_bonus_sohei_guard_knockback")

		if talent and talent:GetLevel() > 0 then
			local radius = talent:GetSpecialValueFor( "value" )
			local pushTargets = FindUnitsInRadius(
				caster:GetTeamNumber(),
				target:GetAbsOrigin(),
				nil,
				radius,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE +	DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ATTACK_IMMUNE,
				FIND_ANY_ORDER,
				false
			)

			for _, pushTarget in pairs(pushTargets) do
				self:PushAwayEnemy(pushTarget)
			end
		end
	end

--------------------------------------------------------------------------------

	function sohei_guard:PushAwayEnemy( target )
		local caster = self:GetCaster()
		local casterposition = caster:GetAbsOrigin()
		local targetposition = target:GetAbsOrigin()
		local radius = caster:FindAbilityByName( "special_bonus_sohei_guard_knockback" ):GetSpecialValueFor("value" )

		local vVelocity = casterposition - targetposition
		vVelocity.z = 0.0

		local distance = radius - vVelocity:Length2D() + caster:GetPaddedCollisionRadius()
		local duration = distance / self:GetSpecialValueFor( "knockback_speed" )

		target:AddNewModifier( caster, self, "modifier_sohei_guard_knockback", {
			duration = duration,
			distance = distance,
			tree_radius = target:GetPaddedCollisionRadius()
		} )
	end

--------------------------------------------------------------------------------

	function sohei_guard:OnProjectileHit_ExtraData( target, location, extra_data )
		target:EmitSound( "Sohei.GuardHit" )
		ApplyDamage( {
			victim = target,
			attacker = self:GetCaster(),
			damage = extra_data.damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
			ability = self
		} )
	end
end

--------------------------------------------------------------------------------

-- Guard projectile reflect modifier
modifier_sohei_guard_reflect = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_sohei_guard_reflect:IsDebuff()
	return false
end

function modifier_sohei_guard_reflect:IsHidden()
	return false
end

function modifier_sohei_guard_reflect:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

--[[
function modifier_sohei_guard_reflect:GetEffectName()
	return "particles/items3_fx/lotus_orb_shell.vpcf"
end

function modifier_sohei_guard_reflect:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
]]--

--------------------------------------------------------------------------------

function modifier_sohei_guard_reflect:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_AVOID_DAMAGE,
		MODIFIER_PROPERTY_ABSORB_SPELL,
		--MODIFIER_PROPERTY_REFLECT_SPELL,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}

	return funcs
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sohei_guard_reflect:GetModifierAvoidDamage( event )
		if event.ranged_attack == true and event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
			return 1
		end

		return 0
	end

--------------------------------------------------------------------------------

	function modifier_sohei_guard_reflect:GetAbsorbSpell( event )
		return 1
	end

--------------------------------------------------------------------------------

	-- why does this do nothing
	function modifier_sohei_guard_reflect:GetReflectSpell( event )
		return 1
	end

--------------------------------------------------------------------------------

	function modifier_sohei_guard_reflect:OnAttackLanded( event )
		if event.target == self:GetParent() then
			if event.ranged_attack == true then
				-- Pre-heal for the damage done
				local parent = self:GetParent()
				--local parent_armor = parent:GetPhysicalArmorValue()
				--parent:Heal(event.damage * (1 - parent_armor / (parent_armor + 20)), parent)
				-- what is this, wc3

				-- Send the target's projectile back to them
				ProjectileManager:CreateTrackingProjectile( {
					Target = event.attacker,
					Source = parent,
					Ability = self:GetAbility(),
					EffectName = event.attacker:GetRangedProjectileName(),
					iMoveSpeed = event.attacker:GetProjectileSpeed(),
					vSpawnOrigin = parent:GetAbsOrigin(),
					bDodgeable = true,
					iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,

					ExtraData = {
						damage = event.damage
					}
				} )

				parent:EmitSound( "Sohei.GuardProc" )
			end
		end
	end
end

--------------------------------------------------------------------------------

-- Dash movement modifier
modifier_sohei_guard_knockback = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_sohei_guard_knockback:IsDebuff()
	return true
end

function modifier_sohei_guard_knockback:IsHidden()
	return true
end

function modifier_sohei_guard_knockback:IsPurgable()
	return false
end

function modifier_sohei_guard_knockback:IsStunDebuff()
	return false
end

function modifier_sohei_guard_knockback:GetPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_MEDIUM
end

--------------------------------------------------------------------------------

function modifier_sohei_guard_knockback:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}

	return state
end

--------------------------------------------------------------------------------

function modifier_sohei_guard_knockback:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_sohei_guard_knockback:GetOverrideAnimation( event )
	return ACT_DOTA_FLAIL
end

--------------------------------------------------------------------------------

function modifier_sohei_guard_knockback:GetOverrideAnimationRate( event )
	return 2.5
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_sohei_guard_knockback:OnCreated( event )
		local unit = self:GetParent()
		local caster = self:GetCaster()

		local difference = unit:GetAbsOrigin() - caster:GetAbsOrigin()

		-- Movement parameters
		self.direction = difference:Normalized()
		self.distance = event.distance
		self.speed = self:GetAbility():GetSpecialValueFor( "knockback_speed" )
		self.tree_radius = event.tree_radius

		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end
	end

--------------------------------------------------------------------------------

	function modifier_sohei_guard_knockback:OnDestroy()
		local parent = self:GetParent()

		parent:RemoveHorizontalMotionController( self )
		ResolveNPCPositions( parent:GetAbsOrigin(), 128 )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_guard_knockback:UpdateHorizontalMotion( parent, deltaTime )
		local parentOrigin = parent:GetAbsOrigin()

		local tickSpeed = self.speed * deltaTime
		tickSpeed = math.min( tickSpeed, self.distance )
		local tickOrigin = parentOrigin + ( tickSpeed * self.direction )

		parent:SetAbsOrigin( tickOrigin )

		self.distance = self.distance - tickSpeed

		GridNav:DestroyTreesAroundPoint( tickOrigin, self.tree_radius, false )
	end

--------------------------------------------------------------------------------

	function modifier_sohei_guard_knockback:OnHorizontalMotionInterrupted()
		self:Destroy()
	end
end
