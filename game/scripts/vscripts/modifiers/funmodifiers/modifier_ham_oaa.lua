modifier_ham_oaa = class(ModifierBaseClass)

function modifier_ham_oaa:IsHidden()
  return true
end

function modifier_ham_oaa:IsPurgable()
  return false
end

function modifier_ham_oaa:RemoveOnDeath()
  return false
end

function modifier_ham_oaa:OnCreated()
  self.ignore_abilities = {
    brewmaster_primal_split = true,
    obsidian_destroyer_astral_imprisonment = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    shadow_demon_disruption = true,
    tusk_snowball = true,
    venomancer_plague_ward = true,
    void_spirit_dissimilate = true,
  }

  self.cdr = 35
  self.mana_cost_reduction = 35
  self.status_resist = 35
end

function modifier_ham_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_ham_oaa:GetModifierPercentageCooldown(keys)
  if keys.ability and self.ignore_abilities[keys.ability:GetName()] then
    return 0
  else
    return self.cdr
  end
end

function modifier_ham_oaa:GetModifierPercentageManacostStacking()
  return self.mana_cost_reduction
end

function modifier_ham_oaa:GetModifierStatusResistanceStacking()
  return self.status_resist
end

--function modifier_ham_oaa:GetTexture()
  --return ""
--end
