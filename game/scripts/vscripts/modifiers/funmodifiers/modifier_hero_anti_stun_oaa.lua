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

function modifier_hero_anti_stun_oaa:CheckState()
  local parent = self:GetParent()
  local current_ability = parent:GetCurrentActiveAbility()
  if (current_ability and (current_ability:IsInAbilityPhase() or current_ability:IsChanneling())) or parent:IsChanneling() then
    return {
      [MODIFIER_STATE_DEBUFF_IMMUNE] = true,
    }
  end
  return {}
end

function modifier_hero_anti_stun_oaa:GetTexture()
  return "custom/modifiers/white_queen"
end
