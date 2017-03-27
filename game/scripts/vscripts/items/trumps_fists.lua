item_trumps_fists = class({})

LinkLuaModifier( "modifier_item_trumps_fists_passive", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_trumps_fists_corruption", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_trumps_fists_cold", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_trumps_fists_frostbite", "items/trumps_fists.lua", LUA_MODIFIER_MOTION_NONE )

function item_trumps_fists:GetIntrinsicModifierName()
	return "modifier_item_trumps_fists_passive"
end

--------------------------------------------------------------------------------

item_trumps_fists_2 = class({})

function item_trumps_fists_2:GetIntrinsicModifierName()
	return "modifier_item_trumps_fists_passive"
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_passive = class({})

function modifier_item_trumps_fists_passive:IsHidden()
	return true
end

function modifier_item_trumps_fists_passive:OnCreated()
	self.bonus_all_stats = self:GetAbility():GetSpecialValueFor( "bonus_all_stats" )
	self.bonus_damage = self:GetAbility():GetSpecialValueFor( "bonus_damage" )
	self.bonus_health = self:GetAbility():GetSpecialValueFor( "bonus_health" )
	self.bonus_mana = self:GetAbility():GetSpecialValueFor( "bonus_mana" )

	self.heal_prevent_duration = self:GetAbility():GetSpecialValueFor( "heal_prevent_duration" )

	self.corruption_duration = self:GetAbility():GetSpecialValueFor( "corruption_duration" )

	if IsServer() then
		if self:GetParent():GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
			self.cold_duration = self:GetAbility():GetSpecialValueFor( "cold_duration_melee" )
		elseif self:GetParent():GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
			self.cold_duration = self:GetAbility():GetSpecialValueFor( "cold_duration_ranged" )
		else
			self.cold_duration = 0
		end
	end
end

function modifier_item_trumps_fists_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
	return funcs
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Strength()
	return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Agility()
	return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all_stats
end

function modifier_item_trumps_fists_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_trumps_fists_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_trumps_fists_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_trumps_fists_passive:OnAttackLanded( kv )
	if IsServer() then
		if kv.attacker == self:GetParent() then
			kv.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_cold", { duration = self.cold_duration } )
			kv.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_corruption", { duration = self.corruption_duration } )
			kv.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_trumps_fists_frostbite", { duration = self.heal_prevent_duration } )
		end
	end
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_frostbite = class({})

function modifier_item_trumps_fists_frostbite:OnCreated()
	self.heal_prevent_percent = self:GetAbility():GetSpecialValueFor( "heal_prevent_percent" )
end

function modifier_item_trumps_fists_frostbite:IsDebuff()
	return true
end

function modifier_item_trumps_fists_frostbite:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_HEAL_RECEIVED,
	}
	return funcs
end


function modifier_item_trumps_fists_frostbite:OnHealReceived( kv )
	if IsServer() then
		if kv.unit:HasModifier("modifier_item_trumps_fists_frostbite") then
			kv.unit:SetHealth( kv.unit:GetHealth() + kv.gain * self.heal_prevent_percent / 100 )
		end
	end
end

--------------------------------------------------------------------------------

modifier_item_trumps_fists_corruption = class({})

function modifier_item_trumps_fists_corruption:OnCreated()
	self.corruption_armor = self:GetAbility():GetSpecialValueFor( "corruption_armor" )
end

function modifier_item_trumps_fists_corruption:IsDebuff()
	return true
end

function modifier_item_trumps_fists_corruption:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
	return funcs
end

function modifier_item_trumps_fists_corruption:GetModifierPhysicalArmorBonus()
	return self.corruption_armor
end

--------------------------------------------------------------------------------
modifier_item_trumps_fists_cold = class({})

function modifier_item_trumps_fists_cold:OnCreated()
	self.cold_movement_speed = self:GetAbility():GetSpecialValueFor( "cold_movement_speed" )
	self.cold_attack_speed = self:GetAbility():GetSpecialValueFor( "cold_attack_speed" )
end

function modifier_item_trumps_fists_cold:IsDebuff()
	return true
end

function modifier_item_trumps_fists_cold:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
	return funcs
end

function modifier_item_trumps_fists_cold:GetModifierMoveSpeedBonus_Percentage()
	return self.cold_movement_speed
end

function modifier_item_trumps_fists_cold:GetModifierAttackSpeedBonus_Constant()
	return self.cold_attack_speed
end

--------------------------------------------------------------------------------
