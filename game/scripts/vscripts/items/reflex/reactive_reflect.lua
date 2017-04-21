LinkLuaModifier( "modifier_item_reactive_reflect", "items/reflex/reactive_reflect.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_charge_replenisher", "modifiers/modifier_charge_replenisher.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_reactive_2a = class({})
item_reactive_3a = class({})

function item_reactive_2a:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_reactive_2a:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  caster:AddNewModifier( caster, self, "modifier_item_reactive_reflect", { duration = duration } )
end

function item_reactive_3a:GetIntrinsicModifierName()
  return "modifier_charge_replenisher"
end

function item_reactive_3a:OnSpellStart()
  local charges = self:GetCurrentCharges()
  if charges <= 0 then
    return false
  end

  local maxCharges = self:GetSpecialValueFor( "max_charges" )
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  self:SetCurrentCharges( charges - 1 )
  if charges == 1 then
    self:StartCooldown(self:GetCooldownTime())
  end

  local chargeReplenishIn = self:GetCooldownTime()

  caster:AddNewModifier( caster, self, "modifier_item_reactive_reflect", { duration = duration } )
end

modifier_item_reactive_reflect = class({})

function modifier_item_reactive_reflect:IsHidden()
  return false
end

function modifier_item_reactive_reflect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_REFLECT_SPELL,
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_reactive_reflect:GetModifierIncomingDamage_Percentage()
  return -100
end

function modifier_item_reactive_reflect:GetReflectSpell()
  return true
end
