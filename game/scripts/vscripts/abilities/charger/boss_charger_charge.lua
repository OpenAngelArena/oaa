
require('libraries/timers')

LinkLuaModifier("modifier_boss_charger_charge", "abilities/charger/boss_charger_charge.lua", LUA_MODIFIER_MOTION_BOTH) --- PARTH WEVY IMPARTAYT
LinkLuaModifier("modifier_boss_charger_pillar_debuff", "abilities/charger/modifier_boss_charger_pillar_debuff.lua", LUA_MODIFIER_MOTION_NONE) --- PARTH WEVY IMPARTAYT

boss_charger_charge = class({})

function boss_charger_charge:OnSpellStart()
end

function boss_charger_charge:OnChannelFinish(interupted)
  if interupted then
    return
  end
  local caster = self:GetCaster()

  caster:AddNewModifier(caster, self, "modifier_boss_charger_charge", {
    duration = self:GetSpecialValueFor( "charge_duration" )
  })
end

modifier_boss_charger_charge = class({})

function modifier_boss_charger_charge:IsHidden()
  return false
end

function modifier_boss_charger_charge:OnIntervalThink()
  if not IsServer() then
    return
  end

  local caster = self:GetCaster()

  if self.distance_traveled >= self.max_distance then
    return self:EndCharge()
  end

  local origin = caster:GetAbsOrigin()
  caster:SetAbsOrigin(origin + (self.direction * self.speed))
  self.distance_traveled = self.distance_traveled + (self.direction * self.speed):Length2D()

  -- FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, creepSearchRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
  local towers = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 50, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

  function isTower (tower)
    return tower:GetUnitName() == "npc_dota_boss_charger_pillar"
  end

  towers = filter(isTower, iter(towers))

  if towers:length() > 0 then
    -- we hit a tower!
    local tower = towers:head()
    tower:Kill(self:GetAbility(), caster)

    caster:AddNewModifier(caster, self:GetAbility(), "modifier_boss_charger_pillar_debuff", {
      duration = self.debuff_duration
    })
    return self:EndCharge()
  end
end

function modifier_boss_charger_charge:EndCharge()
  local caster = self:GetCaster()

  caster:InterruptMotionControllers(true)
  FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
  self:StartIntervalThink(-1)
  self:Destroy()
  return 0
end

function modifier_boss_charger_charge:OnCreated(keys)
  if not IsServer() then
    return
  end

  local ability = self:GetAbility()
  local cursorPosition = ability:GetCursorPosition()
  local caster = self:GetCaster()
  local origin = caster:GetAbsOrigin()
  local direction = (cursorPosition - origin):Normalized()

  direction.z = 0

  self.direction = direction
  self.speed = ability:GetSpecialValueFor( "speed" )
  self.distance_traveled = 0
  self.max_distance = ability:GetSpecialValueFor( "distance" )
  self.debuff_duration = ability:GetSpecialValueFor( "debuff_duration" )

  print('starting charge')

  self:StartIntervalThink(0.01)
end
