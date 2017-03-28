LinkLuaModifier( "modifier_bottle_regeneration", "items/bottle.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_bottle = class({})

function item_bottle:OnSpellStart()
	local restore_time = self:GetSpecialValueFor( "restore_time" )

	self:GetCaster():EmitSoundParams( "Bottle.Drink", 0, 0.5, 0 )

	self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_bottle_regeneration", { duration = restore_time } )

	self:SetCurrentCharges( self:GetCurrentCharges() - 1 )
end

--------------------------------------------------------------------------------

modifier_bottle_regeneration = class({})

function modifier_bottle_regeneration:OnCreated()
	self.health_restore = self:GetAbility():GetSpecialValueFor( "health_restore" )
	self.mana_restore = self:GetAbility():GetSpecialValueFor( "mana_restore" )
	self.restore_time = self:GetAbility():GetSpecialValueFor( "restore_time" )
end

function modifier_bottle_regeneration:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}
	return funcs
end

function modifier_bottle_regeneration:GetModifierConstantHealthRegen()
	return self.health_restore / self.restore_time
end

function modifier_bottle_regeneration:GetModifierConstantManaRegen()
	return self.mana_restore / self.restore_time
end

function modifier_bottle_regeneration:GetEffectName()
	return "particles/items_fx/bottle.vpcf"
end

function modifier_bottle_regeneration:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

--------------------------------------------------------------------------------
