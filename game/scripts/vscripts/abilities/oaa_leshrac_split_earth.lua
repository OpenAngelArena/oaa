leshrac_split_earth_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_leshrac_split_earth_oaa_debuff", "abilities/oaa_leshrac_split_earth.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_leshrac_split_earth_oaa_thinker", "abilities/oaa_leshrac_split_earth.lua", LUA_MODIFIER_MOTION_NONE)

function leshrac_split_earth_oaa:Precache(context)
  PrecacheResource("particle", "particles/leshrac/leshrac_split_earth_aoe_indicator.vpcf", context)
end

function leshrac_split_earth_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function leshrac_split_earth_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target_pos = self:GetCursorPosition()

  CreateModifierThinker(caster, self, "modifier_leshrac_split_earth_oaa_thinker", {}, target_pos, caster:GetTeamNumber(), false)
end

function leshrac_split_earth_oaa:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_leshrac_split_earth_oaa_thinker = class(ModifierBaseClass)

function modifier_leshrac_split_earth_oaa_thinker:IsHidden()
  return true
end

function modifier_leshrac_split_earth_oaa_thinker:IsDebuff()
  return false
end

function modifier_leshrac_split_earth_oaa_thinker:IsPurgable()
  return false
end

function modifier_leshrac_split_earth_oaa_thinker:OnCreated()
  if not IsServer() then
    return
  end

  local delay = self:GetAbility():GetSpecialValueFor("delay")

  self:StartIntervalThink(delay)
end

function modifier_leshrac_split_earth_oaa_thinker:OnIntervalThink()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()
  local parent = self:GetParent()
  local ability = self:GetAbility()

  local target_pos = parent:GetAbsOrigin()

  local radius = ability:GetSpecialValueFor("radius")
  local damage = ability:GetSpecialValueFor("damage")
  local stun_duration = ability:GetSpecialValueFor("stun_duration")

  if self.shard_split_earth and self.shard_split_earth_count then
    -- Remove the previous instance of the indicator particle
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, true)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end
    self.shard_split_earth_count = self.shard_split_earth_count + 1
    if self.shard_split_earth_count > ability:GetSpecialValueFor("shard_extra_instances") then
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end
    -- Increase the radius
    radius = radius + self.shard_split_earth_count * ability:GetSpecialValueFor("shard_extra_radius_per_instance")
  end

  local damage_table = {
    attacker = caster,
    damage = damage,
    damage_type = ability:GetAbilityDamageType(),
    ability = ability,
  }

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(target_pos, radius, false)

  -- Find enemies in the area
  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    target_pos,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Apply stun and damage to each enemy
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsInvulnerable() then

      -- Apply stun first
      local duration = enemy:GetValueChangedByStatusResistance(stun_duration)
      enemy:AddNewModifier(caster, ability, "modifier_leshrac_split_earth_oaa_debuff", {duration = duration})

      -- Apply damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  -- Particle
  local nFXIndex = ParticleManager:CreateParticle("particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(nFXIndex, 0, target_pos)
  ParticleManager:SetParticleControl(nFXIndex, 1, Vector(radius, 1, 1))
  ParticleManager:ReleaseParticleIndex(nFXIndex)

  -- Sound
  EmitSoundOnLocationWithCaster(target_pos, "Hero_Leshrac.Split_Earth", caster)

  if caster:HasShardOAA() then
    local interval = ability:GetSpecialValueFor("shard_interval")
    if not self.shard_split_earth_count or self.shard_split_earth_count < ability:GetSpecialValueFor("shard_extra_instances") then
      -- Indicator particle
      local new_radius = radius + ability:GetSpecialValueFor("shard_extra_radius_per_instance")
      self.particle = ParticleManager:CreateParticle("particles/leshrac/leshrac_split_earth_aoe_indicator.vpcf", PATTACH_CUSTOMORIGIN, caster)
      ParticleManager:SetParticleControl(self.particle, 0, target_pos)
      ParticleManager:SetParticleControl(self.particle, 1, Vector(new_radius, 0, 0))
      ParticleManager:SetParticleControl(self.particle, 2, Vector(interval + 0.1, 0, 0))
    end

    if not self.shard_split_earth then
      self.shard_split_earth = true
      self.shard_split_earth_count = 0

      -- Start with the new interval
      self:StartIntervalThink(interval)
    end
  else
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_leshrac_split_earth_oaa_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  if self.particle then
    ParticleManager:DestroyParticle(self.particle, true)
    ParticleManager:ReleaseParticleIndex(self.particle)
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    -- Kill the thinker entity if it exists
    parent:ForceKillOAA(false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_leshrac_split_earth_oaa_debuff = class(ModifierBaseClass)

function modifier_leshrac_split_earth_oaa_debuff:IsHidden()
  return false
end

function modifier_leshrac_split_earth_oaa_debuff:IsDebuff()
  return true
end

function modifier_leshrac_split_earth_oaa_debuff:IsPurgable()
  return true
end

function modifier_leshrac_split_earth_oaa_debuff:IsStunDebuff()
  return true
end

function modifier_leshrac_split_earth_oaa_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_leshrac_split_earth_oaa_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_leshrac_split_earth_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_leshrac_split_earth_oaa_debuff:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_leshrac_split_earth_oaa_debuff:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end
