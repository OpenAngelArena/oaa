LinkLuaModifier("modifier_meepo_divided_we_stand_oaa","abilities/oaa_divided_we_stand.lua",LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_meepo_divided_we_stand_oaa_bonus_buff", "abilities/oaa_divided_we_stand.lua", LUA_MODIFIER_MOTION_NONE)

meepo_divided_we_stand_oaa = class(AbilityBaseClass)

function meepo_divided_we_stand_oaa:GetIntrinsicModifierName()
  return "modifier_meepo_divided_we_stand_oaa"
end
  
------------------------------------------------------------------------------ 
modifier_meepo_divided_we_stand_oaa = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa:IsHidden()
	return true
end

function modifier_meepo_divided_we_stand_oaa:IsDebuff()
	return false
end

function modifier_meepo_divided_we_stand_oaa:IsAura()
	if self:GetParent():PassivesDisabled() then
    return false
  end
	return true
end

function modifier_meepo_divided_we_stand_oaa:GetModifierAura()
  return "modifier_meepo_divided_we_stand_oaa_bonus_buff"
end

function modifier_meepo_divided_we_stand_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function modifier_meepo_divided_we_stand_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_meepo_divided_we_stand_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end


modifier_meepo_divided_we_stand_oaa_bonus_buff = class(ModifierBaseClass)

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsHidden()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:IsDebuff()
  return false
end

function  modifier_meepo_divided_we_stand_oaa_bonus_buff:IsPurgable()
  return false
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnCreated()
        self.bonus = self:GetAbility():GetSpecialValueFor("bonus_resist_pct")
        self.armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_meepo_divided_we_stand_oaa_bonus_buff:OnRefresh()
        self.bonus = self:GetAbility():GetSpecialValueFor("bonus_resist_pct")
        self.armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
end    	

function modifier_meepo_divided_we_stand_oaa_bonus_buff:DeclareFunctions()
		local funcs = {
				MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
				MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
				}
				
				return funcs
end
function modifier_meepo_divided_we_stand_oaa_bonus_buff:GetModifierMagicalResistanceBonus()
	return self.bonus
end				

function modifier_meepo_divided_we_stand_oaa_bonus_buff:GetModifierPhysicalArmorBonus()
	return self.armor
end
---------------------------------------------------------
