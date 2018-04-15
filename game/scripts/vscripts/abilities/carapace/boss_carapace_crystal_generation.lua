boss_carapace_crystal_generation = class(AbilityBaseClass)

function boss_carapace_crystal_generation:GetIntrinsicModifierName()
	return "modifier_boss_carapace_crystal_generation"
end

modifier_boss_carapace_crystal_generation = class({})
LinkLuaModifier("modifier_boss_carapace_crystal_generation", "abilities/carapace/boss_carapace_crystal_generation", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_carapace_crystal_generation:OnCreated()
	self.dmg_threshold = self:GetAbility():GetSpecialValueFor("health_threshold")
	self.start_crystals = self:GetAbility():GetSpecialValueFor("starting_crystals")
	if IsServer() then
		for i = 1, self.start_crystals do
			self:GetAbility():CreateCrystal(health)
		end
	end
end