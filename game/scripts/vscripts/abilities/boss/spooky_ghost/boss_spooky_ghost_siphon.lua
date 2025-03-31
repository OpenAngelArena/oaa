LinkLuaModifier("modifier_boss_spooky_ghost_siphon_debuff", "abilities/boss/spooky_ghost/boss_spooky_ghost_siphon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_frostbite_effect", "abilities/boss/boss_frostbite.lua", LUA_MODIFIER_MOTION_NONE)

boss_spooky_ghost_siphon = class(AbilityBaseClass)

function boss_spooky_ghost_siphon:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_death_prophet/death_prophet_spiritsiphon.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_death_prophet.vsndevts", context)
end

function boss_spooky_ghost_siphon:OnAbilityPhaseStart()
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

function boss_spooky_ghost_siphon:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function boss_spooky_ghost_siphon:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local debuff_duration = self:GetSpecialValueFor("duration")

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

  local do_sound = false
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsInvulnerable() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      do_sound = true
      -- Apply Spirit Siphon debuff
      enemy:AddNewModifier(caster, self, "modifier_boss_spooky_ghost_siphon_debuff", {duration = debuff_duration})
      -- Apply frostbite debuff if disarmed or ethereal
      if caster:IsAttackImmune() or caster:IsDisarmed() then
        enemy:AddNewModifier(caster, nil, "modifier_boss_frostbite_effect", {duration = debuff_duration})
      end
    end
  end

  -- Sound
  if do_sound then
    EmitSoundOnLocationWithCaster(caster_location, "Hero_DeathProphet.SpiritSiphon.Cast", caster)
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_spooky_ghost_siphon_debuff = class(ModifierBaseClass)

function modifier_boss_spooky_ghost_siphon_debuff:IsHidden()
  return false
end

function modifier_boss_spooky_ghost_siphon_debuff:IsDebuff()
  return true
end

function modifier_boss_spooky_ghost_siphon_debuff:IsPurgable()
  return true
end

function modifier_boss_spooky_ghost_siphon_debuff:OnCreated()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local parent = self:GetParent()

  if not caster or caster:IsNull() or not caster:IsAlive() then
    self:Destroy()
  end

  -- Particle
  self.nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_spiritsiphon.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControlEnt(self.nFX, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
  ParticleManager:SetParticleControlEnt(self.nFX, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
  ParticleManager:SetParticleControl(self.nFX, 5, Vector(self:GetRemainingTime(), 0, 0))

  -- Sound
  parent:EmitSound("Hero_DeathProphet.SpiritSiphon.Target")

  -- Start thinking
  self.interval = 0.25
  self:StartIntervalThink(self.interval)
end

function modifier_boss_spooky_ghost_siphon_debuff:OnIntervalThink()
	if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  -- If needed parameters don't exist or caster becomes silenced then destroy this debuff
  if not caster or caster:IsNull() or not caster:IsAlive() or caster:IsSilenced() or not parent or parent:IsNull() or not ability or ability:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- If parent is dead or becomes spell-immune, invulnerable or banished then destroy this debuff
  if not parent:IsAlive() or parent:IsMagicImmune() or parent:IsDebuffImmune() or parent:IsInvulnerable() or parent:IsOutOfGame() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local distance = (caster:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
  local radius = ability:GetSpecialValueFor("radius")
  local buffer_range = ability:GetSpecialValueFor("buffer_range")

  -- If parent goes out of range then destroy this debuff
  if distance > radius + buffer_range then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  local max_hp_pct = ability:GetSpecialValueFor("max_hp_dmg")
  local heal_pct = ability:GetSpecialValueFor("lifesteal_pct")

  local damage_table = {
    attacker = caster,
    victim = parent,
    damage = parent:GetMaxHealth() * max_hp_pct * 0.01 * self.interval,
    damage_type = ability:GetAbilityDamageType(),
    ability = ability,
  }

  -- Apply damage to the parent
  local damage_dealt = ApplyDamage(damage_table)
  -- Calculate heal amount
  local heal_amount = damage_dealt * heal_pct * 0.01
  -- Heal the caster
  --caster:Heal(heal_amount, ability)
  caster:HealWithParams(heal_amount, ability, false, true, caster, false)
end

function modifier_boss_spooky_ghost_siphon_debuff:OnDestroy()
  if IsServer() then
    -- Stop sound
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
      parent:StopSound("Hero_DeathProphet.SpiritSiphon.Target")
    end
    -- Remove particle
    if self.nFX then
      ParticleManager:DestroyParticle(self.nFX, true)
      ParticleManager:ReleaseParticleIndex(self.nFX)
      self.nFX = nil
    end
  end
end

function modifier_boss_spooky_ghost_siphon_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
end

function modifier_boss_spooky_ghost_siphon_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("move_speed_slow")
end

function modifier_boss_spooky_ghost_siphon_debuff:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("attack_speed_slow")
end
