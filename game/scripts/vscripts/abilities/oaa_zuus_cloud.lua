zuus_cloud = class( AbilityBaseClass )
LinkLuaModifier( "modifier_zuus_cloud_oaa", "abilities/oaa_zuus_cloud.lua", LUA_MODIFIER_MOTION_NONE )

function zuus_cloud:OnSpellStart()
  local caster = self:GetCaster()
  local hCloud = CreateUnitByName( "npc_dota_zeus_cloud", self:GetCursorPosition(), true, caster, caster, caster:GetTeamNumber() )
  hCloud:SetOwner( self:GetCaster() )
  hCloud:SetControllableByPlayer( self:GetCaster():GetPlayerOwnerID(), false )
  hCloud:AddNewModifier( caster, self, "modifier_zuus_cloud_oaa", nil)
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
    local radius = self:GetAbility():GetSpecialValueFor( "cloud_radius" )
    self.cloud_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.cloud_particle, 1, Vector(radius, 1, 1))

    ParticleManager:SetParticleControlEnt(self.cloud_particle, 2, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
    self:StartIntervalThink( 0.1 )
    EmitSoundOn("Hero_Zuus.Cloud.Cast", self:GetParent())
  end
end

function modifier_zuus_cloud_oaa:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle(self.cloud_particle, false)
    ParticleManager:ReleaseParticleIndex(self.cloud_particle)
    self.cloud_particle = nil
  end
end

function modifier_zuus_cloud_oaa:OnIntervalThink()
  local interval = self:GetAbility():GetSpecialValueFor( "cloud_bolt_interval" )
  local radius = self:GetAbility():GetSpecialValueFor( "cloud_radius" )
  if self.LastStrike == nil or GameRules:GetDOTATime(false, false) - self.LastStrike > interval then
    local caster = self:GetCaster()
    local targets = FindUnitsInRadius(
      caster:GetTeamNumber(),
      self:GetParent():GetAbsOrigin(),
      nil,
      radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_CLOSEST,
      false
    )
    if #targets == 0 then
      targets = FindUnitsInRadius(
        caster:GetTeamNumber(),
        self:GetParent():GetAbsOrigin(),
        nil,
        radius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_CREEP,
        DOTA_UNIT_TARGET_FLAG_NONE,
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
  local lightning_bolt_ability = caster:FindAbilityByName("zuus_lightning_bolt")
  local sight_radius =  0
  if GameRules:IsDaytime() then
    sight_radius = lightning_bolt_ability:GetSpecialValueFor("sight_radius_day")
  else
    sight_radius = lightning_bolt_ability:GetSpecialValueFor("sight_radius_night")
  end
  local sight_duration = lightning_bolt_ability:GetSpecialValueFor("sight_duration")

  if lightning_bolt_ability:GetLevel() > 0 then
    AddFOWViewer(caster:GetTeam(), target:GetAbsOrigin(), sight_radius, sight_duration, false)

    local talent = caster:FindAbilityByName("special_bonus_unique_zeus_3")
    local ministun_duration = 0.1

    if talent ~= nil and talent:GetLevel() > 0 then
      ministun_duration = ministun_duration + talent:GetSpecialValueFor("value")
    end

    target:AddNewModifier(caster, lightning_bolt_ability, "modifier_stunned", {Duration = ministun_duration})
    ApplyDamage({victim = target, attacker = parent, damage = lightning_bolt_ability:GetAbilityDamage(), damage_type = lightning_bolt_ability:GetAbilityDamageType()})
    -- Renders the particle on the sigil
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud_strike.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())

    ParticleManager:SetParticleControlEnt(particle, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(particle, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z + target:GetBoundingMaxs().z ))
    EmitSoundOn("Hero_Zuus.LightningBolt.Cloud", target)
  end
end
