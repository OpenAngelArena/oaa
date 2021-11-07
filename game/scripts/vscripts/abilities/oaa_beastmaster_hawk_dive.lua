beastmaster_hawk_dive_oaa = class(AbilityBaseClass)

LinkLuaModifier( "modifier_hawk_dive_stun", "abilities/oaa_beastmaster_hawk_dive.lua", LUA_MODIFIER_MOTION_NONE )

function beastmaster_hawk_dive_oaa:OnAbilityPhaseStart()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  -- Remove invis
  caster:RemoveModifierByName("modifier_hawk_invisibility_oaa")

  -- Sound during casting
  --caster:EmitSound("")

  -- Particle during casting
  --self.cast_particle = ParticleManager:CreateParticle(".vpcf", PATTACH_ABSORIGIN, caster)

  return true
end

function beastmaster_hawk_dive_oaa:OnAbilityPhaseInterrupted()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  -- Readd invis
  if not caster:HasModifier("modifier_hawk_invisibility_oaa") then
    caster:AddNewModifier(caster, nil, "modifier_hawk_invisibility_oaa", {})
  end

  -- Interrupt casting sound
  --caster:StopSound("")

  -- Remove casting particle
  if self.cast_particle then
    ParticleManager:DestroyParticle(self.cast_particle, true)
    ParticleManager:ReleaseParticleIndex(self.cast_particle)
    self.cast_particle = nil
  end
end

function beastmaster_hawk_dive_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Remove ability phase (cast) particle
  if self.cast_particle then
    ParticleManager:DestroyParticle(self.cast_particle, false)
    ParticleManager:ReleaseParticleIndex(self.cast_particle)
    self.cast_particle = nil
  end

  -- Check if target and caster entities exist
  if not target or target:IsNull() or not caster or caster:IsNull() then
    return
  end

  -- Hide the caster
  caster:AddNoDraw()

  -- Create a tracking projectile
  local projectile_info = {
    Target = target,
    Source = caster,
    Ability = self,
    --EffectName = ".vpcf",
    bDodgeable = true,
    bProvidesVision = true,
    bVisibleToEnemies = true,
    bReplaceExisting = false,
    iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
    iVisionRadius = caster:GetCurrentVisionRange(),
    iVisionTeamNumber = caster:GetTeamNumber(),
  }

  ProjectileManager:CreateTrackingProjectile(projectile_info)
end

function beastmaster_hawk_dive_oaa:OnProjectileHit(target, location)
  local caster = self:GetCaster()

  -- If target doesn't exist (disjointed?), unhide the caster and don't continue
  if not target or target:IsNull() then
    if caster and not caster:IsNull() then
      if location then
        caster:SetAbsOrigin(location)
      end
      caster:RemoveNoDraw()
    end
    return
  end

  -- If caster doesn't exist, don't continue
  if not caster or caster:IsNull() then
    return
  end

  -- Check if target has spell block or spell immunity
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    if caster and not caster:IsNull() and caster:IsAlive() then
      caster:ForceKill(false)
    end
    return
  end

  local damage = self:GetSpecialValueFor("damage")
  local duration = self:GetSpecialValueFor("stun_duration")

  -- Duration with status resistance in mind
  duration = target:GetValueChangedByStatusResistance(duration)

  target:AddNewModifier(caster, self, "modifier_hawk_dive_stun", {duration = duration})

  local damage_table = {}
  damage_table.victim = target
  damage_table.attacker = caster
  damage_table.damage = damage
  damage_table.damage_type = self:GetAbilityDamageType()
  damage_table.ability = self

  ApplyDamage(damage_table)

  if caster and not caster:IsNull() and caster:IsAlive() then
    caster:ForceKill(false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_hawk_dive_stun = class(ModifierBaseClass)

function modifier_hawk_dive_stun:IsHidden()
  return true
end

function modifier_hawk_dive_stun:IsDebuff()
  return true
end

function modifier_hawk_dive_stun:IsStunDebuff()
  return true
end

function modifier_hawk_dive_stun:IsPurgable()
  return true
end

function modifier_hawk_dive_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_hawk_dive_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_hawk_dive_stun:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }

  return funcs
end

function modifier_hawk_dive_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_hawk_dive_stun:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true,
  }
  return state
end
