item_cave_rune_hasted_doubledamage = class(ItemBaseClass)


function item_cave_rune_hasted_doubledamage:OnSpellStart()
	local caster = self:Getcaster()

	caster:AddNewModifier(caster, self, "modifier_rune_haste_doubledamage", {duration = self:GetSpecialValueFor("duration")})

	caster:EmitSound( "sounds/items/rune_haste.vsnd" )

	caster:RemoveItem(self())
end
