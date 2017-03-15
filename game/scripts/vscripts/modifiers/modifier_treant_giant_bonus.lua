require("internal/util")
modifier_treant_giant_bonus = class({})

function modifier_treant_giant_bonus:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }

  return funcs
end

function modifier_treant_giant_bonus:GetModifierExtraHealthBonus()
  return self:GetAbility():GetSpecialValueFor( "treant_giant_hp_bonus" )
end

function modifier_treant_giant_bonus:GetModifierBaseAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor( "treant_giant_damage_bonus" )
end
