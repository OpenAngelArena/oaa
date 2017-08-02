abyssal_underlord_dark_rift_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_abyssal_underlord_dark_rift_oaa_timer", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_abyssal_underlord_dark_rift_oaa_portal", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
end

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetCastAnimation()
	return ACT_DOTA_CAST_ABILITY_4
end

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetAssociatedPrimaryAbilities()
	return "abyssal_underlord_cancel_dark_rift_oaa"
end

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:OnUpgrade()
	local caster = self:GetCaster()

	local spell = caster:FindAbilityByName( self:GetAssociatedPrimaryAbilities() )

	if spell then
		-- if the spell hasn't be upgraded yet
		-- init the disabled state
		if spell:GetLevel() then
			spell:SetActivated( false )
		end

		-- upgrade the subspell
		spell:SetLevel( self:GetLevel() )
	end
end

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:OnSpellStart()
	local caster = self:GetCaster()
	local originCaster = caster:GetAbsOrigin()
	local duration = self:GetSpecialValueFor( "portal_duration" )
	local pos = self:GetCursorPosition()
	local team = caster:GetTeamNumber()
	local minRange = self:GetSpecialValueFor( "minimum_range" )
	local vectorTarget = pos - originCaster

	-- if the target point is too close, push it out to minimum range
	if vectorTarget:Length2D() < minRange then
		pos = originCaster + ( vectorTarget:Normalized() * minRange )
	end

	local thinker1 = CreateModifierThinker( caster, self, "modifier_abyssal_underlord_dark_rift_oaa_portal", {
		targetX = pos.x,
		targetY = pos.y,
	},
	originCaster, team, false )

	-- for the sake of sanity in regards to the cancel subspell
	-- as well as a neat detail where you can keep track of the portals' duration
	-- we'll add a timer modifier that actually handles the portals' duration
	-- instead of, y'know, making the portals handle it themselves
	local mod = caster:AddNewModifier( caster, self, "modifier_abyssal_underlord_dark_rift_oaa_timer", {
		duration = duration,
	} )

	-- link the modifiers together
	-- CreateModifierThinker returns the thinker unit, not the modifier
	mod.modPortal = thinker1:FindModifierByName( "modifier_abyssal_underlord_dark_rift_oaa_portal" )
end

--------------------------------------------------------------------------------

modifier_abyssal_underlord_dark_rift_oaa_timer = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_abyssal_underlord_dark_rift_oaa_timer:IsHidden()
	return false
end

function modifier_abyssal_underlord_dark_rift_oaa_timer:IsDebuff()
	return false
end

function modifier_abyssal_underlord_dark_rift_oaa_timer:IsPurgable()
	return false
end

function modifier_abyssal_underlord_dark_rift_oaa_timer:RemoveOnDeath()
	return false
end

function modifier_abyssal_underlord_dark_rift_oaa_timer:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_abyssal_underlord_dark_rift_oaa_timer:OnCreated( event )
		local caster = self:GetCaster()
		local spell = self:GetAbility()

		local spell2 = caster:FindAbilityByName( spell:GetAssociatedPrimaryAbilities() )

		-- activate the sub spell
		if spell2 then
			spell2:SetActivated( true )
		end
	end

--------------------------------------------------------------------------------

	function modifier_abyssal_underlord_dark_rift_oaa_timer:OnDestroy()
		local caster = self:GetCaster()

		-- if the linked portals exists, destroy them
		if self.modPortal and not self.modPortal:IsNull() then
			self.modPortal:Destroy()
		end

		local spell = self:GetAbility()
		local spell2 = caster:FindAbilityByName( spell:GetAssociatedPrimaryAbilities() )

		if spell2 then
			-- don't deactivate subspell if caster has a second
			-- instance of this modifier
			if not caster:HasModifier( self:GetName() ) then
				spell2:SetActivated( false )
			end
		end
	end
end

--------------------------------------------------------------------------------

modifier_abyssal_underlord_dark_rift_oaa_portal = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_abyssal_underlord_dark_rift_oaa_portal:IsHidden()
	return true
end

function modifier_abyssal_underlord_dark_rift_oaa_portal:IsDebuff()
	return false
end

function modifier_abyssal_underlord_dark_rift_oaa_portal:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

if IsServer() then
	function modifier_abyssal_underlord_dark_rift_oaa_portal:OnCreated( event )
		local parent = self:GetParent()
		local caster = self:GetCaster()
		local spell = self:GetAbility()

		self.radius = spell:GetSpecialValueFor( "radius" )
		self.originSecond = GetGroundPosition( Vector( event.targetX, event.targetY, 0 ), caster )
		local originParent = parent:GetAbsOrigin()

		-- create portal particles
		self.partPortal1 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, parent )
		ParticleManager:SetParticleControl( self.partPortal1, 0, originParent )
		ParticleManager:SetParticleControl( self.partPortal1, 2, originParent )
		ParticleManager:SetParticleControl( self.partPortal1, 1, Vector( self.radius, 1, 1 ) )

		self.partPortal2 = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abyssal_underlord_dark_rift_portal.vpcf", PATTACH_WORLDORIGIN, parent )
		ParticleManager:SetParticleControl( self.partPortal2, 0, self.originSecond )
		ParticleManager:SetParticleControl( self.partPortal2, 2, self.originSecond )
		ParticleManager:SetParticleControl( self.partPortal2, 1, Vector( self.radius, 1, 1 ) )

		-- play cast sounds
		parent:EmitSound( "Hero_AbyssalUnderlord.DarkRift.Cast" )
		EmitSoundOnLocationWithCaster( self.originSecond, "Hero_AbyssalUnderlord.DarkRift.Cast", parent )

		-- destroy trees
		GridNav:DestroyTreesAroundPoint( originParent, self.radius, true )
		GridNav:DestroyTreesAroundPoint( self.originSecond, self.radius, true )

		self:StartIntervalThink( spell:GetSpecialValueFor( "teleport_delay" ) )
	end

--------------------------------------------------------------------------------

	function modifier_abyssal_underlord_dark_rift_oaa_portal:OnIntervalThink()
		local parent = self:GetParent()
		local spell = self:GetAbility()
		local originParent = parent:GetAbsOrigin()
		local team = parent:GetTeamNumber()

		-- destroy all trees in portals
		GridNav:DestroyTreesAroundPoint( originParent, self.radius, true )
		GridNav:DestroyTreesAroundPoint( self.originSecond, self.radius, true )

		-- play teleporation sounds
		parent:EmitSound( "Hero_AbyssalUnderlord.DarkRift.Aftershock" )
		EmitSoundOnLocationWithCaster( self.originSecond, "Hero_AbyssalUnderlord.DarkRift.Aftershock", parent )

		-- emit warp particles
		local part = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, parent )
		ParticleManager:SetParticleControl( part, 1, Vector( self.radius, 1, 1 ) )
		ParticleManager:SetParticleControl( part, 2, originParent )

		part = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_warp.vpcf", PATTACH_WORLDORIGIN, parent )
		ParticleManager:SetParticleControl( part, 1, Vector( self.radius, 1, 1 ) )
		ParticleManager:SetParticleControl( part, 2, self.originSecond )

		local targetTeam = spell:GetAbilityTargetTeam()
		local targetType = spell:GetAbilityTargetType()
		local targetFlags = bit.bor( DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED )--spell:GetAbilityTargetFlags()

		-- find the units in both portals
		local unitsPortal1 = FindUnitsInRadius(
			team,
			originParent,
			nil,
			self.radius,
			targetTeam,
			targetType,
			targetFlags,
			FIND_ANY_ORDER,
			false
		)

		local unitsPortal2 = FindUnitsInRadius(
			team,
			self.originSecond,
			nil,
			self.radius,
			targetTeam,
			targetType,
			targetFlags,
			FIND_ANY_ORDER,
			false
		)

		local unitsAll = {}

		local function FindInTable( t, target )
			for k, v in pairs( t ) do
				if v == target then
					return k
				end
			end

			return nil
		end

		local function CheckRiftTeleport( unit )
			return not FindInTable( unitsAll, unit ) and not unit:IsRooted() and ( not unit:IsOpposingTeam( parent:GetTeamNumber() ) or not unit:HasModifier( "modifier_fountain_aura_buff" ) )
		end

		-- if the unit hasn't been telported by a previous portal, retain its old position and put it at its new one
		for _, unit in pairs( unitsPortal1 ) do
			if CheckRiftTeleport( unit ) then
				unit.tempOriginOld = unit:GetAbsOrigin()
				local vectorOffset = unit:GetAbsOrigin() - originParent
				unit:SetAbsOrigin( self.originSecond + vectorOffset )

				table.insert( unitsAll, unit )
			end
		end

		for _, unit in pairs( unitsPortal2 ) do
			if CheckRiftTeleport( unit ) then
				unit.tempOriginOld = unit:GetAbsOrigin()
				local vectorOffset = unit:GetAbsOrigin() - self.originSecond
				unit:SetAbsOrigin( originParent + vectorOffset )

				table.insert( unitsAll, unit )
			end
		end

		-- final touches, such as making sure units aren't in unpathable terrain

		for _, unit in pairs( unitsAll ) do
			FindClearSpaceForUnit( unit, unit:GetAbsOrigin(), true )
			local originUnit = unit:GetAbsOrigin()

			part = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_darkrift_ambient_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit )
			ParticleManager:SetParticleControl( part, 2, unit.tempOriginOld )
			ParticleManager:SetParticleControl( part, 5, unit.tempOriginOld )

			unit.tempOriginOld = nil

			-- interrupt the unit, so that channeled abilities won't keep channeling
			unit:Interrupt()
		end
	end

--------------------------------------------------------------------------------

	function modifier_abyssal_underlord_dark_rift_oaa_portal:OnDestroy()
		ParticleManager:DestroyParticle( self.partPortal1, false )
		ParticleManager:ReleaseParticleIndex( self.partPortal1 )

		ParticleManager:DestroyParticle( self.partPortal2, false )
		ParticleManager:ReleaseParticleIndex( self.partPortal2 )

		UTIL_Remove( self:GetParent() )
	end
end