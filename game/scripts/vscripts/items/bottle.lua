LinkLuaModifier("modifier_bottle_regeneration", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_infinite_bottle = class(ItemBaseClass)

function item_infinite_bottle:OnSpellStart()
  local restore_time = self:GetSpecialValueFor("restore_time")
  local caster = self:GetCaster()

  -- TODO: This needs testing if executing on Clients only fixed the 'ghost bottle' issue
  EmitSoundOn("Bottle.Drink", caster)

  caster:AddNewModifier(caster, self, "modifier_bottle_regeneration", { duration = restore_time })

  if self:GetCurrentCharges() - 1 <= 0 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(self:GetCurrentCharges() - 1)
  end
end

function item_infinite_bottle:GetAbilityTextureName()
  return "item_bottle"
end

--------------------------------------------------------------------------------
