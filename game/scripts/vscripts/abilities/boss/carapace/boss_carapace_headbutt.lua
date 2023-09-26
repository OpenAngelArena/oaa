LinkLuaModifier("modifier_boss_carapace_headbutt_slow", "abilities/boss/carapace/boss_carapace_headbutt.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_carapace_headbutt = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_carapace_headbutt:Precache(context)
  PrecacheResource("particle", "particles/warning/warning_particle_cone.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/antimage/antimage_ti7_golden/antimage_blink_start_ti7_golden_smoke.vpcf", context)
  PrecacheResource("particle", "particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts", context)
end

function boss_carapace_headbutt:GetPlaybackRateOverride()
  return 0.25
end

function boss_carapace_headbutt:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local width = self:GetSpecialValueFor("width")
    local distance = self:GetSpecialValueFor("damage_range")
    local castTime = self:GetCastPoint()
    local direction = caster:GetForwardVector()

    -- Make the caster uninterruptible while casting this ability
    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = castTime + 0.1})

    -- Warning particle
    local FX = ParticleManager:CreateParticle("particles/warning/warning_particle_cone.vpcf", PATTACH_WORLDORIGIN, caster)
    ParticleManager:SetParticleControl(FX, 1, caster:GetAbsOrigin())
    ParticleManager:SetParticleControl(FX, 2, caster:GetAbsOrigin() + direction*(distance+width) + Vector(0, 0, 50))
    ParticleManager:SetParticleControl(FX, 3, Vector(width, width, width))
    ParticleManager:SetParticleControl(FX, 4, Vector(255, 0, 255))
    ParticleManager:ReleaseParticleIndex(FX)

    --DebugDrawBoxDirection(caster:GetAbsOrigin(), Vector(0,-width,0), Vector(distance*2,width,50), direction, Vector(255,0,0), 1, castTime)
  end
  return true
end

--------------------------------------------------------------------------------

function boss_carapace_headbutt:GetEnemies()
  local caster = self:GetCaster()
  local damage_range = self:GetSpecialValueFor("damage_range")

  local startPoint = caster:GetAbsOrigin()
  local endPoint = startPoint + (caster:GetForwardVector() * damage_range)

  local enemies = FindUnitsInLine(
    caster:GetTeamNumber(),
    startPoint,
    endPoint,
    caster,
    self:GetSpecialValueFor("width"),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_ALL,
    DOTA_UNIT_TARGET_FLAG_NONE
  )

  return enemies
end

--------------------------------------------------------------------------------

function boss_carapace_headbutt:OnSpellStart()
  local caster = self:GetCaster()
  local range = self:GetSpecialValueFor("range")
  local target = (caster:GetForwardVector() * range) + caster:GetAbsOrigin()

  caster:EmitSound("Hero_Juggernaut.BladeDance")

  -- Needs removal because of self-stun
  caster:RemoveModifierByName("modifier_anti_stun_oaa")

  local smoke = ParticleManager:CreateParticle("particles/econ/items/antimage/antimage_ti7_golden/antimage_blink_start_ti7_golden_smoke.vpcf", PATTACH_CUSTOMORIGIN, caster)
  ParticleManager:SetParticleControl(smoke, 0, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(smoke)

  local enemies = self:GetEnemies()

  local knockbackModifierTable = {
    should_stun = 0,
    knockback_duration = 0.5,
    duration = 0.5,
    knockback_distance = range,
    knockback_height = 50,
    center_x = target.x,
    center_y = target.y,
    center_z = target.z
  }

  local damageTable = {
    attacker = caster,
    damage = self:GetSpecialValueFor("damage"),
    damage_type = self:GetAbilityDamageType(),
    damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK,
    ability = self
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() and not enemy:IsDebuffImmune() then
      --DebugDrawSphere(enemy:GetAbsOrigin(), Vector(255,0,255), 255, 64, true, 5.3)

      enemy:EmitSound("Hero_Ursa.Attack")

      local impact = ParticleManager:CreateParticle("particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf", PATTACH_POINT_FOLLOW, enemy)
      ParticleManager:ReleaseParticleIndex(impact)

      -- Apply modifiers first
      --knockbackModifierTable.duration = enemy:GetValueChangedByStatusResistance(0.5) -- uncomment if it stuns
      --knockbackModifierTable.knockback_duration = enemy:GetValueChangedByStatusResistance(0.5) -- uncomment if it stuns
      enemy:AddNewModifier( caster, self, "modifier_knockback", knockbackModifierTable )
      enemy:AddNewModifier( caster, self, "modifier_boss_carapace_headbutt_slow", {duration = self:GetSpecialValueFor("slow_duration")} )

      -- Do damage
      damageTable.victim = enemy
      ApplyDamage(damageTable)
    end
  end

  caster:SetAbsOrigin(target)
  caster:Stop()
  caster:AddNewModifier( caster, self, "modifier_stunned", {duration=self:GetSpecialValueFor("self_stun")} )
end

--------------------------------------------------------------------------------

modifier_boss_carapace_headbutt_slow = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:IsDebuff()
	return true
end

function modifier_boss_carapace_headbutt_slow:IsPurgable()
  return true
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:DeclareFunctions()
	return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

------------------------------------------------------------------------------------

function modifier_boss_carapace_headbutt_slow:GetModifierMoveSpeedBonus_Percentage()
  return self:GetAbility():GetSpecialValueFor("move_speed_slow_pct")
end

function modifier_boss_carapace_headbutt_slow:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("attack_speed_slow")
end
