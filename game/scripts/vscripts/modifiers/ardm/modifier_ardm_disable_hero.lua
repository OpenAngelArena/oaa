modifier_ardm_disable_hero = modifier_ardm_disable_hero or class({})

function modifier_ardm_disable_hero:IsHidden()
  return true
end

function modifier_ardm_disable_hero:IsDebuff()
  return true
end

function modifier_ardm_disable_hero:IsPurgable()
  return false
end

function modifier_ardm_disable_hero:RemoveOnDeath()
  return false
end

function modifier_ardm_disable_hero:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_ardm_disable_hero:IsAura()
  return true
end

function modifier_ardm_disable_hero:GetModifierAura()
  return "modifier_out_of_duel"
end

function modifier_ardm_disable_hero:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_ardm_disable_hero:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_ardm_disable_hero:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_ardm_disable_hero:GetAuraRadius()
  return 200
end

function modifier_ardm_disable_hero:GetAuraEntityReject(hEntity)
  local parent = self:GetParent()
  if hEntity ~= parent then
    return true
  end
  return false
end
