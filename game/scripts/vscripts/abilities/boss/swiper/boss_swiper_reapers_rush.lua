LinkLuaModifier("modifier_boss_swiper_reapers_rush_active", "abilities/boss/swiper/boss_swiper_reapers_rush.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_swiper_reapers_rush_slow", "abilities/boss/swiper/boss_swiper_reapers_rush.lua", LUA_MODIFIER_MOTION_NONE)

boss_swiper_reapers_rush = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:Precache(context)
  PrecacheResource("particle", "particles/warning/warning_particle_cone.vpcf", context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/lich/frozen_chains_ti6/lich_frozenchains_frostnova_swipe.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context)
end

function boss_swiper_reapers_rush:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local width = self:GetSpecialValueFor("radius")
    local target = self:GetCursorPosition()
    local distance = (target - caster:GetAbsOrigin()):Length2D()
    --local castTime = self:GetCastPoint()
    local direction = (target - caster:GetAbsOrigin()):Normalized()

    -- Warning particle
    local FX = ParticleManager:CreateParticle("particles/warning/warning_particle_cone.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(FX, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(FX, 2, caster:GetAbsOrigin() + direction*(distance+width))
    ParticleManager:SetParticleControl(FX, 3, Vector(width, width, width))
    ParticleManager:SetParticleControl(FX, 4, Vector(255, 0, 0))
    ParticleManager:ReleaseParticleIndex(FX)

    -- Destination indicator particle
    local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(indicator, 0, target)
    ParticleManager:SetParticleControl(indicator, 1, Vector(width, width, width))
    ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))

    self.indicator = indicator

    --DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width / 2,0), Vector(distance,width / 2,50), direction, Vector(255,0,0), 1, castTime)
    --DebugDrawCircle(target + Vector(0,0,32), Vector(255,0,0), 128, width, false, castTime + 2.0)
  end
  return true
end

function boss_swiper_reapers_rush:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.indicator then
      ParticleManager:DestroyParticle(self.indicator, true)
      ParticleManager:ReleaseParticleIndex(self.indicator)
      self.indicator = nil
    end
  end
end

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:GetPlaybackRateOverride()
	return 0.275
end

--------------------------------------------------------------------------------

function boss_swiper_reapers_rush:OnSpellStart()
  -- Remove ability phase (indicator) particle
  if self.indicator then
    ParticleManager:DestroyParticle(self.indicator, true)
    ParticleManager:ReleaseParticleIndex(self.indicator)
    self.indicator = nil
  end

  local caster = self:GetCaster()
  local target = self:GetCursorPosition()
  local distance = (target - caster:GetAbsOrigin()):Length2D()
  local direction = (target - caster:GetAbsOrigin()):Normalized()

  caster:Stop()

  local modifierTable = {
    speed = self:GetSpecialValueFor("speed"),
    distance = distance,
    direction_x = direction.x,
    direction_y = direction.y
  }
  caster:AddNewModifier(caster, self, "modifier_boss_swiper_reapers_rush_active", modifierTable)
end

------------------------------------------------------------------------------------

modifier_boss_swiper_reapers_rush_active = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:IsPurgable()
	return false
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:GetActivityTranslationModifiers()
  return "haste"
end

--------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:GetOverrideAnimationRate()
  return 2.0
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:GetOverrideAnimation()
  return ACT_DOTA_RUN
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:GetOverrideAnimationWeight()
  return 1.0
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_WEIGHT,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS
  }
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:CheckState()
  return {
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_STUNNED] = true, -- self stun to prevent casting during Rush?
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_HEXED] = false,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_SILENCED] = false,
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    --[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }
end

function modifier_boss_swiper_reapers_rush_active:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10001
end

------------------------------------------------------------------------------------

if IsServer() then
	function modifier_boss_swiper_reapers_rush_active:OnDestroy()
		local caster = self:GetParent()
		local ability = self:GetAbility()
		local radius = ability:GetSpecialValueFor("radius")

		local units = FindUnitsInRadius(
			caster:GetTeamNumber(),
			caster:GetAbsOrigin(),
			nil,
			radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_ALL,
			DOTA_UNIT_TARGET_FLAG_NONE,
			FIND_ANY_ORDER,
			false
		)

    local damageTable = {
      attacker = caster,
      damage = ability:GetSpecialValueFor("max_damage"),
      damage_type = ability:GetAbilityDamageType(),
      --damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
      ability = ability
    }

    for _, v in pairs(units) do
      if v and not v:IsNull() then
        local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, v)
        ParticleManager:ReleaseParticleIndex(impact)

        v:EmitSound("hero_ursa.attack")

        if not v:IsMagicImmune() and not v:IsDebuffImmune() then
          v:AddNewModifier(caster, ability, "modifier_boss_swiper_reapers_rush_slow", {duration = ability:GetSpecialValueFor("slow_duration")})

          damageTable.victim = v
          ApplyDamage(damageTable)
        end
      end
    end

		local swipe = ParticleManager:CreateParticle("particles/econ/items/lich/frozen_chains_ti6/lich_frozenchains_frostnova_swipe.vpcf", PATTACH_POINT, caster)
		ParticleManager:ReleaseParticleIndex(swipe)

		caster:Stop()
	end
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:OnCreated(keys)
  if not IsServer() then
    return
  end

  self.speed = keys.speed
  self.distance = keys.distance
  self.direction = Vector(keys.direction_x, keys.direction_y, 0)

  self.traveled = 0
  self.interval = 1 / 30
  self.step = self.speed * self.interval
  self.hit = {}

  self:SetDuration(self.distance / self.speed, false)

  self:StartIntervalThink(self.interval)
end

------------------------------------------------------------------------------------

function modifier_boss_swiper_reapers_rush_active:OnIntervalThink()
	local caster = self:GetParent()
	local ability = self:GetAbility()
	local radius = ability:GetSpecialValueFor("radius")

	self.traveled = self.traveled + self.step

	if self.traveled >= self.distance then
		self:Destroy()
		return
	end

	caster:SetAbsOrigin(caster:GetAbsOrigin() + (self.direction * self.step))

	DebugDrawSphere(caster:GetAbsOrigin(), Vector(255,0,0), 255, radius, false, 0.03)

	local units = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

  local damageTable = {
    attacker = caster,
    damage = ability:GetSpecialValueFor("min_damage"),
    damage_type = ability:GetAbilityDamageType(),
    --damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
    ability = ability
  }

  local point = caster:GetAbsOrigin()

  local knockbackModifierTable = {
    should_stun = 1,
    knockback_height = ability:GetSpecialValueFor("push_length"),
    center_x = point.x,
    center_y = point.y,
    center_z = point.z
  }

  for _, v in pairs(units) do
    if v and not v:IsNull() and not self.hit[v:entindex()] then
      self.hit[v:entindex()] = true

      local impact = ParticleManager:CreateParticle("particles/econ/items/bloodseeker/bloodseeker_eztzhok_weapon/bloodseeker_bloodbath_eztzhok_burst.vpcf", PATTACH_POINT_FOLLOW, v)
      ParticleManager:ReleaseParticleIndex(impact)

      v:EmitSound("hero_ursa.attack")

      if not v:IsMagicImmune() and not v:IsDebuffImmune() then
        knockbackModifierTable.knockback_distance = radius - (v:GetAbsOrigin() - point):Length2D()
        knockbackModifierTable.knockback_duration = v:GetValueChangedByStatusResistance(1.0)
        knockbackModifierTable.duration = knockbackModifierTable.knockback_duration

        v:AddNewModifier( caster, ability, "modifier_knockback", knockbackModifierTable )

        damageTable.victim = v
        ApplyDamage(damageTable)
      end
    end
	end
end

---------------------------------------------------------------------------------------------------

modifier_boss_swiper_reapers_rush_slow = class(ModifierBaseClass)

function modifier_boss_swiper_reapers_rush_slow:IsDebuff()
  return true
end

function modifier_boss_swiper_reapers_rush_slow:IsPurgable()
  return true
end

function modifier_boss_swiper_reapers_rush_slow:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }
end

function modifier_boss_swiper_reapers_rush_slow:GetModifierMoveSpeedBonus_Percentage()
  if not self:GetAbility() then return end
  return self:GetAbility():GetSpecialValueFor("slow")
end
