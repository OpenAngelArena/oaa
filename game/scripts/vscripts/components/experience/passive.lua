
if PassiveExperience == nil then
  --Debug:EnableDebugging()
  --DebugPrint('Creating new PassiveExperience object.')
  PassiveExperience = class({})
end

function PassiveExperience:Init()
  self.moduleName = "PassiveExperience"
  -- xpm stuff
  LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_xpm_thinker", "modifiers/modifier_xpm_thinker.lua", LUA_MODIFIER_MOTION_NONE)
  --CreateModifierThinker( nil, nil, "modifier_xpm_thinker", {}, Vector( 0, 0, 0 ), DOTA_TEAM_NEUTRALS, false )
  local xpm_thinker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
  xpm_thinker:AddNewModifier(xpm_thinker, nil, "modifier_oaa_thinker", {})
  xpm_thinker:AddNewModifier(xpm_thinker, nil, "modifier_xpm_thinker", {})
end
