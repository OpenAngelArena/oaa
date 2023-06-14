-- Anti-Judecca

modifier_all_healing_amplify_oaa = class(ModifierBaseClass)

function modifier_all_healing_amplify_oaa:IsHidden()
  return false
end

function modifier_all_healing_amplify_oaa:IsDebuff()
  return false
end

function modifier_all_healing_amplify_oaa:IsPurgable()
  return false
end

function modifier_all_healing_amplify_oaa:RemoveOnDeath()
  return false
end

function modifier_all_healing_amplify_oaa:OnCreated()
  self.heal_amp = 50
end

function modifier_all_healing_amplify_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
    MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
    MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
  }
end

function modifier_all_healing_amplify_oaa:GetModifierHealAmplify_PercentageSource()
  return self.heal_amp
end

function modifier_all_healing_amplify_oaa:GetModifierLifestealRegenAmplify_Percentage()
  return self.heal_amp
end

function modifier_all_healing_amplify_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  return self.heal_amp
end

function modifier_all_healing_amplify_oaa:GetModifierHPRegenAmplify_Percentage()
  return self.heal_amp
end

function modifier_all_healing_amplify_oaa:GetTexture()
  return "item_kaya_and_sange"
end
