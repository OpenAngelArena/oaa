
ogre_seer_area_ignite_tier5 = class (AbilityBaseClass)
LinkLuaModifier( "modifier_ogre_seer_area_ignite_thinker", "modifiers/modifier_ogre_seer_area_ignite_thinker", LUA_MODIFIER_MOTION_NONE )

----------------------------------------------------------------------------------------

function ogre_seer_area_ignite_tier5:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()
		local vTargetPositions = { }
		vTargetPositions[ 1 ] = self:GetCursorPosition()
		vTargetPositions[ 2 ] = self:GetCursorPosition() + RandomVector( RandomFloat( 250, 300 ) )
		vTargetPositions[ 3 ] = self:GetCursorPosition() + RandomVector( RandomFloat( 250, 300 ) )

		self.hThinkers = { }

		for i, vTargetPos in ipairs( vTargetPositions ) do
			self.hThinkers[ i ] = CreateModifierThinker( caster, self, "modifier_ogre_seer_area_ignite_thinker", { duration = -1 }, vTargetPos, caster:GetTeamNumber(), false )
			if self.hThinkers[ i ] ~= nil then
				local projectile =
				{
					Target = self.hThinkers[ i ],
					Source = caster,
					Ability = self,
					EffectName = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf",
					iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" ),
					vSourceLoc = caster:GetOrigin(),
					bDodgeable = false,
					bProvidesVision = false,
				}

				ProjectileManager:CreateTrackingProjectile( projectile )
				caster:EmitSound("OgreMagi.Ignite.Cast")
			end
		end
	end
end

----------------------------------------------------------------------------------------

function ogre_seer_area_ignite_tier5:OnProjectileHit( hTarget, vLocation )
	if IsServer() then
		for i, hThinker in pairs( self.hThinkers ) do
			if hThinker ~= nil then
				local hBuff = hThinker:FindModifierByName( "modifier_ogre_seer_area_ignite_thinker" )
				if hBuff ~= nil then
					hBuff:OnIntervalThink()
				end
				hThinker = nil;
			end
		end
	end

	return true
end

----------------------------------------------------------------------------------------

