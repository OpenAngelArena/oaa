
modifier_boss_charger_hero_pillar_debuff = class(ModifierBaseClass)

function modifier_boss_charger_hero_pillar_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_boss_charger_hero_pillar_debuff:IsDebuff()
  return true
end

function modifier_boss_charger_hero_pillar_debuff:IsHidden()
  return false
end

function modifier_boss_charger_hero_pillar_debuff:IsPurgable()
  return true
end

function modifier_boss_charger_hero_pillar_debuff:IsStunDebuff()
  return true
end

function modifier_boss_charger_hero_pillar_debuff:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_boss_charger_hero_pillar_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_charger_hero_pillar_debuff:GetOverrideAnimation( params )
  return ACT_DOTA_DISABLED
end

function modifier_boss_charger_hero_pillar_debuff:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true
  }

  return state
end
