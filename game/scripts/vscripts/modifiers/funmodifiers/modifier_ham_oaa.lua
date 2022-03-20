modifier_ham_oaa = class(ModifierBaseClass)

function modifier_ham_oaa:IsHidden()
  return false
end

function modifier_ham_oaa:IsDebuff()
  return false
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
    dark_willow_shadow_realm = true,
    earth_spirit_petrify = true,
    obsidian_destroyer_astral_imprisonment = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    shadow_demon_disruption = true,
    skeleton_king_reincarnation = true,
    tusk_snowball = true,
    venomancer_plague_ward = true,
    void_spirit_dissimilate = true,
    witch_doctor_voodoo_switcheroo_oaa = true,
  }

  self.cdr_penalty = 5
  self.cdr = 25
  self.mana_cost_reduction = 25
  self.status_resist = 25
end

function modifier_ham_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
  }
end

function modifier_ham_oaa:GetModifierPercentageCooldown(keys)
  if self:GetParent():HasModifier("modifier_pro_active_oaa") then
    return 0
  end
  if keys.ability and self.ignore_abilities[keys.ability:GetName()] then
    return self.cdr_penalty
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

function modifier_ham_oaa:GetTexture()
  return "rune_arcane"
end
