
item_postactive_2a = class(ItemBaseClass)

function item_postactive_2a:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_postactive_2a:OnSpellStart()
  local caster = self:GetCaster()
  local shroud_duration = self:GetSpecialValueFor( "duration" )

  caster:AddNewModifier( caster, self, "modifier_item_glimmer_cape_fade", { duration = shroud_duration } )
  caster:EmitSound( "Item.GlimmerCape.Activate" )
end
