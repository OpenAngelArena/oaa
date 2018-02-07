-- modifier_item_devastator_desolator
LinkLuaModifier("modifier_item_devastator_corruption_armor", "modifiers/modifier_item_devastator_corruption_armor.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_devastator_desolator = class({})

function modifier_item_devastator_desolator:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
	}

	return funcs
end

function modifier_item_devastator_desolator:IsHidden()
	return true
end

function modifier_item_devastator_desolator:GetModifierBaseAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_devastator_desolator:OnAttackLanded( params )

    if IsServer() then
		if params.attacker == self:GetParent() and ( not self:GetParent():IsIllusion() ) then
			if self:GetParent():PassivesDisabled() then
				return 0
			end

			local target = params.target
			if target ~= nil and target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
				-- check the current devastator_armor_reduction and the corruption_armor check the higher
				local armor_reduction = self:GetAbility():GetSpecialValueFor( "devastator_armor_reduction" )
				local corruption_armor = self:GetAbility():GetSpecialValueFor( "corruption_armor" )
				-- if already has applied corruption
				if target:HasModifier("modifier_item_devastator_reduce_armor") then
					-- if corruption is higher than armor reduction just exit
					if armor_reduction < corruption_armor then
						return false
					end
					-- so in this case should remove corruption and applied
					target:RemoveModifierByName("modifier_item_devastator_reduce_armor");

				end

				target:AddNewModifier( target, self:GetAbility(), "modifier_item_devastator_corruption_armor", {duration = self:GetAbility():GetSpecialValueFor("corruption_duration")})
			end
		end
	end
	return 0
end
