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
        projectile = ProjectileManager:CreateLinearProjectile(info)
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
  local timer = 6.0
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

  for _,unit in pairs(units) do
    local particle = ParticleManager:CreateParticle("particles/generic_aoe_persistent_circle_1/death_timer_glow_rev.vpcf",PATTACH_POINT_FOLLOW,unit)
    if GameRules.gameDifficulty > 2 then timer = 5.0 else timer = 6.0 end
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
    break
  end
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
