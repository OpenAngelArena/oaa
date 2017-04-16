LinkLuaModifier( "modifier_item_reactive_2b", "items/reflex/reactive_reflect.lua", LUA_MODIFIER_MOTION_NONE )

item_reactive_2b = class({})

function item_reactive_2b:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  caster:AddNewModifier( caster, self, "modifier_item_reactive_2b", { duration = duration } )
end

modifier_item_reactive_2b = class({})

function modifier_item_reactive_2b:IsHidden()
  return false
end

function modifier_item_reactive_2b:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_AVOID_SPELL
  }
end

function modifier_item_reactive_2b:GetReflectSpell()
  return true
end

function modifier_item_reactive_2b:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true
  }
end
