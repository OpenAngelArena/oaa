modifier_onside_buff = class(ModifierBaseClass)

--------------------------------------------------------------------
--damage reduction
function modifier_onside_buff:DeclareFunctions()
	return {
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  ,
	MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS ,
	}
end

function modifier_onside_buff:IsDebuff()
	return false
end

function modifier_onside_buff:GetTexture()
	return "custom/modifier_onside"
end

function modifier_onside_buff:GetModifierPhysicalArmorBonus ()
	local stackCount = self:GetElapsedTime()
	if stackCount >= 10 then
		return 10--(0.1 * (stackCount - 10)^2)) -- (multiplier * (stackcount - seconds till active (equal to stackCount >= number)))
	else
		return 5
	end
end
--[[
function modifier_onside:GetModifierMagicalResistanceBonus ()
	local stackCount = self:GetElapsedTime()
	if stackCount >=10 then
		return (0)
	end
end

]]
