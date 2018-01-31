LinkLuaModifier( "modifier_item_reactive_reflect", "items/reflex/reactive_reflect.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_charge_replenisher", "modifiers/modifier_charge_replenisher.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

item_reflection_shard_1 = class(ItemBaseClass)
item_reflection_shard_2 = item_reflection_shard_1
item_reflection_shard_3 = item_reflection_shard_1

function item_reflection_shard_1:GetIntrinsicModifierName()
    return "modifier_charge_replenisher"
end

function item_reflection_shard_1:OnSpellStart()
  local charges = self:GetCurrentCharges()
  if charges <= 0 then
    return false
  end

  local caster = self:GetCaster()
  local duration = self:GetSpecialValueFor( "duration" )

  self:SetCurrentCharges( charges - 1 )
  if charges == 1 then
    self:StartCooldown(self:GetCooldownTime())
  end

  local chargeReplenishIn = self:GetCooldownTime()

  caster:AddNewModifier( caster, self, "modifier_item_reactive_reflect", { duration = duration } )
  -- Let in-built Lotus Orb modifier handle spell reflecting cause reflecting spells is apparently pretty difficult
  caster:AddNewModifier( caster, self, "modifier_item_lotus_orb_active", { duration = duration } )
end

modifier_item_reactive_reflect = class(ModifierBaseClass)

function modifier_item_reactive_reflect:IsHidden()
  return false
end

function modifier_item_reactive_reflect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_PROPERTY_ABSORB_SPELL
  }
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_item_reactive_reflect:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_item_reactive_reflect:GetAbsorbSpell()
  return 1
end
