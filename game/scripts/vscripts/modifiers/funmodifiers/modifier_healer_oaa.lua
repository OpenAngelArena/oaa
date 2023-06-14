modifier_healer_oaa = class(ModifierBaseClass)

function modifier_healer_oaa:IsHidden()
  return false
end

function modifier_healer_oaa:IsDebuff()
  return false
end

function modifier_healer_oaa:IsPurgable()
  return false
end

function modifier_healer_oaa:RemoveOnDeath()
  return false
end

function modifier_healer_oaa:OnCreated()
  self.heal_amp = 75
end

function modifier_healer_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_healer_oaa:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp
end

function modifier_healer_oaa:GetModifierHealAmplify_PercentageTarget()
  return self.heal_amp
end

--function modifier_healer_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  --return self.heal_amp
--end

function modifier_healer_oaa:GetTexture()
  return "item_holy_locket"
end
