-- Fate's Madness

modifier_mr_phys_weak_oaa = class(ModifierBaseClass)

function modifier_mr_phys_weak_oaa:IsHidden()
  return false
end

function modifier_mr_phys_weak_oaa:IsDebuff()
  return false
end

function modifier_mr_phys_weak_oaa:IsPurgable()
  return false
end

function modifier_mr_phys_weak_oaa:RemoveOnDeath()
  return false
end

function modifier_mr_phys_weak_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_mr_phys_weak_oaa:GetModifierIncomingDamage_Percentage(keys)
  if self:GetParent():IsDebuffImmune() then
    return 0
  end
  if keys.damage_type == DAMAGE_TYPE_PHYSICAL then
    return 40
  end
end

function modifier_mr_phys_weak_oaa:GetModifierMagicalResistanceBonus()
  return 75
end

function modifier_mr_phys_weak_oaa:GetModifierAttackSpeedBonus_Constant()
  return 120
end

function modifier_mr_phys_weak_oaa:GetEffectName()
  return "particles/units/heroes/hero_slardar/slardar_amp_damage.vpcf"
end

function modifier_mr_phys_weak_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_mr_phys_weak_oaa:GetTexture()
  return "pangolier_heartpiercer"
end
