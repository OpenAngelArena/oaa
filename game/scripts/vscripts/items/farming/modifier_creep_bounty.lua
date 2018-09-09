LinkLuaModifier( "modifier_creep_bounty_effect", "items/farming/modifier_creep_bounty.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_aura_origin_tracker", "modifiers/aura_baseclass.lua", LUA_MODIFIER_MOTION_NONE)
modifier_creep_bounty = class(AuraProviderBaseClass)

function modifier_creep_bounty:IsHidden()
  return true
end

function modifier_creep_bounty:GetAuraStackingType()
  return AURA_TYPE_NON_STACKING
end

function modifier_creep_bounty:IsAuraActiveOnDeath()
  return true
end

function modifier_creep_bounty:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_creep_bounty:GetAuraDuration()
  return 10
end

function modifier_creep_bounty:GetModifierAura()
  return "modifier_creep_bounty_effect"
end

function modifier_creep_bounty:GetAuraRadius()
  return -1 -- Global aura
end

function modifier_creep_bounty:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER)
end

function modifier_creep_bounty:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_creep_bounty:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_creep_bounty:GetAuraEntityReject(entity)
  return not (IsValidEntity(entity) and entity.GetPlayerOwnerID and entity:GetPlayerOwnerID() == self:GetParent():GetPlayerOwnerID())
end

--------------------------------------------------------------------------

modifier_creep_bounty_effect = class(AuraEffectBaseClass)

function modifier_creep_bounty_effect:IsPurgable()
  return false
end

function modifier_creep_bounty_effect:IsDebuff()
  return true
end

function modifier_creep_bounty_effect:RemoveOnDeath()
  return false
end

function modifier_creep_bounty_effect:OnCreated(keys)
  AuraEffectBaseClass.OnCreated(self, keys)

  self.creepBountyPercent = self:SafeCallWithAbility(
    "creepBountyPercent",
    CallMethod("GetSpecialValueFor", "creep_bounty_percent")
  )
end

function modifier_creep_bounty_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER
  }
end

function modifier_creep_bounty_effect:GetModifierBountyCreepMultiplier()
  return self:SafeCallWithAbility(
    "creepBountyPercent",
    CallMethod("GetSpecialValueFor", "creep_bounty_percent")
  )
end
