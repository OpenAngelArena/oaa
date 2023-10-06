LinkLuaModifier("modifier_bear_boss_earthshock_debuff", "abilities/boss/bear_boss/bear_boss_earthshock.lua", LUA_MODIFIER_MOTION_NONE)

bear_boss_earthshock = class(AbilityBaseClass)

function bear_boss_earthshock:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context)
end

function bear_boss_earthshock:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local delay = self:GetCastPoint()

    -- Make the caster uninterruptible while casting this ability
    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})

    -- Warning particle
    local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(indicator, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
    ParticleManager:SetParticleControl(indicator, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))
    self.nPreviewFX = indicator
  end
  return true
end

function bear_boss_earthshock:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function bear_boss_earthshock:OnSpellStart()
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

  local knockback_table = {
    should_stun = 1,
    knockback_distance = radius/2,
    knockback_height = 100,
    center_x = caster_location.x,
    center_y = caster_location.y,
    center_z = caster_location.z
  }

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
    damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
    ability = self,
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      -- Knockback table variables
      knockback_table.knockback_duration = enemy:GetValueChangedByStatusResistance(0.5)
      knockback_table.duration = knockback_table.knockback_duration
      -- Apply knockback
      enemy:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      -- Apply Slow
      enemy:AddNewModifier(caster, self, "modifier_bear_boss_earthshock_debuff", {duration = self:GetSpecialValueFor("slow_duration")})
      -- Damage table variables
      damage_table.victim = enemy
      -- Apply Damage
      ApplyDamage(damage_table)
    end
  end

  -- Destroy Trees
  GridNav:DestroyTreesAroundPoint(caster_location, radius, true)

  -- Sound
  EmitSoundOnLocationWithCaster(caster_location, "Hero_Ursa.Earthshock", caster)

  -- Particle
  local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_WORLDORIGIN, nil)
  ParticleManager:SetParticleControl(particle, 0, caster_location)
  ParticleManager:SetParticleControlForward(particle, 0, caster:GetForwardVector())
  ParticleManager:SetParticleControl(particle, 1, Vector(radius*3/4, radius*3/4, radius/2))
  ParticleManager:ReleaseParticleIndex(particle)
end

---------------------------------------------------------------------------------------------------

modifier_bear_boss_earthshock_debuff = class(ModifierBaseClass)

function modifier_bear_boss_earthshock_debuff:IsDebuff()
  return true
end

function modifier_bear_boss_earthshock_debuff:IsPurgable()
  return true
end

function modifier_bear_boss_earthshock_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
end

function modifier_bear_boss_earthshock_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("move_speed_slow")
end

function modifier_bear_boss_earthshock_debuff:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("attack_speed_slow")
end

function modifier_bear_boss_earthshock_debuff:GetEffectName()
  return "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf"
end

function modifier_bear_boss_earthshock_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
