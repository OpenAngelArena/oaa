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
    abaddon_borrowed_time_oaa = true,
    brewmaster_primal_split = true,
    dark_willow_shadow_realm = true,
    dazzle_bad_juju = true,
    dazzle_shallow_grave = true,
    earth_spirit_petrify = true,
    --earth_spirit_rolling_boulder = true,
    --faceless_void_time_walk = true,
    meepo_petrify = true,
    obsidian_destroyer_astral_imprisonment = true,
    oracle_false_promise = true,
    oracle_fates_edict = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    shadow_demon_disruption = true,
    skeleton_king_reincarnation = true,
    --slark_shadow_dance = true,
    --terrorblade_sunder = true,
    tusk_snowball = true,
    --ursa_enrage = true,
    visage_gravekeepers_cloak = true,
    visage_gravekeepers_cloak_oaa = true,
    void_spirit_dissimilate = true,
    witch_doctor_voodoo_switcheroo_oaa = true,
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
  if ability and (self.ignore_abilities[ability:GetName()] or ability:IsItem()) then
    return 0
  else
    return self.cdr_per_int * parent:GetIntellect(false)
  end
end

function modifier_octarine_soul_oaa:OnTooltip()
  return self.cdr_per_int * self:GetParent():GetIntellect(false)
end

function modifier_octarine_soul_oaa:GetTexture()
  return "item_octarine_core"
end
