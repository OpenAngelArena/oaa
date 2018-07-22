modifier_felfrost = class( ModifierBaseClass )

FELFROST_DURATION = 8 -- reset upon being applied

FELFROST_ARMOR_BASE = 0 -- armor loss just by having the debuff
FELFROST_ARMOR_PERSTACK = -1 -- armor loss based on stack count
FELFROST_SLOW_BASE = -10 -- slow just by having the debuff
FELFROST_SLOW_PERSTACK = -10 -- slow based on stack count

--------------------------------------------------------------------------------

function modifier_felfrost:IsHidden()
	return false
end

function modifier_felfrost:IsDebuff()
	return true
end

function modifier_felfrost:IsPurgable()
	return true
end

--------------------------------------------------------------------------------

function modifier_felfrost:GetTexture()
	return "crystal_maiden_frostbite"
end

function modifier_felfrost:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_felfrost:StatusEffectPriority()
	return 4
end

--------------------------------------------------------------------------------

function modifier_felfrost:OnCreated( event )
	self:SetDuration( FELFROST_DURATION, true )
end

--------------------------------------------------------------------------------

function modifier_felfrost:OnRefresh( event )
	self:SetDuration( FELFROST_DURATION, true )
end

--------------------------------------------------------------------------------

function modifier_felfrost:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end
--------------------------------------------------------------------------------

function modifier_felfrost:GetModifierMoveSpeedBonus_Percentage( event )
	return FELFROST_SLOW_BASE + ( FELFROST_SLOW_PERSTACK * self:GetStackCount() )
end

--------------------------------------------------------------------------------

function modifier_felfrost:GetModifierPhysicalArmorBonus( event )
	return FELFROST_ARMOR_BASE + ( FELFROST_ARMOR_PERSTACK * self:GetStackCount() )
end