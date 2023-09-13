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
    dazzle_shallow_grave = true,
    earth_spirit_petrify = true,
    item_abyssal_blade_2 = true,
    item_abyssal_blade_3 = true,
    item_abyssal_blade_4 = true,
    item_abyssal_blade_5 = true,
    item_aeon_disk_oaa_2 = true,
    item_aeon_disk_oaa_3 = true,
    item_aeon_disk_oaa_4 = true,
    item_aeon_disk_oaa_5 = true,
    item_arcane_blink = true,
    item_arcane_blink_2 = true,
    item_arcane_blink_3 = true,
    item_arcane_blink_4 = true,
    item_arcane_blink_5 = true,
    item_bubble_orb_1 = true,
    item_bubble_orb_2 = true,
    item_cyclone = true,
    item_magic_lamp_1 = true,
    item_reduction_orb_3 = true,
    item_refresher_4 = true,
    item_refresher_5 = true,
    item_regen_crystal_1 = true,
    item_regen_crystal_2 = true,
    item_regen_crystal_3 = true,
    item_regen_crystal_4 = true,
    item_sheepstick_4 = true,
    item_sheepstick_5 = true,
    item_shield_staff = true,
    item_shield_staff_2 = true,
    item_shield_staff_3 = true,
    item_shield_staff_4 = true,
    item_shield_staff_5 = true,
    item_sphere = true,
    item_sphere_2 = true,
    item_sphere_3 = true,
    item_sphere_4 = true,
    item_sphere_5 = true,
    item_trumps_fists_1 = true,
    item_trumps_fists_2 = true,
    item_wind_waker = true,
    item_wind_waker_2 = true,
    item_wind_waker_3 = true,
    item_wind_waker_4 = true,
    item_wind_waker_5 = true,
    meepo_petrify = true,
    obsidian_destroyer_astral_imprisonment = true,
    oracle_false_promise = true,
    oracle_fates_edict = true,
    phantom_lancer_doppelwalk = true,
    puck_phase_shift = true,
    riki_tricks_of_the_trade = true,
    shadow_demon_disruption = true,
    skeleton_king_reincarnation = true,
    tusk_snowball = true,
    visage_gravekeepers_cloak = true,
    visage_gravekeepers_cloak_oaa = true,
    void_spirit_dissimilate = true,
    witch_doctor_voodoo_switcheroo_oaa = true,
  }

  self.cdr_per_int = 0.08
end

function modifier_octarine_soul_oaa:CheckState()
  return {
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
  }
end

function modifier_octarine_soul_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
  }
end

function modifier_octarine_soul_oaa:GetModifierPercentageCooldown(keys)
  local parent = self:GetParent()
  local ability = keys.ability
  if ability and self.ignore_abilities[ability:GetName()] then
    return 0
  else
    return self.cdr_per_int * parent:GetIntellect()
  end
end

function modifier_octarine_soul_oaa:GetTexture()
  return "item_octarine_core"
end
