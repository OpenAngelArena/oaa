function urn_of_sorcery_on_ability_executed(keys)
	if keys.caster:GetTeam() ~= keys.unit:GetTeam() and keys.caster:CanEntityBeSeenByMyTeam(keys.unit) then
		local oldest_urn_of_sorcery = nil
	
		for i=0, 5, 1 do
			local current_item = keys.caster:GetItemInSlot(i)	
			if current_item ~= nil and string.find(current_item:GetName(), "urn_of_sorcery") and current_item:GetCurrentCharges() < keys.MaxCharges then
				if oldest_urn_of_sorcery == nil or current_item:GetEntityIndex() < oldest_urn_of_sorcery:GetEntityIndex() then
					oldest_urn_of_sorcery = current_item
				end
			end
		end
		if oldest_urn_of_sorcery ~= nil then
			oldest_urn_of_sorcery:SetCurrentCharges(oldest_urn_of_sorcery:GetCurrentCharges() + 1)
		end	
	end
end

function urn_of_sorcery_on_damage_taken(keys)
	if keys.Damage > 0 and (keys.attacker:IsTower() or keys.attacker:IsHero()) then
		keys.unit:RemoveModifierByName(keys.ModifierName)
	end
end