modifier_glass_cannon_oaa = class(ModifierBaseClass)

function modifier_glass_cannon_oaa:IsHidden()
  return false
end

function modifier_glass_cannon_oaa:IsDebuff()
  return true
end

function modifier_glass_cannon_oaa:IsPurgable()
  return false
end

function modifier_glass_cannon_oaa:RemoveOnDeath()
  return false
end

function modifier_glass_cannon_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_glass_cannon_oaa:GetModifierBonusStats_Strength()
  return -999
end

function modifier_glass_cannon_oaa:GetModifierPreAttack_BonusDamage()
  return 500
end

function modifier_glass_cannon_oaa:GetTexture()
  return "item_blades_of_attack"
end
