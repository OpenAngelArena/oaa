LinkLuaModifier("modifier_rune_haste", LUA_MODIDIER_MOTION_NONE)
LinkLuaModifier("modifier_rune_doubledamage", LUA_MODIDIER_MOTION_NONE)

item_cave_rune_hasted_doubledamage = class(ItemBaseClass)

function item_satanic_core:GetIntrinsicModifierName()
  return "modifier_rune_haste", "modifier_rune_doubledamage"
end

function item_cave_rune_hasted_doubledamage:OnSpellStart()
	local caster = self:Getcaster()

	caster:AddNewModifier(caster, self, "modifier_rune_haste", {duration = 30.0})


	caster:AddNewModifier(caster, self, "modifier_rune_doubledamage", {duration = 30.0})

	caster:EmitSound( "DOTA_Item.BlackKingBar.Activate" )

	caster:RemoveItem(self)
	if self:GetCurrentCharges() - 1 <= 0 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(self:GetCurrentCharges() - 1)

end
