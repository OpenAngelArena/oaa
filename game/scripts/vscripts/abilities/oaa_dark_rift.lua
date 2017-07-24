abyssal_underlord_dark_rift_oaa = class( AbilityBaseClass )

LinkLuaModifier( "modifier_abyssal_underlord_dark_rift_oaa_portal", "abilities/oaa_dark_rift.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

function abyssal_underlord_dark_rift_oaa:GetAOERadius()
	return self:GetSpecialValueFor( "radius" )
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
		duration = duration,
		targetX = pos.x,
		targetY = pos.y,
	},
	originCaster, team, false )
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

		local function FindInTable( t, target )
			for k, v in pairs( t ) do
				if v == target then
					return k
				end
			end

			return nil
		end

		local unitsAll = {}

		-- if the unit hasn't been telported by a previous portal, retain its old position and put it at its new one
		for _, unit in pairs( unitsPortal1 ) do
			if not FindInTable( unitsAll, unit ) and not unit:IsRooted() then
				unit.tempOriginOld = unit:GetAbsOrigin()
				local vectorOffset = unit:GetAbsOrigin() - originParent
				unit:SetAbsOrigin( self.originSecond + vectorOffset )

				table.insert( unitsAll, unit )
			end
		end

		for _, unit in pairs( unitsPortal2 ) do
			if not FindInTable( unitsAll, unit ) and not unit:IsRooted() then
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