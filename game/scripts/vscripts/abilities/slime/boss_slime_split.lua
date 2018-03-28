boss_slime_split = class(AbilityBaseClass)

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

function boss_slime_split:SpawnSlime(position, hpPct)
	local slime = CreateUnitByName("npc_dota_boss_slime", position, true, self:GetCaster(), self:GetCaster(), self:GetCaster():GetTeam() )
	local newHP = slime:GetMaxHealth() * hpPct / 100
	slime:SetBaseMaxHealth( newHP )
	slime:SetMaxHealth( newHP )
	slime:SetHealth( newHP )
	slime:FindAbilityByName("boss_slime_split"):Destroy()
end

modifier_boss_slime_split_passive = class(ModifierBaseClass)
LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/slime/boss_slime_split", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_slime_split_passive:DeclareFunctions()
	return {}
end

function modifier_boss_slime_split_passive:OnDeath(params)
	if params.unit == self:GetParent() then
		local position = params.unit:GetAbsOrigin()
		CreateModifierThinker(self:GetCaster(), params.unit:FindAbilityByName("boss_slime_shake"), "modifier_boss_slime_shake_thinker", {duration = 5}, position, self:GetCaster():GetTeam(), false)
		for i = 1, self:GetSpecialValueFor("slime_split_count") do
			self:GetAbility():SpawnSlime(position + RandomVector(225), self:GetAbility():GetSpecialValueFor("slime_hp_pct"))
		end
	end
end