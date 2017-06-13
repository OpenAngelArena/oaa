-- Modifier that grants complete damage immunity. Mainly for protecting "purge tester" units, like in
-- items/reflex/postactive.lua
modifier_purgetester = class(ModifierBaseClass)

function modifier_purgetester:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
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

function modifier_purgetester:GetAbsoluteNoDamageMagical(keys)
  return 1
end

function modifier_purgetester:GetAbsoluteNoDamagePhysical(keys)
  return 1
end

function modifier_purgetester:GetAbsoluteNoDamagePure(keys)
  return 1
end
