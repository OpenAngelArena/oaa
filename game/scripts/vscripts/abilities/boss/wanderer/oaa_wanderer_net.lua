LinkLuaModifier("modifier_wanderer_net_target", "abilities/boss/wanderer/oaa_wanderer_net.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_net_debuff", "abilities/boss/wanderer/oaa_wanderer_net.lua", LUA_MODIFIER_MOTION_NONE)

wanderer_net = class(AbilityBaseClass)

function wanderer_net:Precache(context)
  PrecacheResource("particle", "particles/generic_gameplay/generic_has_quest.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_siren/siren_net.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_siren/siren_net_projectile.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_naga_siren.vsndevts", context)
end

function wanderer_net:OnAbilityPhaseStart()
  if IsServer() then
    -- Warning particle over caster's head
    self.warningFX = ParticleManager:CreateParticle("particles/generic_gameplay/generic_has_quest.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
  end
  return true
end

function wanderer_net:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.warningFX then
      ParticleManager:DestroyParticle(self.warningFX, true)
      ParticleManager:ReleaseParticleIndex(self.warningFX)
      self.warningFX = nil
    end
  end
end

function wanderer_net:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.warningFX then
    ParticleManager:DestroyParticle(self.warningFX, true)
    ParticleManager:ReleaseParticleIndex(self.warningFX)
    self.warningFX = nil
  end

  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  if not target then
    return
  end

  local speed = self:GetSpecialValueFor("projectile_speed")
  -- Tracking Projectile table
  local info = {
    Target = target,
    Source = caster,
    Ability = self,
    bDodgeable = true,
    EffectName = "particles/units/heroes/hero_siren/siren_net_projectile.vpcf",
    iMoveSpeed = speed,
    --bProvidesVision = false,
    --bIsAttack = false,
    --bReplaceExisting = false,
    bIgnoreObstructions = false,
    --bVisibleToEnemies = true,
  }

  ProjectileManager:CreateTrackingProjectile(info)

  -- Calculate distance and max particle duration
  local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
  local particle_duration = distance/speed

  -- Apply the warning particle (with a modifier)
  target:AddNewModifier(caster, self, "modifier_wanderer_net_target", {duration = particle_duration})

  -- Sound on cast
  caster:EmitSound("Hero_NagaSiren.Ensnare.Cast")
end

function wanderer_net:OnProjectileHit(target, location)
  -- If target doesn't exist or its about to be deleted -> don't continue
  if not target or target:IsNull() then
    return
  end

  -- Remove warning particle
  target:RemoveModifierByName("modifier_wanderer_net_target")

  -- Check for spell block
  if target:TriggerSpellAbsorb(self) then
    return
  end

  -- Check for spell immunity and invulnerability
  if target:IsMagicImmune() or target:IsDebuffImmune() or target:IsInvulnerable() then
    return
  end

  local caster = self:GetCaster()

  -- Check if caster was killed or deleted while Net was flying
  if not caster or caster:IsNull() then
    return
  end

  local duration = self:GetSpecialValueFor("duration")

  -- Apply the actual debuff
  target:AddNewModifier(caster, self, "modifier_wanderer_net_debuff", {duration = duration})

  -- Interrupt (mini-stun)
  target:Interrupt()

  -- Sound on target
  target:EmitSound("Hero_NagaSiren.Ensnare.Target")

  return true
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_net_target = class(ModifierBaseClass)

function modifier_wanderer_net_target:IsHidden()
  return true
end

function modifier_wanderer_net_target:IsDebuff()
  return false
end

function modifier_wanderer_net_target:IsPurgable()
  return false
end

function modifier_wanderer_net_target:GetEffectName()
  return "particles/generic_gameplay/generic_has_quest.vpcf"
end

function modifier_wanderer_net_target:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

---------------------------------------------------------------------------------------------------

modifier_wanderer_net_debuff = class(ModifierBaseClass)

function modifier_wanderer_net_debuff:IsHidden()
  return false
end

function modifier_wanderer_net_debuff:IsDebuff()
  return true
end

function modifier_wanderer_net_debuff:IsPurgable()
  return false
end

function modifier_wanderer_net_debuff:GetEffectName()
  return "particles/units/heroes/hero_siren/siren_net.vpcf"
end

function modifier_wanderer_net_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN
end

function modifier_wanderer_net_debuff:CheckState()
  return {
    [MODIFIER_STATE_ROOTED] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end

function modifier_wanderer_net_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_HEALING,
  }
end

function modifier_wanderer_net_debuff:GetDisableHealing()
  return 1
end
