-- defines item_preemptive_2a
-- defines modifier_item_preemptive_purge
LinkLuaModifier( "modifier_item_preemptive_purge", "items/reflex/preemptive_purge.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_preemptive_2a = class(ItemBaseClass)

function item_preemptive_2a:GetIntrinsicModifierName()
  return 'modifier_generic_bonus'
end

function item_preemptive_2a:OnSpellStart()
  local caster = self:GetCaster()
  local mod = caster:AddNewModifier(caster, self, 'modifier_item_preemptive_purge', {
    duration = self:GetSpecialValueFor( "duration" )
  })
  local interval = self:GetSpecialValueFor( "tick_interval" )
  mod:StartIntervalThink(interval)

  return true
end

function item_preemptive_2a:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

item_preemptive_3a = item_preemptive_2a --luacheck: ignore item_preemptive_3a
item_preemptive_4a = item_preemptive_2a

------------------------------------------------------------------------

modifier_item_preemptive_purge = class(ModifierBaseClass)

function modifier_item_preemptive_purge:IsHidden()
  return false
end

function modifier_item_preemptive_purge:IsDebuff()
  return false
end

function modifier_item_preemptive_purge:IsPurgable()
  return false
end

function modifier_item_preemptive_purge:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_preemptive_purge:OnIntervalThink()
  if IsServer() then
    -- self:StartIntervalThink( -1 )
    self:GetCaster():Purge(false, true, false, false, false)
  end
end
