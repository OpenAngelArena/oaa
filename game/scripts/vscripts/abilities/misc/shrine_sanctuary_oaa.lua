LinkLuaModifier("modifier_shrine_oaa_aura_applier", "abilities/misc/shrine_sanctuary_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_shrine_oaa_aura_effect", "abilities/misc/shrine_sanctuary_oaa.lua", LUA_MODIFIER_MOTION_NONE)

shrine_sanctuary_oaa = class({})

function shrine_sanctuary_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor("duration")

  -- Add an aura modifier
  caster:AddNewModifier(caster, self, "modifier_shrine_oaa_aura_applier", {duration = duration})

  -- Particle
  local particle_name
  if caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
    particle_name = "particles/misc/shrines/radiant_shrine_active.vpcf"
  elseif caster:GetTeamNumber() == DOTA_TEAM_BADGUYS then
    particle_name = "particles/misc/shrines/dire_shrine_active.vpcf"
  end
  local particle = ParticleManager:CreateParticle(particle_name, PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())
  ParticleManager:ReleaseParticleIndex(particle)

  -- Sound
  caster:EmitSound("Shrine.Cast")
end

---------------------------------------------------------------------------------------------------

modifier_shrine_oaa_aura_applier = class(ModifierBaseClass)

function modifier_shrine_oaa_aura_applier:IsHidden()
  return true
end

function modifier_shrine_oaa_aura_applier:IsPurgable()
  return false
end

function modifier_shrine_oaa_aura_applier:IsAura()
  return true
end

function modifier_shrine_oaa_aura_applier:GetModifierAura()
  return "modifier_shrine_oaa_aura_effect"
end

function modifier_shrine_oaa_aura_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_shrine_oaa_aura_applier:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_shrine_oaa_aura_applier:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD
end

function modifier_shrine_oaa_aura_applier:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

---------------------------------------------------------------------------------------------------

modifier_shrine_oaa_aura_effect = class({})

function modifier_shrine_oaa_aura_effect:IsHidden()
  return false
end

function modifier_shrine_oaa_aura_effect:IsPurgable()
  return false
end

function modifier_shrine_oaa_aura_effect:OnCreated()
  self.hp_regen = 90
  self.mana_regen = 50
  self.max_hp_regen = 2
  self.max_mana_regen = 2
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("hp_heal")
    self.mana_regen = ability:GetSpecialValueFor("mp_heal")
    self.max_hp_regen = ability:GetSpecialValueFor("hp_heal_pct")
    self.max_mana_regen = ability:GetSpecialValueFor("mp_heal_pct")
  end
end

function modifier_shrine_oaa_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
  }
end

function modifier_shrine_oaa_aura_effect:GetModifierConstantHealthRegen()
  return self.hp_regen
end

function modifier_shrine_oaa_aura_effect:GetModifierHealthRegenPercentage()
  return self.max_hp_regen
end

function modifier_shrine_oaa_aura_effect:GetModifierConstantManaRegen()
  return self.mana_regen
end

function modifier_shrine_oaa_aura_effect:GetModifierTotalPercentageManaRegen()
  return self.max_mana_regen
end

--function modifier_shrine_oaa_aura_effect:GetEffectName()
  --return ""
--end
