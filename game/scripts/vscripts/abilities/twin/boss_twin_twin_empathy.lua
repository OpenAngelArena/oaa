LinkLuaModifier("modifier_boss_twin_twin_empathy_buff", "abilities/twin/modifier_boss_twin_twin_empathy.lua", LUA_MODIFIER_MOTION_NONE)

boss_twin_twin_empathy = class({})

function boss_twin_twin_empathy:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end
