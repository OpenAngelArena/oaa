LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_slime_split = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

------------------------------------------------------------------------------------

modifier_boss_slime_split_passive = class(ModifierBaseClass)

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:DeclareFunctions()
	local funcs =
	{
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_MODEL_SCALE
	}

	return funcs
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetModifierModelScale()
	return 2.0
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:OnDeath()
	if IsServer() then
		local caster = self:GetParent()

		local unitName = caster:GetUnitName()

		local function CreateClone(origin)
			local clone = CreateUnitByName(unitName, origin, true, nil, nil, caster:GetTeamNumber())
			clone:RemoveAbility("boss_slime_split")
		end

		CreateClone(caster:GetAbsOrigin() + Vector(100,0,0))
		CreateClone(caster:GetAbsOrigin() + Vector(-100,0,0))

		UTIL_Remove(caster)
	end
end