function hell_golem_splash(keys)
  local caster = keys.caster
  local target = keys.target
  local item = keys.ability
  local radius = item:GetSpecialValueFor("radius")
  local percent = item:GetSpecialValueFor("splash_damage")
  local damage = keys.damage_on_hit * percent * 0.01
  local nearbyUnits = FindUnitsInRadius(
    target:GetTeam(),
    target:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )
  for _,unit in pairs(nearbyUnits) do
    if unit ~= target then
      ApplyDamage({
        victim = unit,
        attacker = caster,
        --damage = damage / caster:GetSpellDamageAmp(),
        damage = damage,
        damage_type = DAMAGE_TYPE_PHYSICAL,
        ability = keys.ability
      })
    end
  end
end

function KillTarget(keys)
  if not keys.caster:IsAlive() then return end
  keys.target:ForceKill(true)
end

function death_archdemon_death_orbs(event)
  local caster = event.caster
  local ability = event.ability
  local origin = caster:GetAbsOrigin()
  local projectile_count = 3 --ability:GetTalentSpecialValueFor("projectile_count") -- If you want to make it more powerful with levels
  local speed = 700
  local time_interval = 0.05 -- Time between each launch

  local info = {
    EffectName =  "particles/ebf/death_spear.vpcf",
    Ability = ability,
    vSpawnOrigin = origin,
    fDistance = 3000,
    fStartRadius = 50,
    fEndRadius = 50,
    Source = caster,
    bHasFrontalCone = false,
    iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
    iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    iUnitTargetType = DOTA_UNIT_TARGET_ALL,
    --fMaxSpeed = 5200,
    bReplaceExisting = false,
    bProvidesVision = false,
    fExpireTime = GameRules:GetGameTime() + 7,
    vVelocity = 0.0, --vVelocity = caster:GetForwardVector() * 1800,
    iMoveSpeed = speed,
  }

  origin.z = 0
  info.vVelocity = origin:Normalized() * speed

  --Creates the projectiles in 1440 degrees
  local projectiles_launched = 0
  local projectiles_to_launch = 7
  Timers:CreateTimer(0.5,function()
    projectiles_launched = projectiles_launched + 1
    for angle = -90,90,(180 / projectile_count) do
      for i=0,projectile_count,1 do
        angle = (projectiles_launched - 1) * 2 + angle
        info.vVelocity = RotatePosition(Vector(0, 0, 0), QAngle(0, angle, 0), caster:GetForwardVector()) * speed
        local projectile = ProjectileManager:CreateLinearProjectile(info)
      end
    end
    if projectiles_launched <= projectiles_to_launch then return 0.5 end
  end)
end

function death_archdemon_death_orbs_hit(event)
  local target = event.target
  if not event.caster:IsAlive() then return end
  if target:GetHealth() <= target:GetMaxHealth() / 4 then
    target.NoTombStone = true
    target:KillTarget()
    Timers:CreateTimer(1.0, function()
      target.NoTombStone = false
    end)
  else
    target:SetHealth(target:GetHealth() * 0.3 + 1)
  end
end

function boss_death_archdemon_death_time(keys)
  local caster = keys.caster
  local origin = caster:GetAbsOrigin()
  local ability = keys.ability
  local timer = 5.0
  local Death_range = ability:GetTalentSpecialValueFor("radius")
  local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
  local targetType = DOTA_UNIT_TARGET_ALL
  local targetFlag = ability:GetAbilityTargetFlags()
  local check = false
  local blink_ability = caster:FindAbilityByName("boss_death_archdemon_blink_on_far")
  local death_position = caster:GetAbsOrigin()

  local units = FindUnitsInRadius(
    caster:GetTeamNumber(),
    origin,
    caster,
    FIND_UNITS_EVERYWHERE,
    targetTeam, targetType,
    targetFlag,
    FIND_CLOSEST,
    false)

  --for _,unit in pairs(units) do
  local unit = units[1]
  local particle = ParticleManager:CreateParticle("particles/generic_aoe_persistent_circle_1/death_timer_glow_rev.vpcf",PATTACH_POINT_FOLLOW,unit)
  ability:ApplyDataDrivenModifier( caster, unit, "target_warning", { duration = timer } )
  blink_ability:StartCooldown(timer + 1)

  Timers:CreateTimer(timer, function()
    local vDiff = unit:GetAbsOrigin() - death_position
    caster:RemoveModifierByName("caster_chrono_fx")

    if vDiff:Length2D() < Death_range and caster:IsAlive() then
      unit:RemoveModifierByName("modifier_tauntmail")
      unit.NoTombStone = true
      unit:KillTarget()

      Timers:CreateTimer(timer, function()
        unit.NoTombStone = false
      end)
    end
  end)
  --  break
  --end
end

function boss_death_archdemon_blink_on_far( keys )
  local caster = keys.caster
  local target = keys.target
  local origin = caster:GetAbsOrigin()
  local ability = keys.ability

  ProjectileManager:ProjectileDodge(keys.caster)  --Disjoints disjointable incoming projectiles.

  ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN, keys.caster)
  keys.caster:EmitSound("DOTA_Item.BlinkDagger.Activate")
  FindClearSpaceForUnit(caster, target:GetAbsOrigin(), true)
end

function boss_demon_king_doom_bring( event )
  local target = event.target
  local caster = event.caster
  local time = GameRules:GetGameTime()
  event.ability:ApplyDataDrivenModifier(caster, target, "fuckingdoomed", { duration = 10 })
  Timers:CreateTimer(0.1, function()
    if target:GetHealth() > target:GetMaxHealth() * 0.025 * GameRules.gameDifficulty and GameRules:GetGameTime() <= time + 10 then
      target:SetHealth(target:GetHealth() * (1 - 0.01 * GameRules.gameDifficulty))
      return 0.5
    else
      if GameRules:GetGameTime() <= time + 10 and caster:IsAlive() then
        target:KillTarget()
      end
    end
  end)
end

function boss_demon_king_doomraze( event )
    local caster = event.caster
    local ability = event.ability
    local fv = caster:GetForwardVector()
    local rv = caster:GetRightVector()
    local location = caster:GetAbsOrigin() + fv*200
    caster.charge = caster.charge - 50
    if caster.charge < 0 then caster.Charge = 0 end
    local damage = ability:GetTalentSpecialValueFor("damage")
    location = location - caster:GetRightVector() * 1000
    if GameRules._NewGamePlus == true then damage = damage*10 end
    local created_line = 0
    Timers:CreateTimer(0.25, function()
      created_line = created_line + 1
      for i=1,8,1 do
        createAOEDamage(
          event,
          "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",
          location,
          250,
          damage,
          DAMAGE_TYPE_PURE,
          2,
          "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts")
        location = location + rv * 250
      end
      location = location - rv * 2000 + fv * 400
      if created_line <= 4 then
        return 1.0
      end
  end)
end

function createAOEDamage(keys, particlesname, location, size, damage, damage_type, duration, sound)
  duration = duration or 3
  damage = damage or 5000
  size = size or 250
  damage_type = damage_type or DAMAGE_TYPE_MAGICAL
  if sound ~= nil then
    StartSoundEventFromPosition(sound, location)
  end

  local AOE_effect = ParticleManager:CreateParticle(particlesname, PATTACH_ABSORIGIN  , keys.caster)
  ParticleManager:SetParticleControl(AOE_effect, 0, location)
  ParticleManager:SetParticleControl(AOE_effect, 1, location)

  Timers:CreateTimer(duration, function()
    ParticleManager:DestroyParticle(AOE_effect, false)
  end)

  local nearbyUnits = FindUnitsInRadius(keys.caster:GetTeam(),
    location,
    nil,
    size,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

  for _,unit in pairs(nearbyUnits) do
    if unit ~= keys.caster then
      if unit:GetUnitName()~="npc_dota_courier" and unit:GetUnitName()~="npc_dota_flying_courier" then
         ApplyDamage({
          victim = unit,
          attacker = keys.caster,
          damage = damage,
          damage_type = damage_type,
          ability = keys.ability
        })
      end
    end
  end
end

function boss_demon_king_hell_tempest( keys )
  local ability = keys.ability
  local caster = keys.caster
  caster.charge = 0
  local casterPoint = caster:GetAbsOrigin()
  local delay = 7
  local messageinfo = {
    message = "The boss is casting Hell Tempest, get in the water!",
    duration = 2
  }
  if caster.warning == nil then messageinfo.duration = 5 caster.warning = true end
  FireGameEvent("show_center_message", messageinfo)

  -- Spawn projectile
  Timers:CreateTimer(delay, function()
    local projectileTable = {
      Ability = ability,
      EffectName = "particles/fire_tornado.vpcf",
      vSpawnOrigin = casterPoint - caster:GetForwardVector()*4000,
      fDistance = 5000,
      fStartRadius = 250,
      fEndRadius = 250,
      fExpireTime = GameRules:GetGameTime() + 10,
      Source = caster,
      bHasFrontalCone = true,
      bReplaceExisting = false,
      bProvidesVision = false,
      iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
      iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      iUnitTargetType = DOTA_UNIT_TARGET_ALL,
      bDeleteOnHit = false,
      vVelocity = caster:GetRightVector() * 1000,
      vAcceleration = caster:GetForwardVector() * 200
    }

    local created_projectile = 0
    Timers:CreateTimer(0.05, function()
      created_projectile = created_projectile + 1
      projectileTable.vSpawnOrigin = projectileTable.vSpawnOrigin + caster:GetForwardVector()*(8000/30)
      projectileTable.vVelocity = caster:GetRightVector() * 1000
      ProjectileManager:CreateLinearProjectile( projectileTable )
      if created_projectile <= 15 then
        return 0.05
      end
    end)

    local created_projectile_bis = 0
    Timers:CreateTimer(0.05, function()
      created_projectile_bis = created_projectile_bis + 1
      projectileTable.vSpawnOrigin = projectileTable.vSpawnOrigin + caster:GetForwardVector()*(8000/30)
      projectileTable.vVelocity = caster:GetRightVector() * -1000
      ProjectileManager:CreateLinearProjectile( projectileTable )
      if created_projectile_bis <= 15 then
        return 0.05
      end
    end)
  end)
end

function boss_demon_king_hell_tempest_hit( event )
  local target = event.target
  if target.InWater ~= true and event.caster:IsAlive() then
    if target:GetUnitName()~="npc_dota_courier" and target:GetUnitName()~="npc_dota_flying_courier" then
      target:KillTarget()
    end
  end
end

function hboss_demon_king_hell_tempest_damage( event )
  local caster = event.caster
  caster.charge = caster.charge + 1
  if caster.charge>=caster:GetMaxMana() then caster.charge = caster:GetMaxMana() end
end

function boss_demon_king_hell_tempest_charge( event )
  local caster = event.caster
  if caster.charge == nil then
    caster.charge = 0
    caster:SetMana(0)
  elseif caster.charge < 0 then
    caster.charge = 0
  else
    return
  end

  Timers:CreateTimer(0.1, function()
    if caster.charge < caster:GetMaxMana() then
      caster.charge = caster.charge + 0.25
      caster:SetMana(math.ceil(caster.charge))
      return 0.03
    else
      caster:SetMana(math.ceil(caster.charge))
      return 0.03
    end
  end)
end
