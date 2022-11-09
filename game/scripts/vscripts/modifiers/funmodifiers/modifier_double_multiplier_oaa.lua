modifier_double_multiplier_oaa = class(ModifierBaseClass)

function modifier_double_multiplier_oaa:IsHidden()
  return false
end

function modifier_double_multiplier_oaa:IsDebuff()
  return false
end

function modifier_double_multiplier_oaa:IsPurgable()
  return false
end

function modifier_double_multiplier_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_double_multiplier_oaa:OnCreated()
  self.multiplier = 2
  if IsServer() then
    self:SetStackCount(self.multiplier)
  end
end

function modifier_double_multiplier_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecial(keys)
  if not keys.ability or not keys.ability_special_value then
    return 0
  end

  if keys.ability:IsItem() then
    return 0
  end

  return 1
end

function modifier_double_multiplier_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  if not keys.ability_special_value or not keys.ability_special_level then
    return
  end

  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if keys.ability:IsItem() then
    return value
  end

  return value * self.multiplier
end

function modifier_double_multiplier_oaa:GetTexture()
  return "item_talisman_of_evasion"
end
