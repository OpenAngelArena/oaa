function ModifyStacks(ability, caster, unit, modifier, stack_amount, refresh)
	if stack_amount > 0 then
		return AddStacks(ability, caster, unit, modifier, stack_amount, refresh)
	elseif stack_amount < 0 then
		return RemoveStacks(ability, unit, modifier, -stack_amount)
	end
end

function AddStacks(ability, caster, unit, modifier, stack_amount, refresh)
	if unit:HasModifier(modifier) then
		if refresh then
			ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		end
		unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) + stack_amount)
	else
		ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		unit:SetModifierStackCount(modifier, ability, stack_amount)
	end
	return unit:FindModifierByNameAndCaster(modifier, caster)
end

function RemoveStacks(ability, unit, modifier, stack_amount)
	if unit:HasModifier(modifier) then
		if unit:GetModifierStackCount(modifier, ability) > stack_amount then
			unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) - stack_amount)
		else
			unit:RemoveModifierByName(modifier)
		end
	end
end

function ModifyStacksLua(ability, caster, unit, modifier, stack_amount, refresh, modifierTable)
	if stack_amount > 0 then
		AddStacksLua(ability, caster, unit, modifier, stack_amount, refresh, modifierTable)
	elseif stack_amount < 0 then
		RemoveStacks(ability, unit, modifier, stack_amount)
	end
end

function AddStacksLua(ability, caster, unit, modifier, stack_amount, refresh, data)
	local modifierTable = data or {}
	if unit:HasModifier(modifier) then
		if refresh then
			unit:AddNewModifier(caster, ability, modifier, modifierTable)
		end
		unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) + stack_amount)
	else
		unit:AddNewModifier(caster, ability, modifier, modifierTable)
		unit:SetModifierStackCount(modifier, ability, stack_amount)
	end
end

function RemoveDeathPreventingModifiers(unit)
	for _,v in ipairs(MODIFIERS_DEATH_PREVENTING) do
		unit:RemoveModifierByName(v)
	end
end

function CDOTA_BaseNPC:PurgeTruesightModifiers()
	for _,v in ipairs(MODIFIERS_TRUESIGHT) do
		unit:RemoveModifierByName(v)
	end
end