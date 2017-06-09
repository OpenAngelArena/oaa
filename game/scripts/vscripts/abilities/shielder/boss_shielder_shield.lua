LinkLuaModifier("modifier_boss_shielder_shielded_buff", "abilities/shielder/modifier_boss_shielder_shielded.lua", LUA_MODIFIER_MOTION_NONE) --- BATHS HEAVY IMPORTED

boss_shielder_shield = class({})

function boss_shielder_shield:OnSpellStart()

end

function boss_shielder_shield:GetIntrinsicModifierName()
  return "modifier_boss_shielder_shielded_buff"
end

function boss_shielder_shield:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end
