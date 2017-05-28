LinkLuaModifier("modifier_reactive_immunity", "items/reflex/reactive_invincibility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

item_reactive = class({})

function item_reactive:GetIntrinsicModifierName()
  return "modifier_generic_bonus"
end

function item_reactive:OnSpellStart()
  local duration = self:GetSpecialValueFor("reactive_duration")
  local caster = self:GetCaster()

  caster:AddNewModifier(caster, self, "modifier_reactive_immunity", {duration = duration})
end

------------------------------------------------------------------------

modifier_reactive_immunity = class({})

function modifier_reactive_immunity:GetEffectName()
  return "particles/items_fx/black_king_bar_avatar.vpcf"
end

function modifier_reactive_immunity:GetTexture()
  return self:GetAbility():GetAbilityTextureName()
end

function modifier_reactive_immunity:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ABSORB_SPELL
  }
end

function modifier_reactive_immunity:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_reactive_immunity:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_reactive_immunity:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_reactive_immunity:GetAbsorbSpell()
  return 1
end
