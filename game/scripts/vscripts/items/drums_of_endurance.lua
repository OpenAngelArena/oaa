LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa_swiftness_aura", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa_swiftness_aura_effect", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_drums_of_endurance_oaa_active", "items/drums_of_endurance.lua", LUA_MODIFIER_MOTION_NONE )

item_drums_of_endurance_oaa = class(ItemBaseClass)

function item_drums_of_endurance_oaa:GetIntrinsicModifierName()
	return "modifier_intrinsic_multiplexer"
end

function item_drums_of_endurance_oaa:GetIntrinsicModifierNames()
	return {
  		"modifier_item_ancient_janggo_of_endurance_oaa",
  		"modifier_item_drums_of_endurance_oaa"
    }
end
-----------------------------------------------------------------------------------------------------------------------------
-- Upgrades

item_drums_of_endurance_2 = class(item_drums_of_endurance_oaa)
item_drums_of_endurance_3 = class(item_drums_of_endurance_oaa)
item_drums_of_endurance_4 = class(item_drums_of_endurance_oaa)

------------------------------------------------------------------------------------------------------------------------------
--On Casting/Activating Item

function item_drums_of_endurance_oaa:OnSpellStart()
	--Initializing needed variables
	local ability = self
	local caster = ability:GetCaster()
	local casterTeam = caster:GetTeamNumber()
	local drums = self.GetAbility()
  local needsSetCharges = true

  --if ability:GetSpecialValueFor("ItemRequiresCharges") == 1 then
      --needsSetCharges = true
    --else
      --needsSetCharges = false
  --end

  --local oldcharges = ability:GetCurrentCharges()
  --local newcharges = oldcharges
  --if needsSetCharges then
    --newcharges = oldcharges - 1
  --end
  --ability:SetCurrentCharges(newcharges)

	local units = FindUnitsInRadius(
					casterTeam,
					caster:GetAbsOrigin(),
					nil,
					ability:GetSpecialValueFor("radius"),
					DOTA_UNIT_TARGET_TEAM_FRIENDLY,
					DOTA_UNIT_TARGET_HERO,
					DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
					FIND_CLOSEST,
					false
					)

	local duration = ability:GetSpecialValueFor("duration")

	local modifier_active = "modifier_item_drums_of_endurance_active"

	--Applying Active Effect to allied units
	for _,unit in pairs(units) do
		unit:AddNewModifier(caster, ability, modifier_active, {duration = duration})
	end
end

------------------------------------------------------------------------------------------------------------------------------
--Active Modifier

modifier_item_drums_of_endurance_oaa_active = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa_active:OnCreated()
	-- Ability specials
	self.active_attack_speed = self:GetAbility():GetSpecialValueFor("bonus_attack_speed_pct")
	self.active_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_movement_speed_pct")
end

function modifier_item_drums_of_endurance_oaa_active:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_MOVEMENT_SPEED_BONUS,
		MODIFIER_PROPERTY_ATTACK_SPEED_BONUS}
	return decFuncs
end

function modifier_item_drums_of_endurance_oaa_active:GetModifierMovementSpeedBonus()
	return self.active_movement_speed
end

function modifier_item_drums_of_endurance_oaa_active:GetModifierAttackSpeedBonus()
	return self.active_attack_speed
end

------------------------------------------------------------------------------------------------------------------------------
--Aura

modifier_item_drums_of_endurance_oaa_swiftness_aura = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa_swiftness_aura:OnCreated()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:IsDebuff()
	return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:AllowIllusionDuplicate()
	return true
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:IsHidden()
	return true
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:IsPurgable()
	return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:GetAuraRadius()
	return self.radius
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:GetModifierAura()
	return "modifier_item_drums_of_endurance_oaa_swiftness_aura_effect"
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura:IsAura()
	return true
end

------------------------------------------------------------------------------------------------------------------------------
-- Aura Modifier Effect

modifier_item_drums_of_endurance_oaa_swiftness_aura_effect = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:OnCreated()
	self.aura_movement_speed = self:GetAbility():GetSpecialValueFor("bonus_aura_movement_speed")
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsHidden()
	return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsPurgable()
	return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:IsDebuff()
	return false
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_MOVEMENT_SPEED_BONUS,
    }
	return decFuncs
end

function modifier_item_drums_of_endurance_oaa_swiftness_aura_effect:GetModifierMovementSpeedBonus()
	return self.aura_movement_speed
end

------------------------------------------------------------------------------------------------------------------------------
-- Stats modifier

modifier_item_drums_of_endurance_oaa = class(ModifierBaseClass)

function modifier_item_drums_of_endurance_oaa:Setup(created)
  local ability = self:GetAbility()
 	local caster = self:GetCaster()
 	-- Needs charges only in tier 1
 	local needsSetCharges = false

  --if ability:GetSpecialValueFor("ItemRequiresCharges") == 1 then
    --self.charges = ability:GetCurrentCharges()
	  --needsSetCharges = true
  --else
	  --needsSetCharges = false
	--end

	--if needsSetCharges then
  	--ability:SetCurrentCharges(self.charges)
  --end
end

function modifier_item_drums_of_endurance_oaa:OnCreated()
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_int")
	self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_str")
	self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agi")
	self.bonus_damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
	self.bonus_mana_regeneration = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")

	if IsServer() then
		self:Setup()
		--If no previous drums aura then add the aura effect
		if not self:GetCaster():HasModifier("modifier_item_drums_of_endurance_oaa_swiftness_aura") then
			self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_item_drums_of_endurance_oaa_swiftness_aura", {})
		end
	end
end

function modifier_item_drums_of_endurance_oaa:OnRefreshed()
	if IsServer() then
		self:Setup()
	end
end

function modifier_item_drums_of_endurance_oaa:IsHidden()
	return true
end

function modifier_item_drums_of_endurance_oaa:IsPurgable()
	return false
end

function modifier_item_drums_of_endurance_oaa:IsDebuff()
	return false
end

function modifier_item_drums_of_endurance_oaa:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_drums_of_endurance_oaa:DeclareFunctions()
	local decFuncs = {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_MANA_REGENERATION}
	return decFuncs
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_drums_of_endurance_oaa:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_drums_of_endurance_oaa:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_drums_of_endurance_oaa:GetModifierManaRegeneration()
	return self.bonus_mana_regeneration
end

function modifier_item_drums_of_endurance_oaa:OnDestroy()
	if IsServer() then
		if not self:GetCaster():HasModifier("modifier_item_drums_of_endurance_oaa") then
			self:GetCaster():RemoveModifierByName("modifier_item_drums_of_endurance_oaa_swiftness_aura")
		end
	end
end
