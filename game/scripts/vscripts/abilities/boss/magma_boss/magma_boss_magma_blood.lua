LinkLuaModifier("modifier_magma_boss_magma_blood_passive", "abilities/boss/magma_boss/magma_boss_magma_blood.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_magma_boss_magma_blood_debuff", "abilities/boss/magma_boss/magma_boss_magma_blood.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_magma_boss_magma_blood_warning", "abilities/boss/magma_boss/magma_boss_magma_blood.lua", LUA_MODIFIER_MOTION_NONE)

magma_boss_magma_blood = class(AbilityBaseClass)

function magma_boss_magma_blood:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_impact.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_linger.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_snapfire/snapfire_lizard_blobs_arced.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_snapfire/hero_snapfire_burn_debuff.vpcf", context)
  PrecacheResource("particle", "particles/status_fx/status_effect_snapfire_magma.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_snapfire.vsndevts", context)
end

function magma_boss_magma_blood:GetIntrinsicModifierName()
  return "modifier_magma_boss_magma_blood_passive"
end

function magma_boss_magma_blood:OnProjectileHit(target, location)
  if not target or not location then
    return
  end

  local damage = self:GetSpecialValueFor("impact_damage")
  local dummy_duration = self:GetSpecialValueFor("blob_duration")
  local impact_radius = self:GetSpecialValueFor("impact_radius")

  local caster = self:GetCaster()

  local damage_table = {
    attacker = caster,
    damage = damage,
    damage_type = self:GetAbilityDamageType(),
    ability = self,
  }

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    location,
    nil,
    impact_radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      -- Apply debuff
      enemy:AddNewModifier(caster, self, "modifier_magma_boss_magma_blood_debuff", {duration = self:GetSpecialValueFor("slow_duration")})
      -- Apply damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(location, impact_radius, true)

  local particle_name = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_impact.vpcf"
  local particle_name2 = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_linger.vpcf"
  local sound_name = "Hero_Snapfire.MortimerBlob.Impact"

  -- Particles
  local particle1 = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle1, 3, location)
  ParticleManager:ReleaseParticleIndex(particle1)

  local particle2 = ParticleManager:CreateParticle(particle_name2, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle2, 0, location)
  ParticleManager:SetParticleControl(particle2, 1, location)
  ParticleManager:ReleaseParticleIndex(particle2)

  -- Sound
  EmitSoundOnLocationWithCaster(location, sound_name, caster)

  if target:HasModifier("modifier_oaa_thinker") then
    target:AddNewModifier(target, self, "modifier_kill", {duration = dummy_duration})
    target:AddNewModifier(target, self, "modifier_generic_dead_tracker_oaa", {duration = dummy_duration + MANUAL_GARBAGE_CLEANING_TIME})
  end
end

function magma_boss_magma_blood:ShouldUseResources()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_magma_blood_passive = class(ModifierBaseClass)

function modifier_magma_boss_magma_blood_passive:IsHidden()
  return true
end

function modifier_magma_boss_magma_blood_passive:IsDebuff()
  return false
end

function modifier_magma_boss_magma_blood_passive:IsPurgable()
  return false
end

function modifier_magma_boss_magma_blood_passive:RemoveOnDeath()
  return true
end

function modifier_magma_boss_magma_blood_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.max_scale = ability:GetSpecialValueFor("max_scale")
    self.threshold = ability:GetSpecialValueFor("damage_threshold")
  else
    self.max_scale = 110
    self.threshold = 50
  end
end

modifier_magma_boss_magma_blood_passive.OnRefresh = modifier_magma_boss_magma_blood_passive.OnCreated

function modifier_magma_boss_magma_blood_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_magma_boss_magma_blood_passive:GetModifierModelScale()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local current_hp_pct = parent:GetHealth() / parent:GetMaxHealth()

  return math.max(1, math.ceil(current_hp_pct * self.max_scale))
end

if IsServer() then
  function modifier_magma_boss_magma_blood_passive:OnTakeDamage(event)
    local caster = self:GetParent() or self:GetCaster()
    local ability = self:GetAbility()
    local attacker = event.attacker
    local damage = event.damage
    local damaged_unit = event.unit

    -- Don't continue if attacker doesn't exist or it is about to be deleted
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Continue only if the caster/parent is the damaged unit
    if damaged_unit ~= caster then
      return
    end

    -- Don't continue if caster is the attacker (self damage)
    if caster == attacker then
      return
    end

    -- Don't continue If ability doesn't exist
    if not ability or ability:IsNull() then
      return
    end

    -- Don't proc while on cooldown
    if not ability:IsCooldownReady() then
      return
    end

    -- Don't continue if the attacker entity doesn't have IsHero method -> attacker entity is something weird
    if attacker.IsHero == nil then
      return
    end

    local damage_threshold = self.threshold
    -- If the damage is below the threshold -> don't continue
    if damage <= damage_threshold then
      return
    end

    local tier = caster.BossTier or 3
    local aggro_factor = BOSS_AGRO_FACTOR or 15
    local current_hp_pct = caster:GetHealth() / caster:GetMaxHealth()
    local aggro_hp_pct = math.min(1 - ((tier * aggro_factor) / caster:GetMaxHealth()), 99/100)

    if current_hp_pct >= aggro_hp_pct then
      return
    end

    if attacker:IsHero() then
      self:ProcMagmaBlood(caster, ability, attacker)
    elseif attacker.GetPlayerOwner then
      local player = attacker:GetPlayerOwner()
      local hero_owner
      if player then
        hero_owner = player:GetAssignedHero()
      end
      if not hero_owner then
        hero_owner = PlayerResource:GetSelectedHeroEntity(UnitVarToPlayerID(attacker))
      end
      if hero_owner then
        self:ProcMagmaBlood(caster, ability, hero_owner)
      end
    end
  end
end

function modifier_magma_boss_magma_blood_passive:ProcMagmaBlood(caster, ability, unit)
  -- If unit is dead, spell immune or in a duel, don't do anything
  if not unit:IsAlive() or unit:IsMagicImmune() or Duels:IsActive() then
    return
  end

  local target_loc = unit:GetAbsOrigin()

  local delay = ability:GetSpecialValueFor("proc_delay")
  local travel_distance = (target_loc - caster:GetAbsOrigin()):Length()
  local travel_speed = ability:GetSpecialValueFor("projectile_speed")
  local travel_time = travel_distance / travel_speed

  -- Create a dummy
  local dummy = CreateUnitByName("npc_dota_custom_dummy_unit", target_loc, false, caster, caster, DOTA_TEAM_NEUTRALS)
  dummy:AddNewModifier(caster, ability, "modifier_oaa_thinker", {})
  dummy:AddNewModifier(caster, ability, "modifier_magma_boss_magma_blood_warning", {travel_time = travel_time, delay = delay, duration = travel_time + delay + 0.1})

  -- Initial tracking projectile info
  self.info = {
    Target = dummy,
    Source = caster,
    Ability = ability,
    EffectName = "particles/units/heroes/hero_snapfire/snapfire_lizard_blobs_arced.vpcf",
    iMoveSpeed = travel_speed,
    bDodgeable = false,
    vSourceLoc = caster:GetOrigin(),
    bDrawsOnMinimap = false,
    bVisibleToEnemies = true,
    bProvidesVision = false,
  }

  -- Start interval
	self:StartIntervalThink(delay)

  -- Start cooldown
  ability:UseResources(false, false, false, true)
end

function modifier_magma_boss_magma_blood_passive:OnIntervalThink()
  local caster = self:GetParent() or self:GetCaster()

  -- Launch the projectile
  if self.info then
    ProjectileManager:CreateTrackingProjectile(self.info)
  end

  -- Sound
  local sound_name = "Hero_Snapfire.MortimerBlob.Launch"
  caster:EmitSound(sound_name)

  -- Stop thinking
  self:StartIntervalThink(-1)
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_magma_blood_warning = class(ModifierBaseClass)

function modifier_magma_boss_magma_blood_warning:IsHidden()
  return true
end

function modifier_magma_boss_magma_blood_warning:IsDebuff()
  return false
end

function modifier_magma_boss_magma_blood_warning:IsPurgable()
  return false
end

function modifier_magma_boss_magma_blood_warning:OnCreated(kv)
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local caster = self:GetCaster()
  local ability = self:GetAbility()

  local loc = parent:GetAbsOrigin()
  local radius = ability:GetSpecialValueFor("impact_radius")
  local travel_time = kv.travel_time
  local delay = kv.delay

  -- Warning particle
  local particle_name = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf"
  self.indicator = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(self.indicator, 0, loc)
  ParticleManager:SetParticleControl(self.indicator, 1, Vector(radius, 0, -radius))
  ParticleManager:SetParticleControl(self.indicator, 2, Vector(travel_time + delay, 0, 0))
end

function modifier_magma_boss_magma_blood_warning:OnDestroy()
  if self.indicator then
    ParticleManager:DestroyParticle(self.indicator, true)
    ParticleManager:ReleaseParticleIndex(self.indicator)
  end
end

---------------------------------------------------------------------------------------------------

modifier_magma_boss_magma_blood_debuff = class(ModifierBaseClass)

function modifier_magma_boss_magma_blood_debuff:IsHidden()
  return false
end

function modifier_magma_boss_magma_blood_debuff:IsDebuff()
  return true
end

function modifier_magma_boss_magma_blood_debuff:IsPurgable()
  return true
end

function modifier_magma_boss_magma_blood_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
  else
    self.move_speed_slow = -40
  end
end

function modifier_magma_boss_magma_blood_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
  return funcs
end

function modifier_magma_boss_magma_blood_debuff:GetModifierMoveSpeedBonus_Percentage()
  return self.move_speed_slow
end

function modifier_magma_boss_magma_blood_debuff:GetEffectName()
  return "particles/units/heroes/hero_snapfire/hero_snapfire_burn_debuff.vpcf"
end

function modifier_magma_boss_magma_blood_debuff:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_magma_boss_magma_blood_debuff:GetStatusEffectName()
  return "particles/status_fx/status_effect_snapfire_magma.vpcf"
end

function modifier_magma_boss_magma_blood_debuff:StatusEffectPriority()
  return MODIFIER_PRIORITY_LOW
end
