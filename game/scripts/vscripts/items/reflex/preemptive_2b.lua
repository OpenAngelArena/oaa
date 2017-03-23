-- defines item_preemptive_2b
-- defines modifier_item_preemptive_2b
LinkLuaModifier( "modifier_item_preemptive_2b", "items/reflex/preemptive_2b.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_preemptive_2b = class({})

function item_preemptive_2b:OnSpellStart()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, 'modifier_item_preemptive_2b', {
    duration = self:GetSpecialValueFor( "duration" )
  })

  return true
end

function item_preemptive_2b:GetCooldown( nLevel )
  return self:GetSpecialValueFor( "cooldown" )
end

function item_preemptive_2b:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

modifier_item_preemptive_2b = class({})

function modifier_item_preemptive_2b:IsHidden()
  return false
end

function modifier_item_preemptive_2b:IsDebuff()
  return false
end

function modifier_item_preemptive_2b:IsPurgable()
  return false
end

function modifier_item_preemptive_2b:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_preemptive_2b:GetModifierIncomingDamage_Percentage (event)
  local spell = self:GetAbility()

  return spell:GetSpecialValueFor( "damage_reduction" )
end
