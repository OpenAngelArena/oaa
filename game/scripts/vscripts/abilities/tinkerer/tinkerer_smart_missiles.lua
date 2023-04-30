LinkLuaModifier("modifier_tinkerer_smart_missiles_stun", "abilities/tinkerer/tinkerer_smart_missiles.lua", LUA_MODIFIER_MOTION_NONE)

tinkerer_smart_missiles = class({})

function tinkerer_smart_missiles:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local caster_loc = caster:GetAbsOrigin()

  if not target then
    return
  end

  local rocket_width = self:GetSpecialValueFor("rocket_width")
  local rocket_speed = self:GetSpecialValueFor("rocket_speed")
  local rocket_range = self:GetSpecialValueFor("rocket_range")
  local rocket_vision = self:GetSpecialValueFor("rocket_vision")

  -- Calculate offset and starting width
  local attachment = caster:ScriptLookupAttachment("attach_attack3")
  local rocket_spawn_loc = caster_loc
  local offset = 0
  if attachment ~= 0 then
    rocket_spawn_loc = caster:GetAttachmentOrigin(attachment)
    offset = (caster_loc - rocket_spawn_loc):Length2D()
  end
  local start_width = rocket_width + offset

  -- Calculate direction
  local direction = (target - rocket_spawn_loc):Normalized()

  -- Reverse cast direction for self point cast
  if target == caster_loc then
    direction = caster:GetForwardVector() * -1
  end

  -- Remove vertical component
  direction.z = 0

  local projectile_table = {
    Ability = self,
    EffectName = "particles/hero/tinkerer/rocket_projectile_linear.vpcf",
    vSpawnOrigin = rocket_spawn_loc,
    fDistance = rocket_range + caster:GetCastRangeBonus(),
    fStartRadius = start_width,
    fEndRadius = rocket_width,
    Source = caster,
    bHasFrontalCone = true,
    bReplaceExisting = false,
    iUnitTargetTeam = self:GetAbilityTargetTeam(),
    iUnitTargetType = self:GetAbilityTargetType(),
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, --DOTA_UNIT_TARGET_FLAG_NONE
    bDeleteOnHit = true,
    vVelocity = direction * rocket_speed,
    bProvidesVision = true,
    iVisionRadius = math.max(rocket_width, rocket_vision),
    iVisionTeamNumber = caster:GetTeamNumber(),
    ExtraData = {
      ox = tostring(caster_loc.x),
      oy = tostring(caster_loc.y),
      oz = tostring(caster_loc.z),
      multishot_bool = 0,
    }
  }

  -- Create projectile
  ProjectileManager:CreateLinearProjectile(projectile_table)

  -- Sound
  caster:EmitSound("Hero_Tinker.Heat-Seeking_Missile")

  -- Multishot missiles talent
  local talent = caster:FindAbilityByName("special_bonus_unique_tinkerer_1")
  if talent and talent:GetLevel() > 0 then
    local multishot_angle = talent:GetSpecialValueFor("multishot_angle")
    local multishot_count = talent:GetSpecialValueFor("multishot_count")

    -- Send additional projectiles specified by the talent
    for i = 0, multishot_count-1 do
      -- Angle multiplier to switch sides between right and left
      local angle_mult = 1
      if i % 2 == 1 then
        angle_mult = -1
      end

      -- Projectiles with indices 0,1 have same angle (also applies for 2,3 or 4,5...)
      local angle = ( math.floor(i / 2) + 1 ) * multishot_angle * angle_mult

      -- Rotate primary direction vector
      local direction_multishot = RotatePosition(Vector(0,0,0), QAngle(0, angle, 0), direction):Normalized()

      -- Calculate velocity for this projectile
      projectile_table.vVelocity = direction_multishot * rocket_speed
      -- Mark this projectile as a multishot projectile
      projectile_table.ExtraData.multishot_bool = 1

      -- Create multishot projectile
      ProjectileManager:CreateLinearProjectile(projectile_table)
    end
  end
end

function tinkerer_smart_missiles:OnProjectileHit_ExtraData(target, location, data)
  if not target or not location then
    return false
  end

  local caster = self:GetCaster()
  local base_damage = self:GetSpecialValueFor("base_damage")

  -- Check for bonus base damage talent
  local talent2 = caster:FindAbilityByName("special_bonus_unique_tinkerer_2")
  if talent2 and talent2:GetLevel() > 0 then
    base_damage = base_damage + talent2:GetSpecialValueFor("value")
  end

  -- Damage table
  local damage_table = {}
  damage_table.victim = target
  damage_table.attacker = caster
  damage_table.damage = base_damage
  damage_table.ability = self
  damage_table.damage_type = self:GetAbilityDamageType()

  -- Glance (go through them, damage them but don't explode) neutral creeps but not bosses and ignore couriers completely
  if (target:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not target:IsOAABoss()) or target:IsCourier() then
    if not target:IsMagicImmune() then
      ApplyDamage(damage_table)
    end
    return false
  end

  -- Check if target is already affected by "STUNNED" from this ability (and caster) to prevent being stunned by multishot missiles
  local stunned_modifier = target:FindModifierByNameAndCaster("modifier_tinkerer_smart_missiles_stun", caster)
  if stunned_modifier and data.multishot_bool == 1 then
    if not target:IsMagicImmune() then
      ApplyDamage(damage_table)
    end
    return false
  end

  local bonus_max_hp_damage = self:GetSpecialValueFor("bonus_max_hp_damage")
  local bonus_damage_range = self:GetSpecialValueFor("bonus_damage_range")
  local stun_duration = self:GetSpecialValueFor("stun_duration")
  local rocket_vision = self:GetSpecialValueFor("rocket_vision")
  local rocket_explode_vision = self:GetSpecialValueFor("rocket_explode_vision")
  local vision_duration = self:GetSpecialValueFor("vision_duration")

  -- Calculate traveled distance
  local origin_position = Vector(tonumber(data.ox), tonumber(data.oy), tonumber(data.oz))
  local travel_distance = (location - origin_position):Length2D()

  -- Calculate bonus damage if traveled distance is higher than the threshold for non-boss units
  local bonus_damage = 0
  if travel_distance >= bonus_damage_range then
    bonus_damage = target:GetMaxHealth() * bonus_max_hp_damage * 0.01
  end

  if target:IsOAABoss() then
    bonus_damage = bonus_damage * 15/100
  end

  -- Calculate total damage
  local total_damage = base_damage + bonus_damage
  damage_table.damage = total_damage

  -- Particle
  local particle_name = "particles/units/heroes/hero_tinker/tinker_missle_explosion.vpcf"
  local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
  ParticleManager:ReleaseParticleIndex(particle)

  -- Status resistance fix
  local actual_duration = target:GetValueChangedByStatusResistance(stun_duration)

  -- Apply stun and damage - stun before the damage (Applying stun after damage is bad)
  if not target:IsMagicImmune() then
    target:AddNewModifier(caster, self, "modifier_tinkerer_smart_missiles_stun", {duration = actual_duration})
    ApplyDamage(damage_table)
  end

  -- Add vision
  local vision_radius = math.max(rocket_vision, rocket_explode_vision)
  AddFOWViewer(caster:GetTeamNumber(), location, vision_radius, vision_duration, false)

  -- Sound
  local sound_name = "Hero_Tinker.Heat-Seeking_Missile.Impact"
  EmitSoundOnLocationWithCaster(location, sound_name, caster)

  -- Missile explosion affects nearby units
  local talent3 = caster:FindAbilityByName("special_bonus_unique_tinkerer_3")
  if not talent3 or talent3:GetLevel() <= 0 then
    return true
  end

  local explode_radius = talent3:GetSpecialValueFor("explode_radius")
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    location,
    nil,
    explode_radius,
    self:GetAbilityTargetTeam(),
    self:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy ~= target and not enemy:IsMagicImmune() then
      -- Status resistance fix
      local enemy_duration = target:GetValueChangedByStatusResistance(stun_duration)

      -- Apply Stun before damage (Applying stun after damage is bad)
      target:AddNewModifier(caster, self, "modifier_tinkerer_smart_missiles_stun", {duration = enemy_duration})

      -- Damage
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  return true
end

function tinkerer_smart_missiles:ProcsMagicStick()
  return true
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_smart_missiles_stun = class(ModifierBaseClass)

function modifier_tinkerer_smart_missiles_stun:IsHidden()
  return false
end

function modifier_tinkerer_smart_missiles_stun:IsDebuff()
  return true
end

function modifier_tinkerer_smart_missiles_stun:IsStunDebuff()
  return true
end

function modifier_tinkerer_smart_missiles_stun:IsPurgable()
  return true
end

function modifier_tinkerer_smart_missiles_stun:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_tinkerer_smart_missiles_stun:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_tinkerer_smart_missiles_stun:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_tinkerer_smart_missiles_stun:GetOverrideAnimation()
  return ACT_DOTA_DISABLED
end

function modifier_tinkerer_smart_missiles_stun:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true,
  }
end
