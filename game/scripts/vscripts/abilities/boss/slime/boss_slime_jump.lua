LinkLuaModifier("modifier_generic_projectile", "modifiers/modifier_generic_projectile.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_slime_jump_slow", "abilities/boss/slime/boss_slime_jump.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

boss_slime_jump = class(AbilityBaseClass)

------------------------------------------------------------------------------------

function boss_slime_jump:GetPlaybackRateOverride()
	return 0.1
end

function boss_slime_jump:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/units/heroes/hero_techies/techies_blast_off_fire_smallmoketrail.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
end

------------------------------------------------------------------------------------

function boss_slime_jump:FindTargets(position)
  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")

  return FindUnitsInRadius(
    caster:GetTeamNumber(),
    position or caster:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )
end

------------------------------------------------------------------------------------

function boss_slime_jump:OnAbilityPhaseStart()
  local target = self:GetCursorPosition()
  local radius = self:GetSpecialValueFor("radius")

  DebugDrawCircle(target + Vector(0,0,32), Vector(255,0,0), 55, radius, false, self:GetCastPoint())

  return true
end

------------------------------------------------------------------------------------

function boss_slime_jump:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local origin = caster:GetAbsOrigin()
  local radius = self:GetSpecialValueFor("radius")

  -- Warning particle (while Slime is flying)
  local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(indicator, 0, target)
  ParticleManager:SetParticleControl(indicator, 1, Vector(radius, radius, radius))
  ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))

  local projectileModifier = caster:AddNewModifier(caster, self, "modifier_generic_projectile", {})
  local projectileTable = {
    onLandedCallback = function ()
      local shakeAbility = caster:FindAbilityByName("boss_slime_shake")
      if shakeAbility and RandomInt(1, 100) > shakeAbility:GetSpecialValueFor("chance") then
        ExecuteOrderFromTable({
          UnitIndex = caster:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
          AbilityIndex = shakeAbility:entindex(),
        })
      end

      local smoke = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_blast_off_fire_smallmoketrail.vpcf", PATTACH_POINT, caster)
      ParticleManager:ReleaseParticleIndex(smoke)

      -- Remove warning particle
      if indicator then
        ParticleManager:DestroyParticle(indicator, true)
        ParticleManager:ReleaseParticleIndex(indicator)
      end

      -- Destination vector (location where slime landed)
      local point = caster:GetAbsOrigin() or target

      local knockbackModifierTable = {
        should_stun = 1,
        knockback_distance = self:GetSpecialValueFor("knockback"),
        knockback_height = 80,
        center_x = point.x,
        center_y = point.y,
        center_z = point.z
      }

      local damageTable = {
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = self:GetAbilityDamageType(),
        ability = self
      }

      local units = self:FindTargets(point)

      for _, v in pairs(units) do
        knockbackModifierTable.knockback_duration = v:GetValueChangedByStatusResistance(1.0)
        knockbackModifierTable.duration = knockbackModifierTable.knockback_duration

        v:AddNewModifier(caster, self, "modifier_knockback", knockbackModifierTable)

        v:AddNewModifier(caster, self, "modifier_boss_slime_jump_slow", {duration = self:GetSpecialValueFor("slow_duration")})

        -- Apply damage
        damageTable.victim = v
        ApplyDamage(damageTable)
      end

      EmitSoundOnLocationWithCaster(point, "Hero_Techies.Suicide", caster)

      local explosion = ParticleManager:CreateParticle("particles/econ/items/techies/techies_arcana/techies_suicide_arcana.vpcf", PATTACH_CUSTOMORIGIN, caster)
      ParticleManager:SetParticleControl(explosion, 0, point)
      ParticleManager:SetParticleControl(explosion, 3, point)
      ParticleManager:ReleaseParticleIndex(explosion)
    end,
    speed = self:GetSpecialValueFor("movement_speed"),
    origin = origin,
    target = target,
    height = 256,
    flail = true,
    noInvul = true,
    selectable = true
  }
  projectileModifier:InitProjectile(projectileTable)
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_jump_slow = class(ModifierBaseClass)

function modifier_boss_slime_jump_slow:IsDebuff()
  return true
end

function modifier_boss_slime_jump_slow:IsPurgable()
  return true
end

function modifier_boss_slime_jump_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_boss_slime_jump_slow:GetModifierMoveSpeedBonus_Percentage()
  if not self:GetAbility() then return end
  return self:GetAbility():GetSpecialValueFor("slow")
end
