
modifier_generic_bonus = class(ModifierBaseClass)

function modifier_generic_bonus:OnCreated()
  self:Setup()
end
function modifier_generic_bonus:OnRefresh()
  self:Setup()
end

function modifier_generic_bonus:Setup()
  local attributesToCheck = {
    'bonus_health',
    'bonus_health_regen',
    'bonus_mana',
    'bonus_mana_regen',
    'bonus_armor',
    'magic_resistance',
    'bonus_strength',
    'bonus_agility',
    'bonus_intellect',
    'bonus_all_stats',
    'bonus_attack_speed',
    'bonus_movement_speed',
    'spell_amp',
    'bonus_damage'
  }

  local ability = self:GetAbility()

  if not ability then
    return
  end

  for i,name in ipairs(attributesToCheck) do
    local value = ability:GetSpecialValueFor(name)
    if value ~= nil then
      self[name] = value
    end
  end
end

function modifier_generic_bonus:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_generic_bonus:GetModifierHealthBonus()
  return self.bonus_health or 0
end

function modifier_generic_bonus:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or 0
end

function modifier_generic_bonus:GetModifierMagicalResistanceBonus()
  return self.magic_resistance or 0
end

function modifier_generic_bonus:GetModifierConstantHealthRegen()
  return self.bonus_health_regen or 0
end

function modifier_generic_bonus:GetModifierBonusStats_Strength()
  return (self.bonus_all_stats or 0) + (self.bonus_strength or 0)
end

function modifier_generic_bonus:GetModifierBonusStats_Agility()
  return (self.bonus_all_stats or 0) + (self.bonus_agility or 0)
end

function modifier_generic_bonus:GetModifierBonusStats_Intellect()
  return (self.bonus_all_stats or 0) + (self.bonus_intellect or 0)
end

function modifier_generic_bonus:GetModifierAttackSpeedBonus_Constant()
  return self.bonus_attack_speed or 0
end

function modifier_generic_bonus:GetModifierMoveSpeedBonus_Constant()
  return self.bonus_movement_speed or 0
end

function modifier_generic_bonus:GetModifierConstantManaRegen()
  return self.bonus_mana_regen or 0
end

function modifier_generic_bonus:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or 0
end

function modifier_generic_bonus:GetModifierManaBonus()
  return self.bonus_mana or 0
end

function modifier_generic_bonus:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or 0
end

function modifier_generic_bonus:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_generic_bonus:IsHidden()
  return true
end
function modifier_generic_bonus:IsDebuff()
  return false
end
function modifier_generic_bonus:IsPurgable()
  return false
end
