LinkLuaModifier( "modifier_temple_guardian_wrath_thinker", "abilities/boss/temple_guardian/modifier_temple_guardian_wrath_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_temple_guardian_immunity", "abilities/boss/temple_guardian/modifier_temple_guardian_immunity", LUA_MODIFIER_MOTION_NONE )

temple_guardian_wrath_tier5 = class(AbilityBaseClass)

function temple_guardian_wrath_tier5:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
end

function temple_guardian_wrath_tier5:GetChannelAnimation()
	return ACT_DOTA_CHANNEL_ABILITY_4
end

--------------------------------------------------------------------------------

function temple_guardian_wrath_tier5:OnAbilityPhaseStart()
	if IsServer() then
    local caster = self:GetCaster()
    local fImmuneDuration = self:GetCastPoint() + self:GetChannelTime()

    caster:AddNewModifier(caster, self, "modifier_temple_guardian_immunity", {duration = fImmuneDuration})

    self.nPreviewFX = ParticleManager:CreateParticle( "particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( self.nPreviewFX, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true )
    ParticleManager:SetParticleControl( self.nPreviewFX, 1, Vector( 250, 250, 250 ) )
    ParticleManager:SetParticleControl( self.nPreviewFX, 15, Vector( 176, 224, 230 ) )
  end

  return true
end

--------------------------------------------------------------------------------

function temple_guardian_wrath_tier5:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

-----------------------------------------------------------------------------

function temple_guardian_wrath_tier5:OnSpellStart()
  local caster = self:GetCaster()
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  self.effect_radius = self:GetSpecialValueFor( "effect_radius" )
  self.interval = self:GetSpecialValueFor( "interval" )

  self.flNextCast = 0.0

  caster:EmitSound("TempleGuardian.Wrath.Cast")
  caster:AddNewModifier( caster, self, "modifier_omninight_guardian_angel", {} )

  --local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf", PATTACH_ABSORIGIN, self:GetCaster() )
  --ParticleManager:SetParticleControl( nFXIndex, 1, Vector( self.effect_radius, self.channel_duration, 0.0 ) )
  --ParticleManager:ReleaseParticleIndex( nFXIndex )
end

-----------------------------------------------------------------------------

function temple_guardian_wrath_tier5:OnChannelThink( flInterval )
	self.flNextCast = self.flNextCast + flInterval
  if self.flNextCast >= self.interval  then
    -- Try not to overlap wrath_thinker locations, but use the last position attempted if we spend too long in the loop
    local nMaxAttempts = 7
    local nAttempts = 0
    local vPos

    repeat
      vPos = self:GetCaster():GetOrigin() + RandomVector( RandomInt( 50, self.effect_radius ) )
      local hThinkersNearby = Entities:FindAllByClassnameWithin( "npc_dota_thinker", vPos, 600 )
      local hOverlappingWrathThinkers = {}

      for _, hThinker in pairs( hThinkersNearby ) do
        if ( hThinker:HasModifier( "modifier_temple_guardian_wrath_thinker" ) ) then
          table.insert( hOverlappingWrathThinkers, hThinker )
        end
      end
      nAttempts = nAttempts + 1
      if nAttempts >= nMaxAttempts then
        break
      end
    until ( #hOverlappingWrathThinkers == 0 )

    CreateModifierThinker( self:GetCaster(), self, "modifier_temple_guardian_wrath_thinker", {}, vPos, self:GetCaster():GetTeamNumber(), false )
    self.flNextCast = self.flNextCast - self.interval
  end
end

-----------------------------------------------------------------------------

function temple_guardian_wrath_tier5:OnChannelFinish( bInterrupted )
  local caster = self:GetCaster()
  caster:RemoveModifierByName("modifier_omninight_guardian_angel")
  if caster:HasModifier("modifier_temple_guardian_immunity") then
    caster:RemoveModifierByName("modifier_temple_guardian_immunity")
  end
end
