-- modifier_item_devastator_desolator
LinkLuaModifier("modifier_item_devastator_corruption_armor", "modifiers/modifier_item_devastator_corruption_armor.lua", LUA_MODIFIER_MOTION_NONE)
modifier_item_devastator_desolator = class({})

function modifier_item_devastator_desolator:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE
	}

	return funcs
end

function modifier_item_devastator_desolator:IsHidden()
	return true
end

function modifier_item_devastator_desolator:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_devastator_desolator:OnAttackLanded( params )
  if IsServer() then
    if params.attacker == self:GetParent() and ( not self:GetParent():IsIllusion() ) then
      local target = params.target
      if target ~= nil and target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
        local armor_reduction = self:GetAbility():GetSpecialValueFor( "devastator_armor_reduction" )
        local corruption_armor = self:GetAbility():GetSpecialValueFor( "corruption_armor" )

        -- If the target has desolator debuff then do nothing
        if target:HasModifier("modifier_desolator_buff") then
          return
        end

        -- If the target has Devastator active debuff
        if target:HasModifier("modifier_item_devastator_reduce_armor") then
          -- If devastator_armor_reduction is higher than corruption_armor then do nothing
          if math.abs(armor_reduction) > math.abs(corruption_armor) then
            return
          end
          -- If devastator_armor_reduction is lower than corruption_armor then remove the Devastator active debuff
          target:RemoveModifierByName("modifier_item_devastator_reduce_armor")
        end

        -- Calculate duration of the debuff
        local corruption_duration = self:GetAbility():GetSpecialValueFor("corruption_duration")
        local armor_reduction_duration = target:GetValueChangedByStatusResistance(corruption_duration)
        -- Apply Devastator passive debuff
        target:AddNewModifier( target, self:GetAbility(), "modifier_item_devastator_corruption_armor", {duration = armor_reduction_duration})
      end
    end
  end
  return 0
end
