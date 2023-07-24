-- Component for handling the ModifierGained Filter used to block silence and stuns on Silt Bosses

if not BossProtectionFilter then
  DebugPrint("Creating filter for Preemptive protect from stun")

  BossProtectionFilter = class({})

  BossProtectionFilter.SilenceSpells = {
    bloodseeker_blood_bath = true,
    death_prophet_silence = true,
    disruptor_static_storm = true,
    doom_bringer_doom = true,
    drow_ranger_silence = true,
    earth_spirit_geomagnetic_grip = true,
    enigma_black_hole = true,
    legion_commander_duel = true,
    lone_druid_savage_roar = true,
    night_stalker_crippling_fear = true,
    puck_waning_rift = true,
    riki_smoke_screen = true,
    silencer_global_silence = true,
    silencer_last_word = true,
    skywrath_mage_ancient_seal = true,
    techies_suicide = true
  }

  BossProtectionFilter.SilenceItems = {
    item_bloodthorn = true,
    item_orchid = true
  }

  -- uses unique modifiers to apply stun (not modifier_bashed)
  BossProtectionFilter.UniqueBashSpell = {
    faceless_void_time_lock = true,
    faceless_void_time_lock_oaa = true,
    spirit_breaker_greater_bash = true
  }

  -- uses unique modifiers to apply stun (not modifier_stunned)
  BossProtectionFilter.UniqueStunSpells = {
    ancient_apparition_cold_feet = true,
    bane_nightmare = true,
    bane_fiends_grip = true,
    batrider_flaming_lasso = true,
    beastmaster_primal_roar = true,
    rattletrap_power_cogs = true,
    dark_seer_vacuum = true,
    earth_spirit_petrify = true,
    earthshaker_fissure = true,
    elder_titan_echo_stomp = true,
    enigma_black_hole = true,
    faceless_void_chronosphere = true,
    invoker_cold_snap = true,
    invoker_tornado = true,
    jakiro_ice_path = true,
    kunkka_torrent = true,
    lion_impale = true,
    magnataur_skewer = true,
    medusa_mystic_snake = true,
    medusa_stone_gaze = true,
    monkey_king_boundless_strike = true,
    morphling_adaptive_strike_str = true,
    naga_siren_song_of_the_siren = true,
    --necrolyte_reapers_scythe = true,
    nyx_assassin_spiked_carapace = true,
    nyx_assassin_impale = true,
    obsidian_destroyer_astral_imprisonment = true,
    --pangolier_gyroshell = true,
    pudge_meat_hook = true,
    pudge_dismember = true,
    sandking_burrowstrike = true,
    shadow_demon_disruption = true,
    shadow_shaman_shackles = true,
    brewmaster_storm_cyclone = true,
    storm_spirit_electric_vortex = true,
    tidehunter_ravage = true,
    tiny_avalanche = true,
    tiny_toss = true,
    tusk_walrus_punch = true,
    tusk_walrus_kick = true,
    windrunner_shackleshot = true,
    winter_wyvern_cold_embrace = true,
    winter_wyvern_winters_curse = true
  }

  BossProtectionFilter.HexItems = {
    item_sheepstick = true
  }

  BossProtectionFilter.HexSpells = {
    lion_voodoo = true,
    shadow_shaman_voodoo = true
  }

end

function BossProtectionFilter:Init()
  self.moduleName = "Boss Protection Filter"
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(self, "ModifierGainedFilter"))
  LinkLuaModifier("modifier_tidehunter_anchor_smash_oaa_boss", "modifiers/modifier_tidehunter_anchor_smash_oaa_boss.lua", LUA_MODIFIER_MOTION_NONE)
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
  local parentHasProtection = parent:HasModifier("modifier_boss_debuff_protection_oaa")
  if not parentHasProtection then
    return true
  end

  --DevPrintTable(keys)

  -- protected boss should never be bashed or silenced
  if modifierName == 'modifier_bashed'
      or BossProtectionFilter.UniqueBashSpell[abilityName]
      or BossProtectionFilter.SilenceSpells[abilityName]
      or BossProtectionFilter.SilenceItems[abilityName] then
    return false
  end

  if modifierName == 'modifier_stunned'
      or BossProtectionFilter.UniqueStunSpells[abilityName]
      or BossProtectionFilter.HexSpells[abilityName]
      or BossProtectionFilter.HexItems[abilityName] then
    return false
  end

  return true
end
