LinkLuaModifier("modifier_tinkerer_oil_spill_thinker", "abilities/tinkerer/tinkerer_oil_spill.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tinkerer_oil_spill_debuff", "abilities/tinkerer/tinkerer_oil_spill.lua", LUA_MODIFIER_MOTION_NONE)

tinkerer_oil_spill = class({})

function tinkerer_oil_spill:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function tinkerer_oil_spill:OnSpellStart()
  local caster = self:GetCaster()
  local cursor = self:GetCursorPosition()
  local caster_loc = caster:GetAbsOrigin()
  local team = caster:GetTeamNumber()
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")

  -- Calculate duration
  local distance = (cursor - caster_loc):Length2D()
  local thinker_duration = distance / projectile_speed + 1

  -- Create a thinker at the location
  local thinker = CreateModifierThinker(caster, self, "modifier_tinkerer_oil_spill_thinker", {duration = thinker_duration}, cursor, team, false)

  local projectile_table = {
    vSourceLoc = caster_loc,
    Target = thinker,
    iMoveSpeed = projectile_speed,
    bDodgeable = false,
    bIsAttack = false,
    bReplaceExisting = false,
    bIgnoreObstructions = true,
    bDrawsOnMinimap = false,
    bVisibleToEnemies = true,
    EffectName = "particles/units/heroes/hero_shadow_demon/shadow_demon_base_attack.vpcf",
    Ability = self,
    Source = caster,
    bProvidesVision = true,
    iVisionRadius = 100,
    iVisionTeamNumber = team,
  }

  ProjectileManager:CreateTrackingProjectile(projectile_table)

  -- Launch sound
  --caster:EmitSound("")
end

function tinkerer_oil_spill:OnProjectileHit(target, location)
  local caster = self:GetCaster()
  local team = caster:GetTeamNumber()

  local radius = self:GetSpecialValueFor("radius")
  local duration = self:GetSpecialValueFor("duration")

  local splat = ParticleManager:CreateParticle("particles/hero/tinkerer/ground_splatter.vpcf", PATTACH_ABSORIGIN, caster)

  local aboveground = GetGroundPosition(location, nil)
  ParticleManager:SetParticleControl(splat, 0, aboveground)
  ParticleManager:ReleaseParticleIndex(splat)

  local impact_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(impact_particle, 0, aboveground)
  ParticleManager:SetParticleControl(impact_particle, 1, Vector(radius, 0, 0))
  ParticleManager:SetParticleControl(impact_particle, 2, aboveground)
  ParticleManager:ReleaseParticleIndex(impact_particle)

  AddFOWViewer(team, location, radius, 2, false)
  --DebugDrawCircle(location, Vector(255,0,0), 1, radius, true, 1.0)

  local oiled_enemies = FindUnitsInRadius(
    team,
    location,
    nil,
    radius,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Check for talent that increases the duration
  local talent = caster:FindAbilityByName("special_bonus_unique_tinkerer_4")
  if talent and talent:GetLevel() > 0 then
    duration = duration + talent:GetSpecialValueFor("value")
  end

  -- Apply debuff to enemies
  for _, enemy in pairs(oiled_enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
      enemy:AddNewModifier(caster, self, "modifier_tinkerer_oil_spill_debuff", {duration = duration})
    end
  end

  if target then
    target:EmitSound("Hero_Grimstroke.InkOver.Target")

    target:ForceKill(false)
  end

  return true
end

function tinkerer_oil_spill:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_oil_spill_thinker = class({})

function modifier_tinkerer_oil_spill_thinker:IsHidden()
  return true
end

function modifier_tinkerer_oil_spill_thinker:IsPurgable()
  return false
end

function modifier_tinkerer_oil_spill_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:ForceKill(false)
  end
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_oil_spill_debuff = class({})

function modifier_tinkerer_oil_spill_debuff:IsHidden()
  return false
end

function modifier_tinkerer_oil_spill_debuff:IsDebuff()
  return true
end

function modifier_tinkerer_oil_spill_debuff:IsPurgable()
  return true
end

function modifier_tinkerer_oil_spill_debuff:GetStatusEffectName()
  return "particles/status_fx/status_effect_grimstroke_ink_over.vpcf"
end

function modifier_tinkerer_oil_spill_debuff:StatusEffectPriority()
  return MODIFIER_PRIORITY_LOW
end

function modifier_tinkerer_oil_spill_debuff:OnCreated()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  local move_speed_slow = 15
  local attack_speed_slow = 15
  local burn_dps = 30
  local burn_interval = 0.25
  local damage_amp = 0
  local extra_duration = 3

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
    attack_speed_slow = ability:GetSpecialValueFor("attack_speed_slow")
    burn_dps = ability:GetSpecialValueFor("burn_dps")
    burn_interval = ability:GetSpecialValueFor("burn_interval")
    extra_duration = ability:GetSpecialValueFor("ignite_extra_duration")
  end

  -- Check for talent that increases the slow amounts
  local talent = caster:FindAbilityByName("special_bonus_unique_tinkerer_5")
  if talent and talent:GetLevel() > 0 then
    move_speed_slow = move_speed_slow + talent:GetSpecialValueFor("value")
    attack_speed_slow = attack_speed_slow + talent:GetSpecialValueFor("value2")
  end

  -- Check for talent that increases the burn dps
  local talent2 = caster:FindAbilityByName("special_bonus_unique_tinkerer_6")
  if talent2 and talent2:GetLevel() > 0 then
    burn_dps = burn_dps + talent2:GetSpecialValueFor("value")
  end

  -- Check for talent that amplifies the damage
  local talent3 = caster:FindAbilityByName("special_bonus_unique_tinkerer_7")
  if talent3 and talent3:GetLevel() > 0 then
    damage_amp = talent3:GetSpecialValueFor("value")
  end

  -- Status resistance fix
  if IsServer() then
    move_speed_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
    attack_speed_slow = parent:GetValueChangedByStatusResistance(attack_speed_slow)
    self.oil_drip = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_debuff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
  end

  self.move_speed_slow = move_speed_slow
  self.attack_speed_slow = attack_speed_slow
  self.burn_dps = burn_dps
  self.burn_interval = burn_interval
  self.damage_amp = damage_amp
  self.bonus_duration = extra_duration
  self.already_burning = false
end

function modifier_tinkerer_oil_spill_debuff:OnRefresh()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  local move_speed_slow = 15
  local attack_speed_slow = 15
  local burn_dps = 30
  local burn_interval = 0.25
  local damage_amp = 0
  local extra_duration = 3

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    move_speed_slow = ability:GetSpecialValueFor("move_speed_slow")
    attack_speed_slow = ability:GetSpecialValueFor("attack_speed_slow")
    burn_dps = ability:GetSpecialValueFor("burn_dps")
    burn_interval = ability:GetSpecialValueFor("burn_interval")
    extra_duration = ability:GetSpecialValueFor("ignite_extra_duration")
  end

  -- Check for talent that increases the slow amounts
  local talent = caster:FindAbilityByName("special_bonus_unique_tinkerer_5")
  if talent and talent:GetLevel() > 0 then
    move_speed_slow = move_speed_slow + talent:GetSpecialValueFor("value")
    attack_speed_slow = attack_speed_slow + talent:GetSpecialValueFor("value2")
  end

  -- Check for talent that increases the burn dps
  local talent2 = caster:FindAbilityByName("special_bonus_unique_tinkerer_6")
  if talent2 and talent2:GetLevel() > 0 then
    burn_dps = burn_dps + talent2:GetSpecialValueFor("value")
  end

  -- Check for talent that amplifies the damage
  local talent3 = caster:FindAbilityByName("special_bonus_unique_tinkerer_7")
  if talent3 and talent3:GetLevel() > 0 then
    damage_amp = talent3:GetSpecialValueFor("value")
  end

  -- Status resistance fix
  if IsServer() then
    move_speed_slow = parent:GetValueChangedByStatusResistance(move_speed_slow)
    attack_speed_slow = parent:GetValueChangedByStatusResistance(attack_speed_slow)
  end

  self.move_speed_slow = move_speed_slow
  self.attack_speed_slow = attack_speed_slow
  self.burn_dps = burn_dps
  self.burn_interval = burn_interval
  self.damage_amp = damage_amp
  self.bonus_duration = extra_duration
end

function modifier_tinkerer_oil_spill_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_tinkerer_oil_spill_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.move_speed_slow)
end

function modifier_tinkerer_oil_spill_debuff:GetModifierAttackSpeedPercentage()
  return 0 - math.abs(self.attack_speed_slow)
end

function modifier_tinkerer_oil_spill_debuff:GetModifierIncomingDamage_Percentage()
  return self.damage_amp
end

if IsServer() then
  function modifier_tinkerer_oil_spill_debuff:OnTakeDamage(event)
    local attacker = event.attacker
    local inflictor = event.inflictor
    local victim = event.unit

    if not attacker or attacker:IsNull() or not inflictor or not victim or victim:IsNull() then
      return
    end

    local parent = self:GetParent()

    if victim ~= parent then
      return
    end

    --if inflictor:GetName() ~= "tinkerer_smart_missiles" then
      --return
    --end

    if self.already_burning then
      return
    end

    self.already_burning = true

    local particle_name = "particles/econ/items/huskar/huskar_2021_immortal/huskar_2021_immortal_burning_spear_debuff_flame_circulate.vpcf"
    self.burning_particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, parent)

    self:OnIntervalThink()
    self:StartIntervalThink(self.burn_interval)

    -- Increase the duration when ignited
    --self:ForceRefresh()
    local new_duration = self.bonus_duration + self:GetRemainingTime()
    self:SetDuration(new_duration, true)
  end

  function modifier_tinkerer_oil_spill_debuff:OnIntervalThink()
    local burn_table = {
      victim = self:GetParent(),
      attacker = self:GetCaster(),
      damage = self.burn_dps * self.burn_interval,
      damage_type = DAMAGE_TYPE_MAGICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
      ability = self:GetAbility()
    }

    ApplyDamage(burn_table)
  end
end

function modifier_tinkerer_oil_spill_debuff:OnTooltip()
  return self.burn_dps
end

function modifier_tinkerer_oil_spill_debuff:OnDestroy()
  if self.oil_drip then
    ParticleManager:DestroyParticle(self.oil_drip, false)
    ParticleManager:ReleaseParticleIndex(self.oil_drip)
  end

  if self.burning_particle then
    ParticleManager:DestroyParticle(self.burning_particle, false)
    ParticleManager:ReleaseParticleIndex(self.burning_particle)
  end
end
