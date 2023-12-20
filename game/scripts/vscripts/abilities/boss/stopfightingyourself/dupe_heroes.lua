LinkLuaModifier("modifier_boss_stopfightingyourself_illusion", "abilities/boss/stopfightingyourself/dupe_heroes.lua", LUA_MODIFIER_MOTION_NONE)

boss_stopfightingyourself_dupe_heroes = class(AbilityBaseClass)

function boss_stopfightingyourself_dupe_heroes:Precache(context)
  PrecacheResource("particle", "particles/darkmoon_creep_warning.vpcf", context)
  PrecacheResource("particle", "particles/status_fx/status_effect_terrorblade_reflection.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts", context)
end

function boss_stopfightingyourself_dupe_heroes:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    local delay = self:GetCastPoint()

    -- Make the caster uninterruptible while casting this ability
    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})

    -- Warning particle
    local indicator = ParticleManager:CreateParticle("particles/darkmoon_creep_warning.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(indicator, 0, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true)
    ParticleManager:SetParticleControl(indicator, 1, Vector(radius, radius, radius))
    ParticleManager:SetParticleControl(indicator, 15, Vector(255, 26, 26))
    self.nPreviewFX = indicator
  end
  return true
end

function boss_stopfightingyourself_dupe_heroes:OnAbilityPhaseInterrupted()
  if IsServer() then
    if self.nPreviewFX then
      ParticleManager:DestroyParticle(self.nPreviewFX, true)
      ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
      self.nPreviewFX = nil
    end
  end
end

function boss_stopfightingyourself_dupe_heroes:OnSpellStart()
  -- Remove ability phase (cast) particle
  if self.nPreviewFX then
    ParticleManager:DestroyParticle(self.nPreviewFX, true)
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end

  local caster = self:GetCaster()
  local radius = self:GetSpecialValueFor("radius")
  local illu_duration = self:GetSpecialValueFor("illusion_duration")
  local illu_out_dmg = self:GetSpecialValueFor("illusion_outgoing_damage")
  local illu_inc_dmg = self:GetSpecialValueFor("illusion_incoming_damage")
  local max_illusions = self:GetSpecialValueFor("max_illusions")

  local caster_location = caster:GetAbsOrigin()

  -- Find enemy heroes in a radius
  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    caster_location,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local illu_table = {
    outgoing_damage = 100 - illu_out_dmg,
    incoming_damage = illu_inc_dmg - 100,
    bounty_base = 0,
    bounty_growth = 0,
    outgoing_damage_structure = 0,
    outgoing_damage_roshan = 0,
    duration = illu_duration,
  }

  local do_sound
  local illu_count = 0
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy:IsRealHero() and not enemy:IsTempestDouble() and not enemy:IsClone() and illu_count < max_illusions then
      do_sound = true
      -- Create an illusion for the enemy
      local illusions = CreateIllusions(caster, enemy, illu_table, 1, enemy:GetHullRadius(), false, true)
      for _, illusion in pairs(illusions) do
        illusion:SetHealth(illusion:GetMaxHealth())
        illusion:SetMana(illusion:GetMaxMana())
        illusion:AddNewModifier(caster, self, "modifier_boss_stopfightingyourself_illusion", {duration = illu_duration})

        Timers:CreateTimer(1/30, function()
          -- Order the illusion to attack
          ExecuteOrderFromTable({
            UnitIndex = illusion:entindex(),
            OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
            Position = enemy:GetAbsOrigin(),
            Queue = false,
          })
        end)

        illu_count = illu_count + 1
      end
    end
  end

  -- Sound
  if do_sound then
    EmitSoundOnLocationWithCaster(caster_location, "Hero_Terrorblade.Reflection", caster)
  end
end

---------------------------------------------------------------------------------------------------

modifier_boss_stopfightingyourself_illusion = class(ModifierBaseClass)

function modifier_boss_stopfightingyourself_illusion:IsHidden()
  return true
end

function modifier_boss_stopfightingyourself_illusion:IsDebuff()
  return false
end

function modifier_boss_stopfightingyourself_illusion:IsPurgable()
  return false
end

function modifier_boss_stopfightingyourself_illusion:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
  }
end

function modifier_boss_stopfightingyourself_illusion:GetStatusEffectName()
  return "particles/status_fx/status_effect_terrorblade_reflection.vpcf"
end

function modifier_boss_stopfightingyourself_illusion:StatusEffectPriority()
  return 100000
end
