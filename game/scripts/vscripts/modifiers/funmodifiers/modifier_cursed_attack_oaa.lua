modifier_cursed_attack_oaa = class(ModifierBaseClass)

function modifier_cursed_attack_oaa:IsHidden()
  return false
end

function modifier_cursed_attack_oaa:IsDebuff()
  return true
end

function modifier_cursed_attack_oaa:IsPurgable()
  return false
end

function modifier_cursed_attack_oaa:RemoveOnDeath()
  return false
end

function modifier_cursed_attack_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MISS_PERCENTAGE,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
  }
end

function modifier_cursed_attack_oaa:GetModifierMiss_Percentage()
  return 75
end

function modifier_cursed_attack_oaa:GetModifierBonusStats_Agility()
  return -999
end

function modifier_cursed_attack_oaa:GetModifierProcAttack_BonusDamage_Pure()
  return 400
end

function modifier_cursed_attack_oaa:GetEffectName()
  return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf"
end

function modifier_cursed_attack_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_cursed_attack_oaa:GetTexture()
  return "antimage_mana_overload"
end
