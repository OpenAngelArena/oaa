LinkLuaModifier( "modifier_item_reactive_2a", "items/reflex/reactive_reflect.lua", LUA_MODIFIER_MOTION_NONE )

item_reactive_2a = class({})

function item_reactive_2a:OnSpellStart()
  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  caster:AddNewModifier( caster, self, "modifier_item_reactive_2a", { duration = duration } )
end

modifier_item_reactive_2a = class({})

function modifier_item_reactive_2a:IsHidden()
  return false
end

function modifier_item_reactive_2a:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_REFLECT_SPELL
  }
end

function modifier_item_reactive_2a:GetReflectSpell()
  return true
end

function modifier_item_reactive_2a:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true
  }
end
