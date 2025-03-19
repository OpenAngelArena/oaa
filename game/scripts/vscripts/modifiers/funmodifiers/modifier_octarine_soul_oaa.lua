-- Octarine Soul

modifier_octarine_soul_oaa = class(ModifierBaseClass)

function modifier_octarine_soul_oaa:IsHidden()
  return false
end

function modifier_octarine_soul_oaa:IsDebuff()
  return false
end

function modifier_octarine_soul_oaa:IsPurgable()
  return false
end

function modifier_octarine_soul_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_octarine_soul_oaa:OnCreated()
  self.ignore_abilities = {
    abaddon_borrowed_time_oaa = true,                       -- invulnerability
    beastmaster_call_of_the_wild_boar_oaa = true,           -- lag
    beastmaster_call_of_the_wild_hawk = true,               -- lag
    brewmaster_primal_split = true,                         -- invulnerability
    dark_willow_shadow_realm = true,                        -- untargettable
    dazzle_shallow_grave = true,                            -- invulnerability
    earth_spirit_petrify = true,                            -- invulnerability
    earth_spirit_rolling_boulder = true,                    -- invulnerability
    ember_spirit_sleight_of_fist = true,                    -- invulnerability
    enigma_demonic_conversion = true,                       -- lag
    enigma_demonic_conversion_oaa = true,                   -- lag
    faceless_void_time_walk = true,                         -- invulnerability
    juggernaut_swift_slash = true,                          -- invulnerability
    meepo_petrify = true,                                   -- invulnerability
    morphling_waveform = true,                              -- invulnerability
    obsidian_destroyer_astral_imprisonment = true,          -- invulnerability, banish
    oracle_false_promise = true,                            -- invulnerability
    phantom_lancer_doppelwalk = true,                       -- lag
    puck_phase_shift = true,                                -- invulnerability
    riki_tricks_of_the_trade = true,                        -- invulnerability
    shadow_demon_disruption = true,                         -- invulnerability, banish
    skeleton_king_reincarnation = true,                     -- near unkillable
    slark_depth_shroud = true,                              -- untargettable
    slark_shadow_dance = true,                              -- untargettable
    sohei_flurry_of_blows = true,                           -- invulnerability
    terrorblade_conjure_image = true,                       -- lag
    terrorblade_conjure_image_oaa = true,                   -- lag
    terrorblade_sunder = true,                              -- near unkillable
    tusk_snowball = true,                                   -- invulnerability
    ursa_enrage = true,                                     -- near unkillable
    venomancer_plague_ward = true,                          -- lag
    visage_gravekeepers_cloak = true,                       -- invulnerability
    visage_gravekeepers_cloak_oaa = true,                   -- invulnerability
    void_spirit_dissimilate = true,                         -- invulnerability
    witch_doctor_voodoo_switcheroo_oaa = true,              -- invulnerability
  }

  self.cdr_per_int = 0.1
end

function modifier_octarine_soul_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_octarine_soul_oaa:GetModifierPercentageCooldown(keys)
  local parent = self:GetParent()
  if parent:HasModifier("modifier_pro_active_oaa") or parent:HasModifier("modifier_ham_oaa") then
    return 0
  end
  local ability = keys.ability
  local cdr = self.cdr_per_int * parent:GetIntellect(false)
  if ability and (self.ignore_abilities[ability:GetName()] or ability:IsItem()) then
    return cdr / 5
  else
    return cdr
  end
end

function modifier_octarine_soul_oaa:OnTooltip()
  return self.cdr_per_int * self:GetParent():GetIntellect(false)
end

function modifier_octarine_soul_oaa:GetTexture()
  return "item_octarine_core"
end
