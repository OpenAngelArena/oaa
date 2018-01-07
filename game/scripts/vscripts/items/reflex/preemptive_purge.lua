-- defines item_dispel_orb_1
-- defines modifier_item_preemptive_purge
LinkLuaModifier( "modifier_item_preemptive_purge", "items/reflex/preemptive_purge.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_dispel_orb_1 = class(ItemBaseClass)

function item_dispel_orb_1:GetIntrinsicModifierName()
  return 'modifier_generic_bonus'
end

function item_dispel_orb_1:OnSpellStart()
  local caster = self:GetCaster()
  local mod = caster:AddNewModifier(caster, self, 'modifier_item_preemptive_purge', {
    duration = self:GetSpecialValueFor( "duration" )
  })
  local interval = self:GetSpecialValueFor( "tick_interval" )
  mod:StartIntervalThink(interval)

  return true
end

function item_dispel_orb_1:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

item_dispel_orb_2 = item_dispel_orb_1 --luacheck: ignore item_dispel_orb_2
item_dispel_orb_3 = item_dispel_orb_1

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
