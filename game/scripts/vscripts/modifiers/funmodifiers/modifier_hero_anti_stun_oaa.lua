modifier_hero_anti_stun_oaa = class(ModifierBaseClass)

function modifier_hero_anti_stun_oaa:IsHidden()
  return false
end

function modifier_hero_anti_stun_oaa:IsDebuff()
  return false
end

function modifier_hero_anti_stun_oaa:IsPurgable()
  return false
end

function modifier_hero_anti_stun_oaa:RemoveOnDeath()
  return false
end

function modifier_hero_anti_stun_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_hero_anti_stun_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
  return -30
end

-- This also works for slows, we don't want that
--function modifier_hero_anti_stun_oaa:GetModifierStatusResistanceStacking()
  --return 100
--end

function modifier_hero_anti_stun_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_hero_anti_stun_oaa:CheckState()
  return {
    [MODIFIER_STATE_HEXED] = false,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_SILENCED] = false,
    [MODIFIER_STATE_STUNNED] = false,
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
  }
end

function modifier_hero_anti_stun_oaa:GetEffectName()
  return "particles/units/heroes/hero_spirit_breaker/spirit_breaker_haste_owner.vpcf"
end

function modifier_hero_anti_stun_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_hero_anti_stun_oaa:GetTexture()
  return "templar_assassin_refraction"
end
