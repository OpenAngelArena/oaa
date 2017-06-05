
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_shield = nil

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  thisEntity:FindAbilityByName("boss_shielder_shield")

  ABILITY_shield = thisEntity:FindAbilityByName("boss_shielder_shield")

local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
ParticleManager:SetParticleControl(particle, 0, self:GetAbsOrigin())
ParticleManager:SetParticleControl(particle, 1, self:GetAbsOrigin())
ParticleManager:SetParticleControl(particle, 2, self:GetAbsOrigin())
ParticleManager:SetParticleControl(particle, 4, self:GetAbsOrigin())
ParticleManager:SetParticleControl(particle, 5, Vector(nil,0,0))

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_shield, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_shielder_shield"
  })
end
