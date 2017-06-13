--[[
-Modifier to grant 2x health/damage
Base health and damage is checked only on first application of modifier
Primary use of this modifier is for Nature's Prophet 2x Treant health/damage talent
]]
modifier_treant_bonus_oaa = class(ModifierBaseClass)

function modifier_treant_bonus_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
  }

  return funcs
end

function modifier_treant_bonus_oaa:OnCreated(keys)
  if IsServer() then
    local parentUnit = self:GetParent()
    -- Get parent unit's base health and damage at time of modifier application
    self.parentMaxHealth = parentUnit:GetBaseMaxHealth()
    self.parentMinDamage = parentUnit:GetBaseDamageMin()
    self.parentMaxDamage = parentUnit:GetBaseDamageMax()
  end
end

function modifier_treant_bonus_oaa:IsPurgable()
  return false
end

function modifier_treant_bonus_oaa:GetModifierExtraHealthBonus()
  return self.parentMaxHealth
end

function modifier_treant_bonus_oaa:GetModifierBaseAttack_BonusDamage()
  -- Check that min and max damage values have been fetched to prevent errors
  if self.parentMinDamage and self.parentMaxDamage then
    return (self.parentMinDamage + self.parentMaxDamage) / 2
  end
end
