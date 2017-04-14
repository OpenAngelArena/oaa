LinkLuaModifier( "modifier_item_glimmer_cape_fade", LUA_MODIFIER_MOTION_NONE )

item_postactive_2a = class({})

function item_postactive_2a:ResetToggleOnRespawn()
  return true
end

function item_postactive_2a:OnToggle(keys)
  local caster = self:GetCaster()
  local shroud_duration = self:GetSpecialValueFor( "duration" )

  caster:AddNewModifier( caster, self, "modifier_item_glimmer_cape_fade", { duration = shroud_duration } )
  EmitSoundOn( "Item.GlimmerCape.Activate", caster )

  -- important else you can use while on CD every other time
  if self:GetToggleState() then
    self:ToggleAbility()
  end

  self:StartCooldown(self:GetCooldownTime())

  return false
end
