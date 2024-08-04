LinkLuaModifier("modifier_boss_killer_tomato_clap_debuff", "abilities/boss/killer_tomato/boss_killer_tomato_clap.lua", LUA_MODIFIER_MOTION_NONE)

boss_killer_tomato_clap = class(AbilityBaseClass)

function boss_killer_tomato_clap:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf", context)
  --PrecacheResource("soundfile", "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts", context)
end

function boss_killer_tomato_clap:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local delay = self:GetCastPoint()

    -- Make the caster uninterruptible while casting this ability
    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})

    Timers:CreateTimer(delay/2, function()
      caster:EmitSound("n_creep_Ursa.Clap")
    end)

    -- Warning particle
    local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(indicator, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
    ParticleManager:SetParticleControl(indicator, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))
    self.nPreviewFX = indicator
  end
  return true
end

function boss_killer_tomato_clap:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
    self:GetCaster():StopSound("n_creep_Ursa.Clap")
  end
end

function boss_killer_tomato_clap:GetPlaybackRateOverride()
  return 0.5
end

function boss_killer_tomato_clap:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local damage = self:GetSpecialValueFor("damage")

  local caster_location = caster:GetAbsOrigin()

  -- Find enemies in a radius
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster_location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Damage table constants
  local damage_table = {
    attacker = caster,
    damage = damage,
    damage_type = self:GetAbilityDamageType(),
    --damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_PHYSICAL_BLOCK,
    ability = self,
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      -- Apply Slow
      enemy:AddNewModifier(caster, self, "modifier_boss_killer_tomato_clap_debuff", {duration = self:GetSpecialValueFor("slow_duration")})
      -- Damage table variables
      damage_table.victim = enemy
      -- Apply Damage
      ApplyDamage(damage_table)
    end
  end

  -- Destroy Trees
  GridNav:DestroyTreesAroundPoint(caster_location, radius, true)

  -- Sound
  EmitSoundOnLocationWithCaster(caster_location, "Hellbear.Smash", caster)

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_WORLDORIGIN, nil)
  ParticleManager:SetParticleControl(particle, 0, caster_location)
  ParticleManager:SetParticleControlForward(particle, 0, caster:GetForwardVector())
  ParticleManager:SetParticleControl(particle, 1, Vector(radius*3/4, radius*3/4, radius/2))
  ParticleManager:ReleaseParticleIndex(particle)
end

---------------------------------------------------------------------------------------------------

modifier_boss_killer_tomato_clap_debuff = class(ModifierBaseClass)

function modifier_boss_killer_tomato_clap_debuff:IsDebuff()
  return true
end

function modifier_boss_killer_tomato_clap_debuff:IsPurgable()
  return true
end

function modifier_boss_killer_tomato_clap_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
end

function modifier_boss_killer_tomato_clap_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("move_speed_slow")
end

function modifier_boss_killer_tomato_clap_debuff:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("attack_speed_slow")
end

function modifier_boss_killer_tomato_clap_debuff:GetEffectName()
  return "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf"
end

function modifier_boss_killer_tomato_clap_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
