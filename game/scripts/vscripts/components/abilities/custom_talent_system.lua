if CustomTalentSystem == nil then
  CustomTalentSystem = class({})
end

function CustomTalentSystem:Init()
  self.moduleName = "CustomTalentSystem"
  GameEvents:OnHeroInGame(partial(self.InitializeTalentTracker, self))
  CustomGameEventManager:RegisterListener('custom_learn_talent_event', Dynamic_Wrap(CustomTalentSystem, 'LearnTalent'))
end

function CustomTalentSystem:InitializeTalentTracker(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  --Timers:CreateTimer(2, function ()
  if not hero:HasModifier("modifier_talent_tracker_oaa") then
    hero:AddNewModifier(hero, nil, "modifier_talent_tracker_oaa", {})
  end

  --end)
end

function CustomTalentSystem:LearnTalent(event)
  local playerID = event.PlayerID
  local talent_index = event.ability
  local player = PlayerResource:GetPlayer(playerID)
  if talent_index then
    local talent = EntIndexToHScript(talent_index)
    local name = talent:GetAbilityName()
    local caster = talent:GetCaster()

    -- If ability was already leveled, do nothing.
    if talent:GetLevel() > 0 then
      print('Ability '..name..' already learned')
      return
    end

    -- Verify ability is actually a talent
    if not IsTalentCustom(talent) then
      print('Ability '..name..' is not a talent!')
      return
    end

    -- If the caster is not a real hero, do nothing
    if not caster:IsRealHero() then
      print('Tried to learn talent '..name..' Caster is not a real hero!')
      return
    end

    -- Check if caster belongs to the player
    if player and player:GetAssignedHero() ~= caster then
      print('Tried to learn talent '..name..' Caster doesnt belong to player '..playerID)
      return
    end

    -- Check caster's ability/skill points
    if caster:GetAbilityPoints() <= 0 then
      print('Tried to learn talent '..name..' Caster doesnt have enough skill points.')
      return
    end

    -- Level up the talent
    -- this does not trigger dota_player_learned_ability event on its own (because no playerID attached?)
    -- maybe Valve will change this in the future
    talent:SetLevel(1)

    -- Spend ability/skill points
    caster:SetAbilityPoints(caster:GetAbilityPoints() - 1)

    local event_for_sending = {
      PlayerID = playerID,
      abilityname = name,
    }
    FireGameEvent("dota_player_learned_ability", event_for_sending)
  end
end

-- Format:
-- ability_name = {
  -- kv_name_1 = {"custom_talent_name", "type"},
  -- kv_name_2 = {"custom_talent_name", "type"},
  -- ...
-- },
-- kv_name can't be AbilityDamage or #AbilityDamage, it doesn't work for that
-- type can be: +, -, *, x, /, %
-- * and x are the same -  muliplies the base value with the talent value
-- / - can be used for dividing cooldowns, intervals etc.
-- % - increases the base value by the talent value (e.g. 20% increase of base value)

local abilities_with_custom_talents = {
  abyssal_underlord_pit_of_malice = {
    pit_damage = {"special_bonus_unique_underlord_7_oaa", "%"},
  },
  chaos_knight_reality_rift = {
    armor_reduction = {"special_bonus_unique_chaos_knight_1_oaa", "+"},
  },
  death_prophet_spirit_siphon = {
    damage_pct = {"special_bonus_unique_death_prophet_1_oaa", "+"},
    AbilityChargeRestoreTime = {"special_bonus_unique_death_prophet_5_oaa", "+"},
  },
  dragon_knight_breathe_fire = {
    damage = {"special_bonus_unique_dragon_knight_1_oaa", "+"},
  },
  faceless_void_chronosphere = {
    AbilityCooldown = {"special_bonus_unique_faceless_void_2_oaa", "+"},
  },
  faceless_void_time_dilation = {
    radius = {"special_bonus_unique_faceless_void_1_oaa", "+"},
  },
  faceless_void_time_zone = {
    AbilityCooldown = {"special_bonus_unique_faceless_void_2_oaa", "+"},
  },
  gyrocopter_flak_cannon = {
    radius = {"special_bonus_unique_gyrocopter_1_oaa", "+"},
  },
  hoodwink_acorn_shot = {
    base_damage_pct = {"special_bonus_unique_hoodwink_1_oaa", "+"},
  },
  huskar_inner_fire = {
    damage = {"special_bonus_unique_huskar_1_oaa", "+"},
  },
  invoker_emp = {
    damage_per_mana_pct = {"special_bonus_unique_invoker_1_oaa", "+"},
  },
  invoker_sun_strike = {
    damage = {"special_bonus_unique_invoker_2_oaa", "+"},
  },
  keeper_of_the_light_illuminate = {
    speed = {"special_bonus_unique_keeper_of_the_light_1_oaa", "%"},
  },
  lich_chain_frost = {
    jumps = {"special_bonus_unique_lich_1_oaa", "+"},
  },
  life_stealer_open_wounds = {
    AbilityCooldown = {"special_bonus_unique_lifestealer_1_oaa", "+"},
  },
  mars_arena_of_blood = {
    spear_damage = {"special_bonus_unique_mars_2_oaa", "+"},
  },
  mirana_leap = {
    leap_bonus_duration = {"special_bonus_unique_mirana_3_oaa", "+"},
  },
  muerta_dead_shot = {
    impact_slow_duration = {"special_bonus_unique_muerta_1_oaa", "+"},
  },
  muerta_pierce_the_veil = {
    AbilityCooldown = {"special_bonus_unique_muerta_2_oaa", "+"},
  },
  queenofpain_shadow_strike = {
    duration_damage = {"special_bonus_unique_queen_of_pain_4_oaa", "+"},
  },
  sandking_epicenter = {
    AbilityCastPoint = {"special_bonus_unique_sand_king_1_oaa", "+"},
  },
  skywrath_mage_arcane_bolt = {
    bolt_damage = {"special_bonus_unique_skywrath_1_oaa", "+"},
  },
  sniper_take_aim = {
    active_attack_range_bonus = {"special_bonus_unique_sniper_6_oaa", "+"},
  },
  spectre_haunt = {
    illusion_damage_outgoing = {"special_bonus_unique_spectre_4_oaa", "+"},
    tooltip_outgoing = {"special_bonus_unique_spectre_4_oaa", "+"},
  },
  spectre_haunt_single = {
    illusion_damage_outgoing = {"special_bonus_unique_spectre_4_oaa", "+"},
    tooltip_outgoing = {"special_bonus_unique_spectre_4_oaa", "+"},
  },
  storm_spirit_electric_vortex = {
    AbilityCooldown = {"special_bonus_unique_storm_spirit_2_oaa", "+"},
  },
  storm_spirit_overload = {
    overload_damage = {"special_bonus_unique_storm_spirit_1_oaa", "+"},
  },
  techies_sticky_bomb = {
    damage = {"special_bonus_unique_techies_1_oaa", "+"},
  },
  windrunner_powershot = {
    powershot_damage = {"special_bonus_unique_windranger_1_oaa", "+"},
  },
  winter_wyvern_cold_embrace = {
    heal_percentage = {"special_bonus_unique_winter_wyvern_1_oaa", "+"},
  },
  wisp_overcharge = {
    bonus_spell_amp = {"special_bonus_unique_wisp_1_oaa", "+"},
  },
  zuus_thundergods_wrath = {
    AbilityCooldown = {"special_bonus_unique_zeus_1_oaa", "+"},
  },
}

-- Avoid talent upgrades for stand-alone Facets, unit abilities and sub-abilities without kvs
-- Focus more on upgrades for scepter and shard abilities;
-- Upgrades for shard abilities should be at >= 20;
-- Upgrades for scepter abilities can be at >= 15;
-- Format:
-- ability_name = {
  -- kv_name_1 = {"modifier_aghanim_talent_oaa_x", "type", number},
  -- kv_name_2 = {"modifier_aghanim_talent_oaa_x", "type", number},
  -- ...
-- },
local abilities_with_aghanim_talents = {
  abaddon_aphotic_shield = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abaddon_borrowed_time_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abaddon_death_coil = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abaddon_frostmourne = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abyssal_underlord_atrophy_aura = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abyssal_underlord_dark_rift_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abyssal_underlord_firestorm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  abyssal_underlord_pit_of_malice = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_acid_spray = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_chemical_rage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_chemical_rage_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_corrosive_weaponry = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_unstable_concoction = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  alchemist_unstable_concoction_throw = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ancient_apparition_chilling_touch = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ancient_apparition_cold_feet = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ancient_apparition_death_rime = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ancient_apparition_ice_blast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ancient_apparition_ice_vortex = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  antimage_blink = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  antimage_counterspell = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  antimage_counterspell_ally = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  antimage_mana_break = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  antimage_mana_void = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  arc_warden_flux = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  arc_warden_magnetic_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  arc_warden_spark_wraith = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  arc_warden_tempest_double = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  axe_battle_hunger = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  axe_berserkers_call = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  axe_counter_helix = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  axe_culling_blade = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bane_brain_sap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bane_enfeeble = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bane_fiends_grip = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bane_nightmare = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  batrider_firefly = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  batrider_flamebreak = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  batrider_flaming_lasso = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  batrider_sticky_napalm_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  beastmaster_call_of_the_wild_boar_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  beastmaster_call_of_the_wild_hawk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  beastmaster_inner_beast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  beastmaster_primal_roar = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  beastmaster_wild_axes = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bloodseeker_blood_bath = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bloodseeker_blood_mist = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bloodseeker_bloodrage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bloodseeker_rupture = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bloodseeker_thirst = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bounty_hunter_jinada = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bounty_hunter_shuriken_toss = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bounty_hunter_track = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bounty_hunter_wind_walk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bounty_hunter_wind_walk_ally = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  brewmaster_cinder_brew = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  brewmaster_drunken_brawler = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  brewmaster_primal_split = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  brewmaster_thunder_clap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_bristleback = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_bristleback_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_hairball = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_quill_spray = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_scepter_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_viscous_nasal_goo = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  bristleback_warpath = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  broodmother_incapacitating_bite = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  broodmother_incapacitating_bite_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  broodmother_insatiable_hunger = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  broodmother_spawn_spiderlings_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  broodmother_spin_web = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  centaur_double_edge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  centaur_hoof_stomp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  centaur_return = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  centaur_stampede = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chaos_knight_chaos_bolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chaos_knight_chaos_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chaos_knight_phantasm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chaos_knight_reality_rift = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chen_divine_favor = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chen_divine_favor_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chen_hand_of_god = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chen_holy_persuasion = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  chen_penitence = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_bone_and_arrow = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_burning_army = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_death_pact = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_strafe = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_tar_bomb = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  clinkz_wind_walk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  crystal_maiden_brilliance_aura = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  crystal_maiden_brilliance_aura_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  crystal_maiden_crystal_nova = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  crystal_maiden_freezing_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  crystal_maiden_frostbite = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_seer_ion_shell = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_seer_surge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_seer_vacuum = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_seer_wall_of_replica = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_willow_bedlam = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_willow_bramble_maze = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_willow_cursed_crown = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_willow_shadow_realm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dark_willow_terrorize = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dawnbreaker_celestial_hammer = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dawnbreaker_fire_wreath = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dawnbreaker_luminosity = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dawnbreaker_solar_guardian = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dazzle_bad_juju = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dazzle_poison_touch = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dazzle_shadow_wave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dazzle_shallow_grave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  death_prophet_carrion_swarm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  death_prophet_exorcism = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  death_prophet_silence = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  death_prophet_spirit_siphon = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  disruptor_glimpse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  disruptor_kinetic_fence = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  disruptor_kinetic_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  disruptor_static_storm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  disruptor_thunder_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  doom_bringer_devour = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  doom_bringer_doom = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  doom_bringer_infernal_blade = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  doom_bringer_scorched_earth = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dragon_knight_breathe_fire = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dragon_knight_dragon_blood = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dragon_knight_dragon_tail = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dragon_knight_elder_dragon_form = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  dragon_knight_fireball = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_frost_arrows = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_marksmanship = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_multishot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_trueshot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_vantage_point = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  drow_ranger_wave_of_silence = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_boulder_smash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_geomagnetic_grip = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_magnetize = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_petrify = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_rolling_boulder = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earth_spirit_stone_caller = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earthshaker_aftershock = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earthshaker_echo_slam = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earthshaker_enchant_totem = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  earthshaker_fissure = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  elder_titan_ancestral_spirit = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  elder_titan_earth_splitter = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  elder_titan_echo_stomp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  elder_titan_innate_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  elder_titan_natural_order = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  electrician_cleansing_shock_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  electrician_electric_shield_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  electrician_energy_absorption_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  electrician_static_grip_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_activate_fire_remnant = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_fire_remnant = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_flame_guard = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_immolation = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_searing_chains = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ember_spirit_sleight_of_fist = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enchantress_enchant = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enchantress_impetus = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enchantress_innate_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enchantress_natures_attendants = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enchantress_untouchable = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_black_hole = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_demonic_conversion = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_demonic_conversion_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_event_horizon = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_gravity_well = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_malefice = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  enigma_midnight_pulse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_chronosphere = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_distortion_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_time_dilation = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_time_lock_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_time_walk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  faceless_void_time_zone = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  furion_force_of_nature = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  furion_sprout = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  furion_teleportation = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  furion_wrath_of_nature = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  grimstroke_dark_artistry = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  grimstroke_ink_creature = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  grimstroke_soul_chain = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  grimstroke_spirit_walk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  gyrocopter_call_down = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  gyrocopter_flak_cannon = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  gyrocopter_homing_missile = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  gyrocopter_rocket_barrage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  hoodwink_acorn_shot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  hoodwink_bushwhack = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  hoodwink_mistwoods_wayfarer = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  hoodwink_scurry = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  hoodwink_sharpshooter = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  huskar_berserkers_blood = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  huskar_burning_spear = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  huskar_inner_fire = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  huskar_life_break = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_alacrity = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_chaos_meteor = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_cold_snap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_deafening_blast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_emp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_exort = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_forge_spirit = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_forge_spirit_melting_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_ghost_walk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_ice_wall = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_quas = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_sun_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_tornado = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  invoker_wex = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  jakiro_dual_breath = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  jakiro_ice_path = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  jakiro_liquid_fire = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  jakiro_liquid_ice = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  jakiro_macropyre = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  juggernaut_blade_dance = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  juggernaut_blade_fury = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  juggernaut_duelist = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  juggernaut_healing_ward = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  juggernaut_omni_slash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_blinding_light = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_chakra_magic = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_illuminate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_radiant_bind = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_recall = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_spirit_form = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  keeper_of_the_light_will_o_wisp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  kunkka_ghostship = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  kunkka_tidebringer = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  kunkka_torrent = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  kunkka_x_marks_the_spot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  legion_commander_duel = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  legion_commander_moment_of_courage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  legion_commander_overwhelming_odds = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  legion_commander_press_the_attack = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  leshrac_defilement = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  leshrac_diabolic_edict = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  leshrac_lightning_storm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  leshrac_pulse_nova = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  leshrac_split_earth_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lich_chain_frost = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lich_frost_nova = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lich_frost_shield = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lich_sinister_gaze = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_feast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_ghoul_frenzy = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_infest = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_open_wounds = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_rage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  life_stealer_unfettered = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lina_combustion = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lina_dragon_slave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lina_fiery_soul = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lina_laguna_blade = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lina_light_strike_array = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lion_finger_of_death = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lion_impale = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lion_mana_drain = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lion_voodoo = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_savage_roar = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_savage_roar_bear = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_spirit_bear = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_spirit_bear_demolish = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_spirit_bear_entangle = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_spirit_link = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lone_druid_true_form = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  luna_eclipse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  luna_lucent_beam = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  luna_lunar_blessing = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  luna_lunar_orbit = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  luna_moon_glaive = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_feral_impulse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_feral_movement_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_howl = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_shapeshift = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_summon_wolves = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  lycan_wolf_bite = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  magnataur_empower = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  magnataur_horn_toss = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  magnataur_reverse_polarity = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  magnataur_shockwave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  magnataur_skewer = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  marci_bodyguard = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  marci_companion_run = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  marci_grapple = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  marci_guardian = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  marci_unleash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mars_arena_of_blood = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mars_bulwark = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mars_gods_rebuke = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mars_spear = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  medusa_cold_blooded = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  medusa_gorgon_grasp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  medusa_mystic_snake = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  medusa_split_shot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  medusa_stone_gaze = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  meepo_divided_we_stand = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  meepo_earthbind = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  meepo_poof = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  meepo_ransack = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  meepo_together_we_stand_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mirana_arrow_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mirana_invis = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mirana_leap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mirana_solar_flare = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  mirana_starfall = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  monkey_king_boundless_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  monkey_king_jingu_mastery = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  monkey_king_primal_spring = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  monkey_king_tree_dance = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  monkey_king_wukongs_command_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  morphling_adaptive_strike_agi = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  morphling_adaptive_strike_str = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  morphling_replicate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  morphling_waveform = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  muerta_dead_shot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  muerta_gunslinger = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  muerta_pierce_the_veil = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  muerta_the_calling = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  naga_siren_deluge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  naga_siren_ensnare = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  naga_siren_mirror_image = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  naga_siren_rip_tide = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  naga_siren_song_of_the_siren = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  necrolyte_death_pulse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  necrolyte_ghost_shroud = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  necrolyte_heartstopper_aura = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  necrolyte_reapers_scythe = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  necrolyte_sadist = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_dark_lord_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_frenzy = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_necromastery = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_requiem = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_shadowraze1 = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_shadowraze2 = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nevermore_shadowraze3 = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  night_stalker_crippling_fear = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  night_stalker_darkness = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  night_stalker_hunter_in_the_night = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  night_stalker_void = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nyx_assassin_burrow = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nyx_assassin_impale = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nyx_assassin_jolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nyx_assassin_spiked_carapace = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  nyx_assassin_vendetta = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  obsidian_destroyer_arcane_orb_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  obsidian_destroyer_astral_imprisonment = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  obsidian_destroyer_equilibrium = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  obsidian_destroyer_sanity_eclipse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ogre_magi_bloodlust = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ogre_magi_fireblast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ogre_magi_ignite = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ogre_magi_multicast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  omniknight_degen_aura = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  omniknight_guardian_angel = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  omniknight_hammer_of_purity = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  omniknight_martyr = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  omniknight_purification = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  oracle_false_promise = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  oracle_fates_edict = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  oracle_fortunes_end = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  oracle_purifying_flames = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pangolier_gyroshell = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pangolier_lucky_shot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pangolier_shield_crash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pangolier_swashbuckle = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_assassin_blur = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_assassin_coup_de_grace = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_assassin_immaterial = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_assassin_phantom_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_assassin_stifling_dagger = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_lancer_doppelwalk = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_lancer_juxtapose = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_lancer_phantom_edge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phantom_lancer_spirit_lance = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phoenix_fire_spirits = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phoenix_icarus_dive = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phoenix_launch_fire_spirit = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phoenix_sun_ray = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  phoenix_supernova = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  primal_beast_onslaught = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  primal_beast_pulverize = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  primal_beast_rock_throw = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  primal_beast_trample = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  primal_beast_uproar = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  puck_dream_coil = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  puck_illusory_orb = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  puck_phase_shift = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  puck_waning_rift = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pudge_dismember = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pudge_flesh_heap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pudge_innate_graft_flesh = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pudge_meat_hook = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pudge_rot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pugna_decrepify = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pugna_life_drain = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pugna_nether_blast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pugna_nether_ward = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  pugna_nether_ward_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  queenofpain_blink = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  queenofpain_scream_of_pain = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  queenofpain_shadow_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  queenofpain_sonic_wave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rattletrap_battery_assault = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rattletrap_hookshot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rattletrap_power_cogs = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rattletrap_rocket_flare = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  razor_eye_of_the_storm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  razor_plasma_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  razor_static_link = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  razor_unstable_current = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  riki_backstab = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  riki_blink_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  riki_innate_backstab = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  riki_smoke_screen = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  riki_tricks_of_the_trade = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rubick_arcane_supremacy = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rubick_fade_bolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rubick_spell_steal = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  rubick_telekinesis = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sandking_burrowstrike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sandking_caustic_finale = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sandking_epicenter = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sandking_sand_storm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sandking_scorpion_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_demonic_cleanse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_demonic_purge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_disruption = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_disseminate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_menace = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_demon_shadow_poison = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_shaman_ether_shock = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_shaman_mass_serpent_ward = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_shaman_mass_serpent_ward_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_shaman_shackles = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shadow_shaman_voodoo = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_chakram = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_chakram_2 = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_exposure_therapy = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_flamethrower = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_reactive_armor = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_timber_chain = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  shredder_whirling_death = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  silencer_curse_of_the_silent = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  silencer_glaives_of_wisdom = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  silencer_global_silence = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  silencer_last_word = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_bone_guard = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_hellfire_blast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_mortal_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_reincarnation = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_spectral_blade = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skeleton_king_vampiric_spirit = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skywrath_mage_ancient_seal = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skywrath_mage_arcane_bolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skywrath_mage_concussive_shot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skywrath_mage_mystic_flare = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  skywrath_mage_ruin_and_restoration = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slardar_amplify_damage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slardar_bash_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slardar_seaborn_sentinel = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slardar_slithereen_crush = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slardar_sprint = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slark_barracuda = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slark_dark_pact = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slark_essence_shift = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slark_pounce = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  slark_shadow_dance = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  snapfire_firesnap_cookie = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  snapfire_lil_shredder = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  snapfire_mortimer_kisses = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  snapfire_scatterblast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sniper_assassinate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sniper_headshot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sniper_keen_scope_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sniper_shrapnel = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sniper_take_aim = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_dash_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_flurry_of_blows_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_ki_attraction = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_momentum_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_polarizing_palm_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sohei_wholeness_of_body_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spectre_desolate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spectre_dispersion = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spectre_haunt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spectre_haunt_single = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spectre_spectral_dagger = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spirit_breaker_bulldoze = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spirit_breaker_charge_of_darkness = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spirit_breaker_greater_bash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  spirit_breaker_nether_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  storm_spirit_ball_lightning = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  storm_spirit_electric_vortex = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  storm_spirit_overload = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  storm_spirit_static_remnant = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sven_gods_strength = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sven_great_cleave = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sven_storm_bolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  sven_warcry = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  techies_land_mines = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  techies_reactive_tazer = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  techies_sticky_bomb = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  techies_suicide = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  templar_assassin_meld = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  templar_assassin_psi_blades = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  templar_assassin_psionic_trap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  templar_assassin_refraction = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  templar_assassin_trap_teleport = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_conjure_image = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_conjure_image_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_dark_unity = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_demon_zeal = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_metamorphosis = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_reflection = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  terrorblade_sunder = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tidehunter_anchor_smash = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tidehunter_gush = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tidehunter_kraken_shell = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tidehunter_ravage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinker_defense_matrix = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinker_eureka = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinker_march_of_the_machines = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinkerer_laser_contraption = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinkerer_laser_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinkerer_oil_spill = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tinkerer_smart_missiles = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_avalanche = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_craggy_exterior = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_grow = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_grow_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_toss = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_toss_tree = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_tree_channel = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tiny_tree_grab = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  treant_eyes_in_the_forest = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  treant_leech_seed = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  treant_living_armor = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  treant_natures_grasp = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  treant_overgrowth = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  troll_warlord_battle_trance = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  troll_warlord_berserkers_rage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  troll_warlord_fervor = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  troll_warlord_whirling_axes_melee = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  troll_warlord_whirling_axes_ranged = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_bitter_chill = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_drinking_buddies = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_ice_shards = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_snowball = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_tag_team = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  tusk_walrus_punch = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  undying_ceaseless_dirge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  undying_decay = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  undying_flesh_golem = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  undying_soul_rip = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  undying_tombstone = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ursa_earthshock = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ursa_enrage = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ursa_fury_swipes = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  ursa_overpower = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  vengefulspirit_command_aura_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  vengefulspirit_magic_missile = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  vengefulspirit_nether_swap = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  vengefulspirit_wave_of_terror = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  venomancer_noxious_plague = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  venomancer_plague_ward = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  venomancer_poison_sting = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  venomancer_venomous_gale = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  viper_corrosive_skin = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  viper_nethertoxin = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  viper_poison_attack = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  viper_viper_strike = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  visage_grave_chill = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  visage_gravekeepers_cloak = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  visage_soul_assumption = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  visage_summon_familiars = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  void_spirit_aether_remnant = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  void_spirit_astral_step = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  void_spirit_dissimilate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  void_spirit_resonant_pulse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  warlock_fatal_bonds = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  warlock_rain_of_chaos = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  warlock_shadow_word = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  warlock_upheaval = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  weaver_geminate_attack = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  weaver_shukuchi = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  weaver_the_swarm = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  weaver_time_lapse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  windrunner_focusfire = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  windrunner_powershot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  windrunner_shackleshot = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  windrunner_windrun = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  winter_wyvern_arctic_burn = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  winter_wyvern_cold_embrace = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  winter_wyvern_innate_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  winter_wyvern_splinter_blast = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  winter_wyvern_winters_curse = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  wisp_overcharge = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  wisp_relocate = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  wisp_spirits = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  wisp_tether = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  witch_doctor_death_ward_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  witch_doctor_maledict = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  witch_doctor_paralyzing_cask = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  witch_doctor_voodoo_restoration = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  witch_doctor_voodoo_switcheroo_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_arc_lightning = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_cloud_oaa = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_heavenly_jump = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_lightning_bolt = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_static_field = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
  zuus_thundergods_wrath = {
    kv_we_modify = {"modifier_aghanim_talent_oaa_10", "+", 0},
  },
}

---------------------------------------------------------------------------------------------------

modifier_talent_tracker_oaa = class({})

function modifier_talent_tracker_oaa:IsHidden()
  return true
end

function modifier_talent_tracker_oaa:IsPurgable()
  return false
end

function modifier_talent_tracker_oaa:RemoveOnDeath()
  return false
end

function modifier_talent_tracker_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

function modifier_talent_tracker_oaa:GetModifierOverrideAbilitySpecial(keys)
  local parent = self:GetParent()
  if not keys.ability or not keys.ability_special_value then
    return 0
  end

  local ability_name = keys.ability:GetAbilityName()

  if abilities_with_custom_talents[ability_name] then
    local keyvalues_to_upgrade = abilities_with_custom_talents[ability_name]
    for k, v in pairs(keyvalues_to_upgrade) do
      local custom_talent = parent:FindAbilityByName(v[1])
      if keys.ability_special_value == k and custom_talent and custom_talent:GetLevel() > 0 then
        return 1
      end
    end
  end

  if abilities_with_aghanim_talents[ability_name] then
    local keyvalues_to_upgrade = abilities_with_aghanim_talents[ability_name]
    for k, v in pairs(keyvalues_to_upgrade) do
      local custom_talent = parent:HasModifier(v[1])
      if keys.ability_special_value == k and custom_talent then
        return 1
      end
    end
  end

  return 0
end

function modifier_talent_tracker_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local parent = self:GetParent()
  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)
  local ability_name = keys.ability:GetAbilityName()

  if not abilities_with_custom_talents[ability_name] and not abilities_with_aghanim_talents[ability_name] then
    return value
  end

  local modified_value = value
  local keyvalues_to_upgrade = abilities_with_custom_talents[ability_name]
  if keyvalues_to_upgrade then
    for k, v in pairs(keyvalues_to_upgrade) do
      local custom_talent = parent:FindAbilityByName(v[1])
      if keys.ability_special_value == k and custom_talent and custom_talent:GetLevel() > 0 then
        local talent_type = v[2]
        local talent_value = custom_talent:GetSpecialValueFor("value")
        if talent_type == "+" then
          modified_value = value + talent_value
        elseif talent_type == "-" then
          modified_value = value - talent_value
        elseif talent_type == "x" or talent_type == "*" then
          modified_value = value * talent_value
        elseif talent_type == "/" and talent_value ~= 0 then
          modified_value = value / talent_value
        elseif talent_type == "%" then
          modified_value = value * (1 + talent_value / 100)
        end
      end
    end
  end

  local keyvalues_to_upgrade2 = abilities_with_aghanim_talents[ability_name]
  if keyvalues_to_upgrade2 then
    for k, v in pairs(keyvalues_to_upgrade2) do
      local custom_talent = parent:HasModifier(v[1])
      if keys.ability_special_value == k and custom_talent then
        local talent_type = v[2]
        local talent_value = v[3]
        if talent_type == "+" then
          modified_value = modified_value + talent_value
        elseif talent_type == "-" then
          modified_value = modified_value - talent_value
        elseif talent_type == "x" or talent_type == "*" then
          modified_value = modified_value * talent_value
        elseif talent_type == "/" and talent_value ~= 0 then
          modified_value = modified_value / talent_value
        elseif talent_type == "%" then
          modified_value = modified_value * (1 + talent_value / 100)
        end
      end
    end
  end

  return modified_value
end

---------------------------------------------------------------------------------------------------

modifier_aghanim_talent_oaa_10 = class({})

function modifier_aghanim_talent_oaa_10:IsHidden()
  return true
end

function modifier_aghanim_talent_oaa_10:IsPurgable()
  return false
end

function modifier_aghanim_talent_oaa_10:RemoveOnDeath()
  return false
end

function modifier_aghanim_talent_oaa_10:OnCreated()
  if not IsServer() then return end

  local parent = self:GetParent()
  local player = PlayerResource:GetPlayer(parent:GetPlayerID())

  if player then
    CustomGameEventManager:Send_ServerToPlayer(player, "oaa_aghanim_talent_status_changed", {})
  end
end

function modifier_aghanim_talent_oaa_10:OnDestroy()
  if not IsServer() then return end

  local parent = self:GetParent()
  local player = PlayerResource:GetPlayer(parent:GetPlayerID())

  if player then
    CustomGameEventManager:Send_ServerToPlayer(player, "oaa_aghanim_talent_status_changed", {})
  end
end

modifier_aghanim_talent_oaa_15 = modifier_aghanim_talent_oaa_10
modifier_aghanim_talent_oaa_20 = modifier_aghanim_talent_oaa_10
modifier_aghanim_talent_oaa_25 = modifier_aghanim_talent_oaa_10
