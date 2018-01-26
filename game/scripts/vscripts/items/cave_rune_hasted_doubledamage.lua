item_cave_rune_hasted_doubledamage = class(ItemBaseClass)


function item_cave_rune_hasted_doubledamage:OnSpellStart()
	local caster = self:Getcaster()

	caster:AddNewModifier(caster, self, "modifier_rune_haste_doubledamage", {duration = self:GetSpecialValueFor("duration")})

	caster:EmitSound( "sounds/items/rune_haste.vsnd" )

	if self:GetCurrentCharges() - 1 <= 0 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(self:GetCurrentCharges() - 1)
	end
end
