-- defines item_reduction_orb_1
-- defines modifier_item_preemptive
LinkLuaModifier( "modifier_item_preemptive", "items/reflex/preemptive.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_reduction_orb_1 = class(ItemBaseClass)

function item_reduction_orb_1:GetIntrinsicModifierName()
  return 'modifier_generic_bonus'
end

function item_reduction_orb_1:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, 'modifier_item_preemptive', {
    duration = self:GetSpecialValueFor( "duration" )
  })

  return true
end

function item_reduction_orb_1:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

modifier_item_preemptive = class(ModifierBaseClass)

function modifier_item_preemptive:IsHidden()
  return false
end

function modifier_item_preemptive:IsDebuff()
  return false
end

function modifier_item_preemptive:IsPurgable()
  return false
end

function modifier_item_preemptive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_preemptive:GetModifierIncomingDamage_Percentage (event)
  local spell = self:GetAbility()

  return spell:GetSpecialValueFor( "damage_reduction" ) * -1
end
