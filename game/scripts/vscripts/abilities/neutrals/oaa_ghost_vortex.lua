LinkLuaModifier("modifier_vortex_oaa_thinker", "abilities/neutrals/oaa_ghost_vortex.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_vortex_oaa_debuff", "abilities/neutrals/oaa_ghost_vortex.lua", LUA_MODIFIER_MOTION_NONE)

ghost_vortex_oaa = class(AbilityBaseClass)

function ghost_vortex_oaa:Precache(context)
  PrecacheResource("particle", "particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", context)
  PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ancient_apparition.vsndevts", context)
end

function ghost_vortex_oaa:GetAOERadius()
  return self:GetSpecialValueFor("radius")
end

function ghost_vortex_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local point = self:GetCursorPosition()

  if not point then
    return
  end

  -- Sound on cast
  EmitSoundOnLocationWithCaster(point, "Hero_Ancient_Apparition.IceVortexCast", caster)

  -- Thinker - aura emitter
  CreateModifierThinker(caster, self, "modifier_vortex_oaa_thinker", {Duration = self:GetSpecialValueFor("duration")}, point, caster:GetTeam(), false)

  GridNav:DestroyTreesAroundPoint(point, self:GetSpecialValueFor("radius"), true)
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

modifier_vortex_oaa_thinker = class({})

function modifier_vortex_oaa_thinker:IsHidden()
  return true
end

function modifier_vortex_oaa_thinker:IsDebuff()
  return false
end

function modifier_vortex_oaa_thinker:IsPurgable()
  return false
end

function modifier_vortex_oaa_thinker:OnCreated()
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local radius = ability:GetSpecialValueFor("radius")

  if IsServer() then
    -- Start the sound loop
    parent:EmitSound("Hero_Ancient_Apparition.IceVortex")
    -- Particle
    self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_ice_vortex.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
    ParticleManager:SetParticleControl(self.nfx, 0, GetGroundPosition(parent:GetAbsOrigin(), parent) + Vector(0,0,100))
    ParticleManager:SetParticleControl(self.nfx, 5, Vector(radius, radius, radius))
  end
end

function modifier_vortex_oaa_thinker:OnDestroy()
  if not IsServer() then
    return
  end
  -- Remove the particle
  if self.nfx then
    ParticleManager:DestroyParticle(self.nfx, false)
    ParticleManager:ReleaseParticleIndex(self.nfx)
  end
  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    -- Stop sound loop
    parent:StopSound("Hero_Ancient_Apparition.IceVortex")
    -- Kill the thinker entity if it exists
    parent:ForceKillOAA(false)
  end
end

function modifier_vortex_oaa_thinker:IsAura()
  return true
end

function modifier_vortex_oaa_thinker:GetModifierAura()
  return "modifier_vortex_oaa_debuff"
end

function modifier_vortex_oaa_thinker:GetAuraDuration()
  return 0.5 -- Linger time
end

function modifier_vortex_oaa_thinker:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_vortex_oaa_thinker:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_vortex_oaa_thinker:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_vortex_oaa_thinker:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_vortex_oaa_thinker:IsAuraActiveOnDeath()
  return false
end

-----------------------------------------------------------------------------------------------------------------------------------------------------

modifier_vortex_oaa_debuff = class({})

function modifier_vortex_oaa_debuff:IsHidden()
  return false
end

function modifier_vortex_oaa_debuff:IsDebuff()
  return true
end

function modifier_vortex_oaa_debuff:IsPurgable()
  return false
end

function modifier_vortex_oaa_debuff:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.ms_slow = ability:GetSpecialValueFor("ms_slow") --parent:GetValueChangedBySlowResistance(ms_slow)
    self.as_slow = ability:GetSpecialValueFor("as_slow")
  else
    self.ms_slow = -20
    self.as_slow = -40
  end
end

function modifier_vortex_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_vortex_oaa_debuff:GetModifierMoveSpeedBonus_Percentage()
  return 0 - math.abs(self.ms_slow)
end

function modifier_vortex_oaa_debuff:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.as_slow)
end

function modifier_vortex_oaa_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end
