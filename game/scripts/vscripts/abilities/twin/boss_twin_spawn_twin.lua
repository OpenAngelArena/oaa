LinkLuaModifier("modifier_boss_twin_twin_empathy", "abilities/twin/modifier_boss_twin_twin_empathy.lua", LUA_MODIFIER_MOTION_NONE)

boss_twin_spawn_twin = class({})

function boss_twin_spawn_twin:OnSpellStart()
	local cursorPosition = self:GetCursorPosition()
	local caster = self:GetCaster()

	local twin = CreateUnitByName("npc_dota_boss_twin_dumb", cursorPosition, true, caster, caster:GetOwner(), caster:GetTeam())

	 --if caster.GetPlayerID then
	twin:SetControllableByPlayer(caster:GetPlayerID(), false)
	 --end
	twin:SetOwner(caster)

	twin:AddNewModifier(caster, self, "modifier_boss_twin_twin_empathy", { local heal_timer = GetSpecialValueFor("heal_timer")})

	return true
end

function boss_twin_twin_empathy:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_POINT 
end

