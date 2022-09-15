modifier_pro_active_oaa = class(ModifierBaseClass)

function modifier_pro_active_oaa:IsHidden()
  return false
end

function modifier_pro_active_oaa:IsDebuff()
  return false
end

function modifier_pro_active_oaa:IsPurgable()
  return false
end

function modifier_pro_active_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_pro_active_oaa:OnCreated()
  self.ignore_abilities = {
    abaddon_borrowed_time_oaa = true,
    brewmaster_primal_split = true,
    dark_willow_shadow_realm = true,
    dazzle_good_juju = true,
    dazzle_shallow_grave = true,
    earth_spirit_petrify = true,
    meepo_petrify = true,
    obsidian_destroyer_astral_imprisonment = true,
    oracle_fates_edict = true,
    oracle_false_promise = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    shadow_demon_disruption = true,
    skeleton_king_reincarnation = true,
    tusk_snowball = true,
    venomancer_plague_ward = true,
    visage_gravekeepers_cloak = true,
    visage_gravekeepers_cloak_oaa = true,
    void_spirit_dissimilate = true,
    witch_doctor_voodoo_switcheroo_oaa = true,
  }

  self.cdr_penalty = 10
  self.cdr = 50
end

function modifier_pro_active_oaa:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end

function modifier_pro_active_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
  }
end

function modifier_pro_active_oaa:GetModifierPercentageCooldown(keys)
  local ability = keys.ability
  if ability and (self.ignore_abilities[ability:GetName()] or ability:IsItem()) then
    return self.cdr_penalty
  else
    return self.cdr
  end
end

function modifier_pro_active_oaa:GetTexture()
  return "dazzle_bad_juju"
end
