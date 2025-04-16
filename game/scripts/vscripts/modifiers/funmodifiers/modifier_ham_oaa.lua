-- Hyper Active

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
    abaddon_borrowed_time_oaa = true,                       -- invulnerability
    beastmaster_call_of_the_wild_boar_oaa = true,           -- lag
    beastmaster_call_of_the_wild_hawk = true,               -- lag
    brewmaster_primal_split = true,                         -- invulnerability
    dark_willow_shadow_realm = true,                        -- untargettable
    dazzle_shallow_grave = true,                            -- invulnerability
    earth_spirit_petrify = true,                            -- invulnerability
    --earth_spirit_rolling_boulder = true,                    -- invulnerability
    --ember_spirit_sleight_of_fist = true,                    -- invulnerability
    enigma_demonic_conversion = true,                       -- lag
    enigma_demonic_conversion_oaa = true,                   -- lag
    --faceless_void_time_walk = true,                         -- invulnerability
    --juggernaut_swift_slash = true,                          -- invulnerability
    meepo_petrify = true,                                   -- invulnerability
    --morphling_waveform = true,                              -- invulnerability
    obsidian_destroyer_astral_imprisonment = true,          -- invulnerability, banish
    oracle_false_promise = true,                            -- invulnerability
    phantom_lancer_doppelwalk = true,                       -- lag
    puck_phase_shift = true,                                -- invulnerability
    riki_tricks_of_the_trade = true,                        -- invulnerability
    shadow_demon_disruption = true,                         -- invulnerability, banish
    skeleton_king_reincarnation = true,                     -- near unkillable
    --slark_depth_shroud = true,                              -- untargettable
    --slark_shadow_dance = true,                              -- untargettable
    --sohei_flurry_of_blows = true,                           -- invulnerability
    terrorblade_conjure_image = true,                       -- lag
    terrorblade_conjure_image_oaa = true,                   -- lag
    --terrorblade_sunder = true,                              -- near unkillable
    tusk_snowball = true,                                   -- invulnerability
    --ursa_enrage = true,                                     -- near unkillable
    venomancer_plague_ward = true,                          -- lag
    visage_gravekeepers_cloak = true,                       -- invulnerability
    visage_gravekeepers_cloak_oaa = true,                   -- invulnerability
    void_spirit_dissimilate = true,                         -- invulnerability
    witch_doctor_voodoo_switcheroo_oaa = true,              -- invulnerability
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
  local ability = keys.ability
  if ability and (self.ignore_abilities[ability:GetName()] or ability:IsItem()) then
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
