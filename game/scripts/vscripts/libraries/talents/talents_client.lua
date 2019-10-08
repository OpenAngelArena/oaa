function MergeTables( t1, t2 )
    for name,info in pairs(t2) do
		if type(info) == "table"  and type(t1[name]) == "table" then
			MergeTables(t1[name], info)
		else
			t1[name] = info
		end
	end
end

AbilityKV = LoadKeyValues("scripts/npc/npc_abilities_custom.txt")
MergeTables(AbilityKV, LoadKeyValues("scripts/npc/npc_abilities_override.txt"))

function C_DOTA_BaseNPC:HasTalent(talentName)
	local data = CustomNetTables:GetTableValue("talents", tostring(self:entindex())) or {}
	if data[talentName] then
		return true
	end
	return false
end

function C_DOTA_BaseNPC:FindTalentValue(talentName, valname)
	local value = valname or "value"
	if self:HasTalent(talentName) and AbilityKV[talentName] then
		local specialVal = AbilityKV[talentName]["AbilitySpecial"]
		for l,m in pairs(specialVal) do
			if m[value] then
				return m[value]
			end
		end
	end
	return 0
end

function C_DOTABaseAbility:GetTalentSpecialValueFor(value)
	local base = self:GetSpecialValueFor(value)
	local talentName
	local kv = AbilityKV[self:GetName()]["AbilitySpecial"]
	local valname = "value"
	local multiply = false
	for k,v in pairs(kv) do -- trawl through keyvalues
		if v[value] then
			talentName = v["LinkedSpecialBonus"]
			if v["LinkedSpecialBonusField"] then valname = v["LinkedSpecialBonusField"] end
			if v["LinkedSpecialBonusOperation"] and v["LinkedSpecialBonusOperation"] == "SPECIAL_BONUS_MULTIPLY" then multiply = true end
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