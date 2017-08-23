LinkLuaModifier('modifier_offside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)

modifier_onside_buff = class(ModifierBaseClass)
modifier_offside_buff = class(ModifierBaseClass)

function modifier_offside_buff:IsHidden()
  return false
end

--------------------------------------------------------------------
--aura
function modifier_onside_buff:IsAura()
  return true
end

function modifier_onside_buff:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_onside_buff:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_onside_buff:GetAuraRadius()
  return 2500
end

function modifier_onside_buff:GetModifierAura()
  return "modifier_offside_buff"
end
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