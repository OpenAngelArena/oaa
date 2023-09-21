LinkLuaModifier("modifier_boss_slime_shake_slow", "abilities/boss/slime/boss_slime_shake.lua", LUA_MODIFIER_MOTION_NONE)

------------------------------------------------------------------------------------

boss_slime_shake = class(AbilityBaseClass)

------------------------------------------------------------------------------------

function boss_slime_shake:GetPlaybackRateOverride()
	return 2.0
end

function boss_slime_shake:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf", context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
end

------------------------------------------------------------------------------------

local function RandomPointInsideCircle(x, y, radius, minLength)
	local dist = math.random((minLength or 0), radius)
	local angle = math.random(0, math.pi * 2)

	local xOffset = dist * math.cos(angle)
	local yOffset = dist * math.sin(angle)

	return Vector(x + xOffset, y + yOffset, 0)
end

------------------------------------------------------------------------------------

local function RandomPointsInsideCircleUniform( pos, radius, count, uniform, minLength )
	local points = {}

	local function CheckPoint( v )
		for i=1,#points do
			if (points[i] - v):Length2D() < uniform then return false end
		end
		return true
	end

	local fallback = 150

	for i=1,count do
		local point

		repeat
			point = RandomPointInsideCircle(pos.x, pos.y, radius, minLength)
			fallback = fallback - 1
			if fallback == 0 then
				return points
			end
		until CheckPoint(point)
			point.z = pos.z
			table.insert(points, point)
	end

	return points
end

------------------------------------------------------------------------------------

function boss_slime_shake:OnAbilityPhaseStart()
  local caster = self:GetCaster()

  -- Make the caster uninterruptible while casting this ability
  caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = self:GetCastPoint() + self:GetChannelTime()})

  return true
end

------------------------------------------------------------------------------------

function boss_slime_shake:FireProjectile(point)
	local caster = self:GetCaster()
	local minSize = self:GetSpecialValueFor("projectile_min_size")
	local maxSize = self:GetSpecialValueFor("projectile_max_size")
	local size = RandomInt(minSize, maxSize)
	local delay = self:GetSpecialValueFor("delay")

	local pos = GetGroundPosition(point, caster)

  -- Warning particle
  local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(indicator, 0, pos)
  ParticleManager:SetParticleControl(indicator, 1, Vector(size, size, size))
  ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))

	DebugDrawCircle(pos + Vector(0,0,32), Vector(255,0,0), 55, size, false, delay)

  Timers:CreateTimer(delay, function()
    -- Removing warning particle
    if indicator then
      ParticleManager:DestroyParticle(indicator, true)
      ParticleManager:ReleaseParticleIndex(indicator)
    end

    -- Create Firestorm particle
    local wave = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf", PATTACH_CUSTOMORIGIN, caster)
    ParticleManager:SetParticleControl(wave, 0, pos)
    ParticleManager:ReleaseParticleIndex(wave)
  end)

  Timers:CreateTimer(delay + 0.6, function()
    local units = FindUnitsInRadius(
      caster:GetTeamNumber(),
      pos,
      nil,
      size,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_ALL,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_CLOSEST,
      false
    )

    for _, victim in pairs(units) do
      victim:AddNewModifier( caster, self, "modifier_boss_slime_shake_slow", { duration = self:GetSpecialValueFor("slow_duration") })

      local damageTable = {
        victim = victim,
        attacker = caster,
        damage = self:GetSpecialValueFor("damage"),
        damage_type = self:GetAbilityDamageType(),
        ability = self
      }
      ApplyDamage(damageTable)
    end
  end)
end

------------------------------------------------------------------------------------

function boss_slime_shake:OnSpellStart()
	local caster = self:GetCaster()
	--local minSize = self:GetSpecialValueFor("projectile_min_size")
	local maxSize = self:GetSpecialValueFor("projectile_max_size")
	self.points = RandomPointsInsideCircleUniform( caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("projectile_count"), maxSize, maxSize)
	self.n = 1
	self.t = 0
end

------------------------------------------------------------------------------------

function boss_slime_shake:OnChannelThink(flInterval)
	self.t = self.t + flInterval
	if self.n and self.points[self.n] and self.t > (self:GetChannelTime() / #self.points) * self.n then
		self:FireProjectile(self.points[self.n])
		self.n = self.n + 1
	end
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_shake_slow = class(ModifierBaseClass)

function modifier_boss_slime_shake_slow:IsDebuff()
  return true
end

function modifier_boss_slime_shake_slow:IsPurgable()
  return true
end

function modifier_boss_slime_shake_slow:DeclareFunctions()
  local funcs =
  {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
  }

  return funcs
end

function modifier_boss_slime_shake_slow:GetModifierMoveSpeedBonus_Percentage()
  if not self:GetAbility() then return end
  return self:GetAbility():GetSpecialValueFor("slow")
end
