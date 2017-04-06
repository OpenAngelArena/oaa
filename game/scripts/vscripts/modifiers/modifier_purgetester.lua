-- Modifier that grants 500% damage reduction. Mainly for protecting "purge tester" units, like in
-- items/reflex/postactive.lua
modifier_purgetester = class({})

function modifier_purgetester:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
end

function modifier_purgetester:IsHidden()
  return true
end

function modifier_purgetester:IsPurgable()
  return false
end

function modifier_purgetester:IsPurgeException()
  return false
end

function modifier_purgetester:GetModifierIncomingDamage_Percentage(keys)
  return -500
end
