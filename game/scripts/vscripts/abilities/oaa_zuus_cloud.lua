zuus_cloud = class( AbilityBaseClass )
LinkLuaModifier( "modifier_zuus_cloud_oaa", "abilities/oaa_zuus_cloud.lua", LUA_MODIFIER_MOTION_NONE )

function zuus_cloud:OnSpellStart()
  local caster = self:GetCaster()
  local hCloud = CreateUnitByName( "npc_dota_zeus_cloud", self:GetCursorPosition(), true, caster, caster, caster:GetTeamNumber() )
  hCloud:SetOwner( self:GetCaster() )
  hCloud:SetControllableByPlayer( self:GetCaster():GetPlayerOwnerID(), false )
  hCloud:AddNewModifier( caster, self, "modifier_zuus_cloud_oaa", { Interval = self:GetSpecialValueFor( "cloud_bolt_interval" ), Radius = self:GetSpecialValueFor( "cloud_radius" ) } )
  hCloud:AddNewModifier( caster, self, "modifier_kill", { duration = self:GetSpecialValueFor( "cloud_duration" ) } )
  FindClearSpaceForUnit( hCloud, self:GetCursorPosition(), true )
end

modifier_zuus_cloud_oaa = class( ModifierBaseClass )

function modifier_zuus_cloud_oaa:IsHidden()
  return true
end

function modifier_zuus_cloud_oaa:IsDebuff()
  return false
end

function modifier_zuus_cloud_oaa:IsPurgable()
  return false
end

function modifier_zuus_cloud_oaa:RemoveOnDeath()
  return true
end

function modifier_zuus_cloud_oaa:OnCreated( kv )
  if IsServer() then
    self.Interval = kv.Interval
    self.Radius = kv.Radius
    self.cloud_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.cloud_particle, 1, Vector(self.Radius, 1, 1))

    ParticleManager:SetParticleControlEnt(self.cloud_particle, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    self:StartIntervalThink( 0.1 )
    EmitSoundOn("Hero_Zuus.Cloud.Cast", self:GetParent())
  end
end

function modifier_zuus_cloud_oaa:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle( self.cloud_particle, false)
    ParticleManager:ReleaseParticleIndex(self.cloud_particle)
    self.cloud_particle= nil
  end
end

function modifier_zuus_cloud_oaa:OnIntervalThink()
  if self.LastStrike == nil or GameRules:GetDOTATime(false, false) - self.LastStrike > self.Interval then
    local caster = self:GetCaster()
    local targets = FindUnitsInRadius(
      caster:GetTeamNumber(),
      self:GetParent():GetAbsOrigin(),
      nil,
      self.Radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor( DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES ),
      FIND_CLOSEST,
      false
    )
    if #targets == 0 then
      targets = FindUnitsInRadius(
        caster:GetTeamNumber(),
        self:GetParent():GetAbsOrigin(),
        nil,
        self.Radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_CREEP,
        bit.bor( DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES ),
        FIND_CLOSEST,
        false
      )
    end

    if #targets > 0 then
      self:CastLightningBolt(targets[1])
      self.LastStrike = GameRules:GetDOTATime(false, false)
    end
  end
end

function modifier_zuus_cloud_oaa:CastLightningBolt(target)
  local caster = self:GetCaster()
  local parent = self:GetParent()
  local ability = caster:FindAbilityByName( 'zuus_lightning_bolt' )
  local radius = ability:GetSpecialValueFor("spread_aoe")
  local sight_radius =  0
  if GameRules:IsDaytime() then
    sight_radius = ability:GetSpecialValueFor("sight_radius_day")
  else
    sight_radius = ability:GetSpecialValueFor("sight_radius_night")
  end
  local sight_duration = ability:GetSpecialValueFor("sight_duration")

  if ability:GetLevel() > 0 then
    AddFOWViewer(caster:GetTeam(), target:GetAbsOrigin(), sight_radius, sight_duration, false)

    -- Checks if the target has been set yet
    target:AddNewModifier(caster, ability, "modifier_stunned", {Duration = 0.1})
    ApplyDamage({victim = target, attacker = caster, damage = ability:GetAbilityDamage(), damage_type = ability:GetAbilityDamageType()})
    -- Renders the particle on the sigil
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud_strike.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())

    ParticleManager:SetParticleControlEnt(self.cloud_particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))
    EmitSoundOn("Hero_Zuus.LightningBolt.Cloud", target)
  end
end
