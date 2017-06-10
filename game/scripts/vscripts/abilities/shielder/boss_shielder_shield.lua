LinkLuaModifier("modifier_boss_shielder_shielded_buff", "abilities/shielder/modifier_boss_shielder_shielded.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

boss_shielder_shield = class({})

function boss_shielder_shield:GetAbilityTextureName (brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

function boss_shielder_shield:OnSpellStart()
  local particle = ParticleManager:CreateParticle("TheWarpiestOfShields.vpcf", PATTACH_ABSORIGIN_FOLLOW, thisEntity)
  ParticleManager:SetParticleControl(particle, 0, thisEntity:GetAbsOrigin())
  ParticleManager:SetParticleControl(particle, 1, thisEntity:GetAbsOrigin())
end

function boss_shielder_shield:GetIntrinsicModifierName()
  return "modifier_boss_shielder_shielded_buff"
end

function boss_shielder_shield:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end
