LinkLuaModifier( "modifier_item_shivas_guard_thinker", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_shivas_cuirass", "items/shivas_cuirass.lua",LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_shivas_cuirass_aura", "items/shivas_cuirass.lua",LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_shivas_cuirass = class({})

function item_shivas_cuirass:GetIntrinsicModifierName()
	return "modifier_item_shivas_cuirass"
end

function item_shivas_cuirass:OnSpellStart()
	local hCaster = self:GetCaster()

	EmitSoundOn( "DOTA_Item.ShivasGuard.Activate", hCaster )
	CreateModifierThinker( hCaster, self, "modifier_item_shivas_guard_thinker", nil, hCaster:GetAbsOrigin(), hCaster:GetTeamNumber(), false )
end

--------------------------------------------------------------------------------

item_shivas_cuirass_2 = item_shivas_cuirass --luacheck: ignore item_shivas_cuirass_2

--------------------------------------------------------------------------------

modifier_item_shivas_cuirass = class({})

function modifier_item_shivas_cuirass:OnCreated()
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor( "bonus_intellect" )
	self.bonus_armor = self:GetAbility():GetSpecialValueFor( "bonus_armor" )
	self.bonus_attack_speed = self:GetAbility():GetSpecialValueFor( "bonus_attack_speed" )

	self.aura_radius = self:GetAbility():GetSpecialValueFor( "aura_radius" )
end

function modifier_item_shivas_cuirass:IsHidden()
	return true
end

function modifier_item_shivas_cuirass:IsAura()
	return true
end

function modifier_item_shivas_cuirass:IsPurgable()
  return false
end

function modifier_item_shivas_cuirass:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_shivas_cuirass:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_item_shivas_cuirass:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_item_shivas_cuirass:GetModifierAura()
	return "modifier_item_shivas_cuirass_aura"
end

function modifier_item_shivas_cuirass:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}
	return funcs
end

function modifier_item_shivas_cuirass:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_shivas_cuirass:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_shivas_cuirass:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

--------------------------------------------------------------------------------

modifier_item_shivas_cuirass_aura = class({})

function modifier_item_shivas_cuirass_aura:OnCreated()
	self.aura_attack_speed = self:GetAbility():GetSpecialValueFor( "aura_attack_speed" )
	self.aura_attack_speed_bonus = self:GetAbility():GetSpecialValueFor( "aura_attack_speed_bonus" )

	self.aura_positive_armor = self:GetAbility():GetSpecialValueFor( "aura_positive_armor" )
	self.aura_negative_armor = self:GetAbility():GetSpecialValueFor( "aura_negative_armor" )
end

function modifier_item_shivas_cuirass_aura:IsDebuff()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return true
	end

	return false
end

function modifier_item_shivas_cuirass_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_item_shivas_cuirass_aura:GetModifierAttackSpeedBonus_Constant()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return self.aura_attack_speed
	end

	return self.aura_attack_speed_bonus
end

function modifier_item_shivas_cuirass_aura:GetModifierPhysicalArmorBonus()
	if self:GetCaster():GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		return self.aura_negative_armor
	end

	return self.aura_positive_armor
end

--------------------------------------------------------------------------------
