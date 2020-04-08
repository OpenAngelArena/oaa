function CDOTA_BaseNPC:HasTalent(talentName)
	return (self:HasAbility(talentName) and self:FindAbilityByName(talentName):GetLevel() > 0)
end

function CDOTABaseAbility:GetTalentSpecialValueFor(value)
	local base = self:GetSpecialValueFor(value)
	local talentName
	local valname = "value"
	local multiply = false
	local kv = self:GetAbilityKeyValues()
	for k,v in pairs(kv) do -- trawl through keyvalues
		if k == "AbilitySpecial" then
			for l,m in pairs(v) do
				if m[value] then
					talentName = m["LinkedSpecialBonus"]
					if m["LinkedSpecialBonusField"] then valname = m["LinkedSpecialBonusField"] end
					if m["LinkedSpecialBonusOperation"] and m["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
				end
			end
		end
	end
	if talentName and self:GetCaster():HasTalent(talentName) then
		if multiply then
			base = base * self:GetCaster():FindTalentValue(talentName, valname)
		else
			base = base + self:GetCaster():FindTalentValue(talentName, valname)
		end
	end
	return base
end

function CDOTA_Modifier_Lua:GetTalentSpecialValueFor(value)
	return self:GetAbility():GetTalentSpecialValueFor(value)
end

function CDOTA_BaseNPC:FindTalentValue(talentName, value)
	if self:HasAbility(talentName) then
		return self:FindAbilityByName(talentName):GetSpecialValueFor(value or "value")
	end
	return 0
end
