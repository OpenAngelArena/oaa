LinkLuaModifier( "modifier_ogre_seer_area_ignite_thinker", "abilities/boss/ogre_seer/modifier_ogre_seer_area_ignite_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_ogre_seer_ignite_debuff", "abilities/boss/ogre_seer/modifier_ogre_seer_area_ignite_thinker", LUA_MODIFIER_MOTION_NONE )

ogre_seer_area_ignite_tier5 = class(AbilityBaseClass)

----------------------------------------------------------------------------------------

function ogre_seer_area_ignite_tier5:OnSpellStart()
  local caster = self:GetCaster()
  local vTargetPositions = { }
  vTargetPositions[ 1 ] = self:GetCursorPosition()
  vTargetPositions[ 2 ] = self:GetCursorPosition() + RandomVector( RandomFloat( 250, 300 ) )
  vTargetPositions[ 3 ] = self:GetCursorPosition() + RandomVector( RandomFloat( 250, 300 ) )

  self.hThinkers = { }

  for i, vTargetPos in ipairs( vTargetPositions ) do
    self.hThinkers[ i ] = CreateModifierThinker( caster, self, "modifier_ogre_seer_area_ignite_thinker", { duration = -1 }, vTargetPos, caster:GetTeamNumber(), false )
    if self.hThinkers[ i ] then
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

----------------------------------------------------------------------------------------

function ogre_seer_area_ignite_tier5:OnProjectileHit( hTarget, vLocation )
  for _, hThinker in pairs( self.hThinkers ) do
    if hThinker and not hThinker:IsNull() then
      local hBuff = hThinker:FindModifierByName( "modifier_ogre_seer_area_ignite_thinker" )
      if hBuff ~= nil then
        hBuff:OnIntervalThink()
      end
    end
  end

  return true
end
