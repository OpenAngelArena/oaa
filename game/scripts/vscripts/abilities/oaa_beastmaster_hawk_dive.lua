LinkLuaModifier("modifier_hawk_dive_stun", "abilities/oaa_beastmaster_hawk_dive.lua", LUA_MODIFIER_MOTION_NONE)

beastmaster_hawk_dive_oaa = class(AbilityBaseClass)

function beastmaster_hawk_dive_oaa:Precache(context)
  PrecacheResource("particle", "particles/beastmaster_hawk/hawk_dive_bomb_tracking_projectile.vpcf", context)
end

function beastmaster_hawk_dive_oaa:OnAbilityPhaseStart()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  -- Possible with reflection spells and items
  if caster:IsRealHero() then
    return
  end

  -- Remove invis
  caster:RemoveModifierByName("modifier_hawk_invisibility_oaa")

  -- Make the hawk briefly visible
  caster:MakeVisibleToTeam(caster:GetOpposingTeamNumber(), self:GetCastPoint() / 2)

  -- Sound during casting
  caster:EmitSound("Hero_Beastmaster.Hawk.Reveal")

  -- Particle during casting
  self.cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_shard_dive_chargeup.vpcf", PATTACH_ABSORIGIN, caster)

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
  caster:StopSound("Hero_Beastmaster.Hawk.Reveal")

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

  -- Possible with reflection spells and items
  if caster:IsRealHero() then
    return
  end

  -- Hide the caster
  caster:AddNoDraw()

  -- Create a tracking projectile
  -- Valve doesn't use a tracking projectile, they use a motion controller on the hawk
  -- Using tracking projectile is scuffed but more stable
  local projectile_info = {
    Target = target,
    Source = caster,
    Ability = self,
    EffectName = "particles/beastmaster_hawk/hawk_dive_bomb_tracking_projectile.vpcf",
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

  -- If target doesn't exist (disjointed), unhide the caster and don't continue
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

  -- Explosion particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_shard_dive_impact.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, target:GetAbsOrigin())

  -- Bird exploding sound
  target:EmitSound("Hero_Beastmaster.Hawk.Target")

  -- Check if target has spell block or spell immunity
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    if caster and not caster:IsNull() and caster:IsAlive() then
      caster:ForceKillOAA(false)
    end
    -- Release explosion particle
    ParticleManager:ReleaseParticleIndex(particle)
    return
  end

  local damage = self:GetSpecialValueFor("damage")
  local duration = self:GetSpecialValueFor("root_duration")

  -- Duration with status resistance in mind
  duration = target:GetValueChangedByStatusResistance(duration)

  target:AddNewModifier(caster, self, "modifier_hawk_dive_stun", {duration = duration})

  local damage_table = {
    attacker = caster,
    victim = target,
    damage = damage,
    damage_type = self:GetAbilityDamageType(),
    ability = self,
  }

  ApplyDamage(damage_table)

  -- Add vision over stunned unit
  AddFOWViewer(caster:GetTeamNumber(), location, caster:GetCurrentVisionRange(), duration, false)

  if caster and not caster:IsNull() and caster:IsAlive() then
    caster:ForceKillOAA(false)
  end

  -- Release explosion particle
  ParticleManager:ReleaseParticleIndex(particle)
end

---------------------------------------------------------------------------------------------------

modifier_hawk_dive_stun = class(ModifierBaseClass)

function modifier_hawk_dive_stun:IsHidden() -- needs tooltip
  return false
end

function modifier_hawk_dive_stun:IsDebuff()
  return true
end

--function modifier_hawk_dive_stun:IsStunDebuff()
  --return true
--end

function modifier_hawk_dive_stun:IsPurgable()
  return true
end

function modifier_hawk_dive_stun:OnCreated()
  if not IsServer() then
    return
  end

  self:GetParent():EmitSound("Hero_Treant.Overgrowth.Target")
end

function modifier_hawk_dive_stun:GetEffectName()
  return "particles/units/heroes/hero_treant/treant_overgrowth_vines_mid.vpcf" --"particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_hawk_dive_stun:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW --PATTACH_OVERHEAD_FOLLOW
end

-- function modifier_hawk_dive_stun:DeclareFunctions()
  -- return {
    -- MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  -- }
-- end

-- function modifier_hawk_dive_stun:GetOverrideAnimation()
  -- return ACT_DOTA_DISABLED
-- end

function modifier_hawk_dive_stun:CheckState()
  return {
    --[MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_ROOTED] = true,
  }
end
