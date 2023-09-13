-- Component for handling the ModifierGained Filter used to block silence and stuns on Silt Bosses

if not BossProtectionFilter then
  DebugPrint("Creating filter for Preemptive protect from stun")

  BossProtectionFilter = class({})

  BossProtectionFilter.SpellsList = {
    axe_berserkers_call = true, -- pierces bkb
    bane_fiends_grip = true, -- pierces bkb
    bane_nightmare = true, -- to prevent weird interactions
    batrider_flaming_lasso = true, -- pierces bkb
    beastmaster_primal_roar = true, -- pierces bkb
    brewmaster_storm_cyclone = true,
    death_prophet_silence = true,
    disruptor_static_storm = true, -- applied constantly in aoe
    doom_bringer_doom = true, -- pierces bkb or applied constantly in aoe
    drow_ranger_wave_of_silence = true,
    earth_spirit_petrify = true,
    elder_titan_earth_splitter = true, -- pierces bkb
    enigma_black_hole = true, -- pierces bkb
    faceless_void_chronosphere = true, -- pierces bkb
    faceless_void_time_lock = true, -- pierces bkb
    faceless_void_time_lock_oaa = true, -- pierces bkb
    keeper_of_the_light_will_o_wisp = true,
    lion_voodoo = true,
    lone_druid_savage_roar = true,
    magnataur_reverse_polarity = true, -- pierces bkb
    magnataur_skewer = true, -- to prevent weird interactions
    medusa_stone_gaze = true, -- pierces bkb
    morphling_adaptive_strike_str = true,
    naga_siren_ensnare = true, -- pierces bkb with scepter
    naga_siren_song_of_the_siren = true, -- applied constantly in aoe
    night_stalker_crippling_fear = true, -- applied constantly in aoe
    phoenix_supernova = true, -- pierces bkb
    primal_beast_pulverize = true, -- pierces bkb
    puck_dream_coil = true, -- pierces bkb with talent
    pudge_dismember = true, -- pierces bkb
    pudge_meat_hook = true, -- pierces bkb
    rattletrap_hookshot = true, -- pierces bkb
    riki_smoke_screen = true, -- applied constantly in aoe
    shadow_shaman_voodoo = true,
    silencer_global_silence = true, -- pierces bkb
    skywrath_mage_ancient_seal = true,
    slardar_bash = true, -- pierces bkb
    slardar_bash_oaa = true, -- pierces bkb
    spirit_breaker_charge_of_darkness = true, -- pierces bkb
    spirit_breaker_greater_bash = true, -- pierces bkb
    storm_spirit_electric_vortex = true,
    tiny_toss = true, -- to prevent weird interactions
    treant_overgrowth = true, -- pierces bkb
    troll_warlord_berserkers_rage = true, -- pierces bkb
    tusk_walrus_kick = true, -- pierces bkb
    tusk_walrus_punch = true, -- pierces bkb
    vengefulspirit_nether_swap = true, -- pierces bkb
    venomancer_latent_poison = true, -- pierces bkb
    warlock_rain_of_chaos = true, -- pierces bkb
    windrunner_shackleshot = true,
    winter_wyvern_winters_curse = true, -- pierces bkb
  }

  BossProtectionFilter.ItemsList = {
    item_abyssal_blade = true, -- pierces bkb
    item_abyssal_blade_2 = true, -- pierces bkb
    item_abyssal_blade_3 = true, -- pierces bkb
    item_abyssal_blade_4 = true, -- pierces bkb
    item_abyssal_blade_5 = true, -- pierces bkb
    item_basher = true, -- pierces bkb
    item_bloodthorn = true,
    item_bloodthorn_2 = true,
    item_bloodthorn_3 = true,
    item_bloodthorn_4 = true,
    item_bloodthorn_5 = true,
    item_bubble_orb_1 = true, -- pierces bkb
    item_bubble_orb_2 = true, -- pierces bkb
    item_orchid = true,
    item_sheepstick = true,
    item_sheepstick_2 = true,
    item_sheepstick_3 = true,
    item_sheepstick_4 = true,
    item_sheepstick_5 = true,
  }

  BossProtectionFilter.ModifierList = {
    modifier_bashed = true, -- pierces bkb
    modifier_huskar_life_break_taunt = true, -- pierces bkb
    modifier_stunned = true, -- sometimes pierces bkb
    modifier_queenofpain_scream_of_pain_fear = true, -- pierces bkb
    modifier_viper_viper_strike_silence = true,
  }
end

function BossProtectionFilter:Init()
  self.moduleName = "Boss Protection Filter"
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(self, "ModifierGainedFilter"))
end

function BossProtectionFilter:ModifierGainedFilter(keys)

  if not keys.entindex_parent_const or not keys.entindex_caster_const or not keys.entindex_ability_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local parent = EntIndexToHScript(keys.entindex_parent_const)
  local ability = EntIndexToHScript(keys.entindex_ability_const)

  local abilityName = ability:GetName()
  local modifierName = keys.name_const

  -- Anchor Smash override
  if parent:IsOAABoss() and abilityName == "tidehunter_anchor_smash" and modifierName == "modifier_tidehunter_anchor_smash" then
    local duration = keys.duration
    parent:AddNewModifier(caster, ability, "modifier_tidehunter_anchor_smash_oaa_boss", {duration = duration})
    return false
  end

  -- True Debuff Immunity
  local parentHasProtection = parent:HasModifier("modifier_boss_debuff_protection_oaa") or parent:HasModifier("modifier_anti_stun_oaa")
  if not parentHasProtection then
    return true
  end

  -- protected boss should never be bashed or silenced
  if BossProtectionFilter.ModifierList[modifierName] or BossProtectionFilter.SpellsList[abilityName] or BossProtectionFilter.ItemsList[abilityName] then
    return false
  end

  return true
end
