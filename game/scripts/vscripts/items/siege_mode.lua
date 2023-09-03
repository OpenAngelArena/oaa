LinkLuaModifier("modifier_item_splash_cannon_passive", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_siege_mode_thinker", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_item_siege_mode_active", "items/siege_mode.lua", LUA_MODIFIER_MOTION_NONE)

---------------------------------------------------------------------------------------------------

item_siege_mode = class(ItemBaseClass)

function item_siege_mode:GetAOERadius()
  return self:GetSpecialValueFor("active_radius")
end

function item_siege_mode:GetIntrinsicModifierName()
  return "modifier_item_splash_cannon_passive"
end

function item_siege_mode:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()

  if not target then
    return
  end

  -- 'Fix' for the caster not turning to cast this item at the location
  -- Items are weird because they are not supposed to have cast points or to require facing
  -- See Gleipnir in vanilla for reference
  caster:FaceTowards(target)

  -- KVs
  local projectile_speed = self:GetSpecialValueFor("projectile_speed")
  local projectile_vision_radius = self:GetSpecialValueFor("knockback_distance")
  local recoil_distance = self:GetSpecialValueFor("recoil_distance")
  local recoil_duration = self:GetSpecialValueFor("recoil_duration")

  -- Other variables
  local caster_team = caster:GetTeamNumber()
  local caster_loc = caster:GetAbsOrigin()

  -- Calculate projectile stuff
  local distance = (caster_loc - target):Length2D()
  local projectile_duration = distance / projectile_speed + 0.1

  -- Create a dummy for the tracking projectile
  local dummy = CreateModifierThinker(caster, self, "modifier_item_siege_mode_thinker", {duration = projectile_duration}, target, caster_team, false)

  -- Tracking projectile info
  local projectile = {
    EffectName = "particles/base_attacks/ranged_tower_bad.vpcf",
    Ability = self,
    Source = caster,
    vSourceLoc = caster_loc,
    Target = dummy,
    iMoveSpeed = projectile_speed,
    bDodgeable = false,
    bVisibleToEnemies = true,
    bProvidesVision = true,
    iVisionRadius = projectile_vision_radius,
    iVisionTeamNumber = caster_team,
    iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
  }
  -- Create a tracking projectile
  ProjectileManager:CreateTrackingProjectile(projectile)

  -- Sound
  caster:EmitSound("Splash_Cannon.Launch")

  -- Initialize knockback table for recoil
  local knockback_table = {
    should_stun = 0,
    center_x = target.x,
    center_y = target.y,
    center_z = target.z,
    duration = recoil_duration,
    knockback_duration = recoil_duration,
    knockback_distance = recoil_distance,
    --knockback_height = recoil_distance / 2,
  }

  -- Apply Recoil to the caster
  caster:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
end

function item_siege_mode:OnProjectileHit(target, location)
  if not target or not location then
    return
  end

  local caster = self:GetCaster()
  local origin = target:GetAbsOrigin()

  -- Ability constants
  local targetTeam = self:GetAbilityTargetTeam()
  local targetType = self:GetAbilityTargetType()
  local targetFlags = self:GetAbilityTargetFlags()
  local damageType = self:GetAbilityDamageType()

  -- KVs
  local radius = self:GetSpecialValueFor("active_radius")
  local attack_damage_percent = self:GetSpecialValueFor("active_splash_percent")
  local bonus_damage = self:GetSpecialValueFor("active_damage")
  local distance = self:GetSpecialValueFor("knockback_distance")
  local duration = self:GetSpecialValueFor("knockback_duration")

  -- Initialize knockback table
  local knockback_table = {
    should_stun = 0,
    center_x = origin.x,
    center_y = origin.y,
    center_z = origin.z,
    duration = duration,
    knockback_duration = duration,
    knockback_distance = distance,
    knockback_height = distance / 2,
  }

  -- Initialize damage table
  local damage_table = {
    attacker = caster,
    damage_type = damageType or DAMAGE_TYPE_PHYSICAL,
    damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DOTA_DAMAGE_FLAG_BYPASSES_BLOCK),
    ability = self,
  }

  local splash_damage = caster:GetAverageTrueAttackDamage(nil) * attack_damage_percent * 0.01
  if caster:IsRangedAttacker() then
    damage_table.damage = bonus_damage + splash_damage
  else
  -- Melee casters don't apply splash
    damage_table.damage = bonus_damage
  end

  -- find units around the target location
  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    origin,
    nil,
    radius,
    targetTeam,
    targetType,
    targetFlags,
    FIND_ANY_ORDER,
    false
  )

  -- Particles
  local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(part, 3, origin)
  ParticleManager:ReleaseParticleIndex(part)
  local explosion = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak_explosion.vpcf", PATTACH_WORLDORIGIN, caster)
  --ParticleManager:SetParticleControl(explosion, 0, origin)
  ParticleManager:SetParticleControl(explosion, 5, origin)
  ParticleManager:ReleaseParticleIndex(explosion)

  -- iterate through all targets
  for _, unit in pairs(units) do
    if unit and not unit:IsNull() then
      if not unit:IsMagicImmune() and not unit:IsAttackImmune() then
        -- Apply knockback
        unit:AddNewModifier(caster, self, "modifier_knockback", knockback_table)
      end

      -- Apply damage
      damage_table.victim = unit
      ApplyDamage(damage_table)
    end
  end

  -- Destroy trees
  GridNav:DestroyTreesAroundPoint(origin, radius, false)

  -- Sound
  EmitSoundOnLocationWithCaster(location, "Splash_Cannon.Explosion", caster)

  return true
end

item_siege_mode_2 = item_siege_mode

---------------------------------------------------------------------------------------------------

modifier_item_splash_cannon_passive = class(ModifierBaseClass)

function modifier_item_splash_cannon_passive:IsHidden()
  return true
end

function modifier_item_splash_cannon_passive:IsDebuff()
  return false
end

function modifier_item_splash_cannon_passive:IsPurgable()
  return false
end

function modifier_item_splash_cannon_passive:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_splash_cannon_passive:OnCreated()
  self:OnRefresh()
  if IsServer() then
    self:GetParent():ChangeAttackProjectile()
    self:StartIntervalThink(0.1)
  end
end

function modifier_item_splash_cannon_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_health = ability:GetSpecialValueFor("bonus_health")
    self.bonus_health_regen = ability:GetSpecialValueFor("bonus_health_regen")
    self.bonus_strength = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_agility = ability:GetSpecialValueFor("bonus_agility")
    self.bonus_intellect = ability:GetSpecialValueFor("bonus_intellect")
    self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
    self.attack_range = ability:GetSpecialValueFor("bonus_attack_range")
  end

  if IsServer() then
    self:OnIntervalThink()
  end
end

function modifier_item_splash_cannon_passive:OnIntervalThink()
  if self:IsFirstItemInInventory() then
    self:SetStackCount(2)
  else
    self:SetStackCount(1)
  end
end

function modifier_item_splash_cannon_passive:OnDestroy()
  if IsServer() then
    self:GetParent():ChangeAttackProjectile()
  end
end

function modifier_item_splash_cannon_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_item_splash_cannon_passive:GetModifierHealthBonus()
  return self.bonus_health or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_splash_cannon_passive:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Strength()
  return self.bonus_strength or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Agility()
  return self.bonus_agility or self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_splash_cannon_passive:GetModifierBonusStats_Intellect()
  return self.bonus_intellect or self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

function modifier_item_splash_cannon_passive:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_splash_cannon_passive:GetModifierAttackRangeBonus()
  local parent = self:GetParent()
  if not parent:IsRangedAttacker() or self:GetStackCount() ~= 2 then
    return 0
  end

  -- Prevent stacking with Dragon Lance and Hurricane Pike
  if parent:HasModifier("modifier_item_dragon_lance") or parent:HasModifier("modifier_item_hurricane_pike") then
    return 0
  end

  return self.attack_range or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
end

if IsServer() then
  function modifier_item_splash_cannon_passive:OnAttackLanded(event)
    -- Check if first item in inventory -> prevent the code below from executing multiple times for each Splash Cannon
    if not self:IsFirstItemInInventory() then
      return
    end

    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Splash doesn't work on illusions and melee units
    if parent:IsIllusion() or not parent:IsRangedAttacker() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() then
      return
    end

    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return
    end

    local origin = target:GetAbsOrigin()

    -- set the targeting requirements for the actual targets
    local targetTeam = ability:GetAbilityTargetTeam()
    local targetType = ability:GetAbilityTargetType()
    local targetFlags = ability:GetAbilityTargetFlags()

    -- Splash parameters
    local splash_radius = ability:GetSpecialValueFor("passive_splash_radius")
    local splash_percent = ability:GetSpecialValueFor("passive_splash_percent")

    -- find all appropriate targets around the initial target
    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      origin,
      nil,
      splash_radius,
      targetTeam,
      targetType,
      targetFlags,
      FIND_ANY_ORDER,
      false
    )

    -- get the wearer's damage
    local damage = event.original_damage

    -- get the damage modifier
    local actual_damage = damage * splash_percent * 0.01

    -- Damage table
    local damage_table = {}
    damage_table.attacker = parent
    damage_table.damage_type = ability:GetAbilityDamageType() or DAMAGE_TYPE_PHYSICAL
    damage_table.ability = ability
    damage_table.damage = actual_damage
    damage_table.damage_flags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)

    -- Show particle only if damage is above zero and only if there are units nearby
    if actual_damage > 0 and #units > 1 then
      local part = ParticleManager:CreateParticle("particles/econ/items/clockwerk/clockwerk_paraflare/clockwerk_para_rocket_flare_explosion.vpcf", PATTACH_CUSTOMORIGIN, parent)
      ParticleManager:SetParticleControl(part, 3, origin)
      ParticleManager:ReleaseParticleIndex(part)
    end

    -- iterate through all targets
    for _, unit in pairs(units) do
      if unit and not unit:IsNull() and unit ~= target then
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end

    -- sound
    target:EmitSound("dota_fountain.ProjectileImpact")
  end
end

---------------------------------------------------------------------------------------------------

modifier_item_siege_mode_thinker = class(ModifierBaseClass)

function modifier_item_siege_mode_thinker:IsHidden()
  return true
end

function modifier_item_siege_mode_thinker:IsDebuff()
  return false
end

function modifier_item_siege_mode_thinker:IsPurgable()
  return false
end

function modifier_item_siege_mode_thinker:OnCreated()

end

function modifier_item_siege_mode_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:ForceKillOAA(false)
  end
end

---------------------------------------------------------------------------------------------------
--[[
modifier_item_siege_mode_active = class(ModifierBaseClass)

function modifier_item_siege_mode_active:IsHidden()
  return false
end

function modifier_item_siege_mode_active:IsDebuff()
  return false
end

function modifier_item_siege_mode_active:IsPurgable()
  return true
end

function modifier_item_siege_mode_active:GetEffectName()
  return "particles/units/heroes/hero_oracle/oracle_fortune_purge_root_pnt.vpcf"
end

function modifier_item_siege_mode_active:OnCreated()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.atkRange = ability:GetSpecialValueFor("siege_attack_range")
    self.castRange = ability:GetSpecialValueFor("siege_cast_range")
    self.atkDmg = ability:GetSpecialValueFor("siege_attack_damage")
    self.atkRate = ability:GetSpecialValueFor("siege_attack_rate")
    self.moveSpeed = ability:GetSpecialValueFor("siege_move_speed")
    self.projectileSpeed = ability:GetSpecialValueFor("siege_projectile_speed")
  end

  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  self.parentWasRanged = true
  -- Check if parent has Metamorphosis, Berserkers Rage, Dragon Form or True Form
  if not parent:HasModifier("modifier_terrorblade_metamorphosis") and not parent:HasAbility("troll_warlord_berserkers_rage") and not parent:HasModifier("modifier_dragon_knight_dragon_form") and not parent:HasModifier("modifier_lone_druid_true_form") then
    if not parent:IsRangedAttacker() then
      self.parentWasRanged = false
      parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
    end
  end

  self:StartIntervalThink(0)
end

function modifier_item_siege_mode_active:OnRefresh()
  local ability = self:GetAbility()

  if ability and not ability:IsNull() then
    self.atkRange = ability:GetSpecialValueFor("siege_attack_range")
    self.castRange = ability:GetSpecialValueFor("siege_cast_range")
    self.atkDmg = ability:GetSpecialValueFor("siege_attack_damage")
    self.atkRate = ability:GetSpecialValueFor("siege_attack_rate")
    self.moveSpeed = ability:GetSpecialValueFor("siege_move_speed")
    self.projectileSpeed = ability:GetSpecialValueFor("siege_projectile_speed")
  end
end

function modifier_item_siege_mode_active:OnIntervalThink()
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  if not ability or ability:IsNull() or ability:GetItemState() ~= 1 then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_item_siege_mode_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_FIXED_ATTACK_RATE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
  }

  return funcs
end

function modifier_item_siege_mode_active:CheckState()
  if self:GetParent():IsRangedAttacker() then
    return {
      [MODIFIER_STATE_ROOTED] = true,
    }
  end
  return {}
end

function modifier_item_siege_mode_active:GetModifierPreAttack_BonusDamage()
  return self.atkDmg or 500
end

function modifier_item_siege_mode_active:GetModifierFixedAttackRate()
  return self.atkRate or 0.7
end

function modifier_item_siege_mode_active:GetModifierAttackRangeBonus()
  if self:GetParent():IsRangedAttacker() then
    return self.atkRange or 600
  end

  return 0
end

function modifier_item_siege_mode_active:GetModifierCastRangeBonus()
  return self.castRange or 0
end

function modifier_item_siege_mode_active:GetModifierMoveSpeed_Absolute()
  return self.moveSpeed or 270
end

function modifier_item_siege_mode_active:GetModifierProjectileSpeedBonus()
  local parent = self:GetParent()
  if not IsServer() or parent:HasModifier("modifier_item_princes_knife") then
    return 0
  end

  if self.checkProjectileSpeed then
    return 0
  else
    self.checkProjectileSpeed = true
    local projectile_speed = parent:GetProjectileSpeed()
    self.checkProjectileSpeed = false
    if projectile_speed > self.projectileSpeed then
      return self.projectileSpeed - projectile_speed
    end
  end

  return 0
end

function modifier_item_siege_mode_active:GetTexture()
  return "custom/siege_mode_active"
end
]]
