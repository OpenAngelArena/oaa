-- Component for handling the ModifierGained Filter used to block silence and stuns on Silt Bosses

if not BossProtectionFilter then
  DebugPrint("Creating filter for Preemptive protect from stun")
  BossProtectionFilter = class({})

  BossProtectionFilter.SilenceSpells = {
    'bloodseeker_blood_bath',
    'death_prophet_silence',
    'disruptor_static_storm',
    'doom_bringer_doom',
    'drow_ranger_silence',
    'earth_spirit_geomagnetic_grip',
    'enigma_black_hole',
    'legion_commander_duel',
    'lone_druid_savage_roar',
    'night_stalker_crippling_fear',
    'puck_waning_rift',
    'riki_smoke_screen',
    'silencer_global_silence',
    'silencer_last_word',
    'skywrath_mage_ancient_seal',
    'techies_suicide',
    'viper_nethertoxin'
  }

  BossProtectionFilter.SilenceItems = {
    'item_bloodthorn',
    'item_orchid'
  }

  -- uses unique modifiers to apply stun
  BossProtectionFilter.UniqueBashSpell = {
    'faceless_void_time_lock',
    'faceless_void_time_lock_oaa',
    'spirit_breaker_greater_bash'
  }

  -- uses unique modifiers to apply stun
  BossProtectionFilter.UniqueStunSpells = {
    'ancient_apparition_cold_feet',
    'bane_nightmare',
    'bane_fiends_grip',
    'batrider_flaming_lasso',
    'beastmaster_primal_roar',
    'rattletrap_power_cogs',
    'dark_seer_vacuum',
    'earth_spirit_petrify',
    'earthshaker_fissure',
    'elder_titan_echo_stomp',
    'enigma_black_hole',
    'faceless_void_chronosphere',
    'invoker_cold_snap',
    'invoker_tornado',
    'jakiro_ice_path',
    'kunkka_torrent',
    'lion_impale',
    'magnataur_skewer',
    'medusa_mystic_snake',
    'medusa_stone_gaze',
    'monkey_king_boundless_strike',
    'morphling_adaptive_strike_str',
    'naga_siren_song_of_the_siren',
    'necrolyte_reapers_scythe',
    'nyx_assassin_spiked_carapace',
    'nyx_assassin_impale',
    'obsidian_destroyer_astral_imprisonment',
    'pangolier_gyroshell',
    'pudge_meat_hook',
    'pudge_dismember',
    'sandking_burrowstrike',
    'shadow_demon_disruption',
    'shadow_shaman_shackles',
    'brewmaster_storm_cyclone',
    'storm_spirit_electric_vortex',
    'tidehunter_ravage',
    'tiny_avalanche',
    'tiny_toss',
    'tusk_walrus_punch',
    'tusk_walrus_kick',
    'windrunner_shackleshot',
    'winter_wyvern_cold_embrace',
    'winter_wyvern_winters_curse'
  }

  BossProtectionFilter.UniqueStunItems = {
    'item_allied_cyclone'
  }

  BossProtectionFilter.HexItems = {
    'item_sheepstick'
  }

  BossProtectionFilter.HexSpells = {
    'lion_voodoo',
    'shadow_shaman_voodoo'
  }


end

function BossProtectionFilter:Init()
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(self, "ModifierGainedFilter"))
end

function BossProtectionFilter:TableContainValue(table, value)
  for key, val in ipairs(table) do
    if val == value then
      print("Found :" .. value )
      return true
    end
  end
  return false
end

function BossProtectionFilter:ModifierGainedFilter(keys)

  if not keys.entindex_parent_const or not keys.entindex_caster_const or not keys.entindex_ability_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local parent = EntIndexToHScript(keys.entindex_parent_const)
  local ability = EntIndexToHScript(keys.entindex_ability_const)

  keys.parentName = parent:GetName()
  keys.casterName = caster:GetName()
  keys.abilityName = ability:GetName()

  local parentHasProtection = parent:HasModifier("modifier_siltbreaker_boss_protection_bash_and_silence")
  if not parentHasProtection then
    return true
  end

  --DevPrintTable(keys)

  -- protected boss should never be bashed or silenced
  if keys.name_const == 'modifier_bashed'
      or BossProtectionFilter:TableContainValue(BossProtectionFilter.UniqueBashSpell, keys.abilityName)
      or BossProtectionFilter:TableContainValue(BossProtectionFilter.SilenceSpells, keys.abilityName)
      or BossProtectionFilter:TableContainValue(BossProtectionFilter.SilenceItems, keys.abilityName) then

    print("Bash/Silence blocked!")
    return false
  end

  -- if boss has active protection block all stuns
  if parent:HasModifier("modifier_siltbreaker_boss_protection") then
    if keys.name_const == 'modifier_stunned'
        or BossProtectionFilter:TableContainValue(BossProtectionFilter.UniqueStunSpells, keys.abilityName)
        or BossProtectionFilter:TableContainValue(BossProtectionFilter.UniqueStunItems, keys.abilityName)
        or BossProtectionFilter:TableContainValue(BossProtectionFilter.HexSpells, keys.abilityName)
        or BossProtectionFilter:TableContainValue(BossProtectionFilter.HexItems, keys.abilityName) then

      print("Stun blocked!")
      return true
    end
  end


  return true
end





