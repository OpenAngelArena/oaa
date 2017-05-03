function CDOTABaseAbility:HasBehavior(behavior)
	return bit.band(self:GetBehavior(), behavior) == behavior
end

function AbilityHasBehaviorByName(ability_name, behaviorString)
	local AbilityBehavior = GetKeyValue(ability_name, "AbilityBehavior")
	if AbilityBehavior then
		local AbilityBehaviors = string.split(AbilityBehavior, " | ")
		return table.contains(AbilityBehaviors, behaviorString)
	end
	return false
end

function CDOTABaseAbility:PreformPrecastActions(unit)
	return PreformAbilityPrecastActions(unit or self:GetCaster(), self)
end

function CDOTABaseAbility:IsAbilityMulticastable()
	return not ability:HasBehavior(DOTA_ABILITY_BEHAVIOR_PASSIVE) and not table.contains(NOT_MULTICASTABLE_ABILITIES, self:GetAbilityName())
end

function CDOTABaseAbility:ClearFalseInnateModifiers()
	if self:GetKeyValue("HasInnateModifiers") ~= 1 then
		for _,v in ipairs(self:GetCaster():FindAllModifiers()) do
			if v:GetAbility() and v:GetAbility() == self then
				v:Destroy()
			end
		end
	end
end

function AddNewAbility(unit, ability_name, skipLinked)
	local hAbility = unit:AddAbility(ability_name)
	hAbility:ClearFalseInnateModifiers()
	local linked
	local link = LINKED_ABILITIES[ability_name]
	if link and not skipLinked then
		linked = {}
		for _,v in ipairs(link) do
			local h, _ = AddNewAbility(unit, v)
			table.insert(linked, h)
		end
	end
	return hAbility, linked
end

function CDOTABaseAbility:GetReducedCooldown()
	local biggestReduction = 0
	local unit = self:GetCaster()
	for k,v in pairs(COOLDOWN_REDUCTION_MODIFIERS) do
		if unit:HasModifier(k) then
			biggestReduction = math.max(biggestReduction, type(v) == "function" and v(unit) or v)
		end
	end
	return self:GetCooldown(math.max(self:GetLevel() - 1, 1)) * (100 - biggestReduction) * 0.01
end

function CDOTABaseAbility:AutoStartCooldown()
	self:StartCooldown(self:GetReducedCooldown())
end