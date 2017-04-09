LinkLuaModifier( "modifier_bottle_regeneration", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_infinite_bottle = class({})

function item_infinite_bottle:OnSpellStart()
	local restore_time = self:GetSpecialValueFor( "restore_time" )

	EmitSoundOn( "Bottle.Drink", self:GetCaster() )

	self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_bottle_regeneration", { duration = restore_time } )

  if self:GetCurrentCharges() - 1 <= 0 then
    self:GetCaster():RemoveItem(self)
  else
    self:SetCurrentCharges( self:GetCurrentCharges() - 1 )
  end
end

--------------------------------------------------------------------------------
