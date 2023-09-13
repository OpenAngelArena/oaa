-- White Queen

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
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
  }
end

function modifier_hero_anti_stun_oaa:GetModifierIncomingDamage_Percentage()
  local parent = self:GetParent()
  local current_ability = parent:GetCurrentActiveAbility()
  if (current_ability and current_ability:IsInAbilityPhase()) or parent:IsChanneling() then
    return -50
  end
  return 0
end

function modifier_hero_anti_stun_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 20000
end

function modifier_hero_anti_stun_oaa:CheckState()
  local parent = self:GetParent()
  local current_ability = parent:GetCurrentActiveAbility()
  if (current_ability and current_ability:IsInAbilityPhase()) or parent:IsChanneling() then
    return {
      [MODIFIER_STATE_HEXED] = false,
      [MODIFIER_STATE_ROOTED] = false,
      [MODIFIER_STATE_SILENCED] = false,
      [MODIFIER_STATE_STUNNED] = false,
      [MODIFIER_STATE_FROZEN] = false,
      [MODIFIER_STATE_FEARED] = false,
      [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
    }
  end
  return {}
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
