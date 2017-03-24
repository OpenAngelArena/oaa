-- defines item_preemptive_2a
-- defines modifier_item_preemptive_2a
LinkLuaModifier( "modifier_item_preemptive_2a", "items/reflex/preemptive_2a.lua", LUA_MODIFIER_MOTION_NONE )

------------------------------------------------------------------------

item_preemptive_2a = class({})

function item_preemptive_2a:OnSpellStart()
  local caster = self:GetCaster()
  local mod = caster:AddNewModifier(caster, self, 'modifier_item_preemptive_2a', {
    duration = self:GetSpecialValueFor( "duration" )
  })
  local interval = self:GetSpecialValueFor( "tick_interval" )
  mod:StartIntervalThink(interval)

  return true
end

function item_preemptive_2a:GetCooldown( nLevel )
  return self:GetSpecialValueFor( "cooldown" )
end

function item_preemptive_2a:ProcsMagicStick ()
  return false
end

------------------------------------------------------------------------

modifier_item_preemptive_2a = class({})

function modifier_item_preemptive_2a:IsHidden()
  return false
end

function modifier_item_preemptive_2a:IsDebuff()
  return false
end

function modifier_item_preemptive_2a:IsPurgable()
  return false
end

function modifier_item_preemptive_2a:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_item_preemptive_2a:OnIntervalThink()
  if IsServer() then
    -- self:StartIntervalThink( -1 )
    self:GetCaster():Purge(false, true, false, false, false)
  end
end
