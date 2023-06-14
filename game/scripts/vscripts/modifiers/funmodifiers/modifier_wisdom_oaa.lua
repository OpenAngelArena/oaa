modifier_wisdom_oaa = class(ModifierBaseClass)

function modifier_wisdom_oaa:IsHidden()
  return false
end

function modifier_wisdom_oaa:IsDebuff()
  return false
end

function modifier_wisdom_oaa:IsPurgable()
  return false
end

function modifier_wisdom_oaa:RemoveOnDeath()
  return false
end

function modifier_wisdom_oaa:OnCreated()
  self.bonus_int_per_lvl = 1
  self.bonus_spell_amp_per_mana = 0.008

  if not IsServer() then
    return
  end

  -- local parent = self:GetParent()

  -- -- Check if parent has the stuff
  -- if parent.GetPrimaryAttribute == nil then
    -- return
  -- end

  -- local primary_attribute = parent:GetPrimaryAttribute()
  -- local new_primary_attribute
  -- if primary_attribute == DOTA_ATTRIBUTE_INTELLECT then
    -- if RandomInt(0, 1) == 0 then
      -- new_primary_attribute = DOTA_ATTRIBUTE_AGILITY
    -- else
      -- new_primary_attribute = DOTA_ATTRIBUTE_STRENGTH
    -- end
  -- else
    -- new_primary_attribute = DOTA_ATTRIBUTE_INTELLECT
  -- end

  -- -- Change Primary attribute
  -- parent:SetPrimaryAttribute(new_primary_attribute)
end

function modifier_wisdom_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_wisdom_oaa:GetModifierBonusStats_Intellect()
  local parent = self:GetParent()
  return self.bonus_int_per_lvl * parent:GetLevel()
end

function modifier_wisdom_oaa:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  return self.bonus_spell_amp_per_mana * parent:GetMaxMana()
end

function modifier_wisdom_oaa:GetTexture()
  return "item_staff_of_wizardry"
end
