
LinkLuaModifier("modifier_tinkerer_laser_oaa_debuff", "abilities/tinkerer/tinkerer_laser.lua", LUA_MODIFIER_MOTION_NONE)

local function ApplyLaser(source, attach_source, target, attach_target)
  local particle_name = "particles/econ/items/tinker/tinker_ti10_immortal_laser/tinker_ti10_immortal_laser.vpcf" --"particles/units/heroes/hero_tinker/tinker_laser.vpcf"
  local part = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, target)
  if source:ScriptLookupAttachment(attach_source) ~= 0 then
    ParticleManager:SetParticleControlEnt(part, 9, source, PATTACH_POINT_FOLLOW, attach_source, source:GetAbsOrigin(), true)
  else
    ParticleManager:SetParticleControl(part, 9, source:GetAbsOrigin())
  end
  if target:ScriptLookupAttachment(attach_target) ~= 0 then
    ParticleManager:SetParticleControlEnt(part, 1, target, PATTACH_POINT_FOLLOW, attach_target, target:GetAbsOrigin(), true)
  else
    ParticleManager:SetParticleControl(part, 1, target:GetAbsOrigin())
  end
  ParticleManager:ReleaseParticleIndex(part)
end

tinkerer_laser_oaa = class({})

function tinkerer_laser_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() or self:IsStolen() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
  end
end

-- function tinkerer_laser_oaa:OnAbilityPhaseStart()
  -- if not IsServer() then
    -- return
  -- end

  -- local caster = self:GetCaster()

  -- -- Sound during casting
  -- caster:EmitSound("Hero_Tinker.LaserAnim")

  -- return true
-- end

-- function tinkerer_laser_oaa:OnAbilityPhaseInterrupted()
  -- if not IsServer() then
    -- return
  -- end

  -- -- Interrupt casting sound
  -- self:GetCaster():StopSound("Hero_Tinker.LaserAnim")
-- end

function tinkerer_laser_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  -- Don't do anything if target has Linken's effect or it's spell-immune
  if target:TriggerSpellAbsorb(self) or target:IsMagicImmune() then
    return
  end

  local target_loc = target:GetAbsOrigin()

  -- Visual effect
  ApplyLaser(caster, "attach_attack2", target, "attach_hitloc")

  -- Cast Sound
  caster:EmitSound("Hero_Tinker.Laser")

  local duration_hero = self:GetSpecialValueFor("duration_hero")
  local duration_creep = self:GetSpecialValueFor("duration_creep")
  local base_damage = self:GetSpecialValueFor("base_damage")
  local current_hp_pct = self:GetSpecialValueFor("current_hp_damage_pct")
  local radius = self:GetSpecialValueFor("radius")

  local enemies = FindUnitsInRadius(
    caster:GetTeamNumber(),
    target_loc,
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  -- Damage table
  local damage_table = {
    attacker = caster,
    ability = self,
    damage_type = self:GetAbilityDamageType(),
  }

  -- Damage enemies
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      local duration = duration_hero
      if enemy:IsCreep() then
        duration = duration_creep
      end
      -- Apply debuff
      enemy:AddNewModifier(caster, self, "modifier_tinkerer_laser_oaa_debuff", {duration = duration})

      -- Actual damage
      damage_table.victim = enemy
      damage_table.damage = base_damage + (enemy:GetHealth() * current_hp_pct / 100)
      ApplyDamage(damage_table)
    end
  end

  -- Impact Sound
  if target then
    target:EmitSound("Hero_Tinker.LaserImpact")
  end
end

---------------------------------------------------------------------------------------------------

modifier_tinkerer_laser_oaa_debuff = class({})

function modifier_tinkerer_laser_oaa_debuff:IsHidden()
  return false
end

function modifier_tinkerer_laser_oaa_debuff:IsDebuff()
  return true
end

function modifier_tinkerer_laser_oaa_debuff:IsPurgable()
  return true
end

function modifier_tinkerer_laser_oaa_debuff:OnCreated()
  self.miss_rate = self:GetAbility():GetSpecialValueFor("miss_rate")
end

function modifier_tinkerer_laser_oaa_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
  }
end

function modifier_tinkerer_laser_oaa_debuff:GetModifierMiss_Percentage()
  return self.miss_rate or self:GetAbility():GetSpecialValueFor("miss_rate")
end
