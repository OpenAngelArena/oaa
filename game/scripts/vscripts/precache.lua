g_ItemPrecache = {
  --"item_blood_sword",
  "item_bubble_orb_1",
  "item_butterfly_oaa",
  "item_craggy_coat_oaa",
  "item_dagger_of_moriah_1",
  "item_dagon_oaa",
  "item_demon_stone",
  "item_devastator_3",
  "item_dispel_orb_1",
  --"item_dragon_scale_oaa",
  "item_elixier_burst",
  "item_elixier_hybrid",
  "item_elixier_sustain",
  "item_enrage_crystal_1",
  --"item_eternal_shroud_oaa",
  "item_far_sight",
  "item_giant_form",
  "item_greater_phase_boots",
  "item_greater_tranquil_boots",
  "item_heart_oaa_1",
  "item_heart_transplant",
  "item_lucience",
  "item_martyrs_mail_1",
  --"item_meteor_hammer_1",
  "item_pull_staff",
  --"item_reflex_core",
  "item_regen_crystal_1",
  --"item_rune_breaker_oaa",
  --"item_sacred_skull",
  "item_satanic_core",
  "item_shield_staff",
  "item_siege_mode",
  --"item_silver_staff",
  "item_sonic",
  "item_stoneskin",
  "item_trumps_fists_1",
  --"item_travel_boots_oaa",
  "item_vampire",
}

g_UnitPrecache = {
  "dota_fountain",
  "npc_dota_demon_stone_demon",
  "npc_dota_monkey_clone_oaa",
  "npc_dota_tinkerer_keen_node",
  --"npc_dota_visage_familiar", -- should be precached together with Visage
  --"npc_dota_witch_doctor_death_ward_oaa", -- should be precached together with Witch Doctor
  "npc_dota_hero_sohei",
  "npc_dota_hero_electrician",
  --"npc_azazel_tower_watch",
  "npc_dota_boss_simple_1", -- Skeleton boss
  "npc_dota_boss_simple_5", -- Cleave boss
  "npc_dota_boss_simple_7", -- Dire Creep boss
  --"npc_dota_boss_tier_1", -- Roshan (precached with normal dota)
  "npc_dota_boss_twin",
  "npc_dota_boss_twin_dumb",
  "npc_dota_boss_simple_2", -- Bear boss
  "npc_dota_boss_shielder",
  "npc_dota_boss_charger",
  "npc_dota_boss_charger_pillar",
  "npc_dota_boss_carapace", -- Weaver boss
  "npc_dota_boss_slime",
  "npc_dota_boss_swiper",  -- Sven boss
  "npc_dota_boss_spiders", -- Alchemist boss
  "npc_dota_creature_magma_boss",
  "npc_dota_magma_boss_volcano",
  "npc_dota_creature_ogre_tank_boss",
  "npc_dota_creature_ogre_seer",
  "npc_dota_creature_lycan_boss",
  "npc_dota_creature_dire_hound",
  "npc_dota_creature_dire_hound_boss",
  "npc_dota_creature_werewolf",
  "npc_dota_hero_bloodseeker", -- For Lycan Boss Wolf transformation
  "npc_dota_boss_tier_4", -- Killer Tomato
  "npc_dota_boss_tier_6", -- Spooky Ghost
  "npc_dota_creature_temple_guardian",
  "npc_dota_creature_temple_guardian_spawner",
  "npc_dota_creature_spider_boss",
  "npc_dota_boss_spiders_spiderball",
  "npc_dota_boss_spiders_spider",
  "npc_dota_boss_stopfightingyourself",
  "npc_dota_boss_wanderer_1",
  "npc_dota_boss_wanderer_2",
  "npc_dota_boss_wanderer_3",
  "npc_dota_boss_grendel",
}

g_ModelPrecache = {
  "models/items/upgrade_1.vmdl",
  "models/items/upgrade_2.vmdl",
  "models/items/upgrade_3.vmdl",
  "models/items/upgrade_4.vmdl",
}

g_ParticlePrecache = {
  "particles/items/upgrade_1.vpcf",
  "particles/items/upgrade_2.vpcf",
  "particles/items/upgrade_3.vpcf",
  "particles/items/upgrade_4.vpcf",
  "particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf",
  "particles/units/heroes/hero_pugna/pugna_netherblast.vpcf",
  "particles/items/phase_splinter_impact_model.vpcf", -- Cleave Spark particle
  "particles/units/heroes/hero_treant/treant_leech_seed_damage_glow.vpcf", -- Midas Spark particle
  -- Carapace Boss
  "particles/econ/items/antimage/antimage_ti7_golden/antimage_blink_start_ti7_golden_smoke.vpcf",
  "particles/econ/items/pudge/pudge_ti6_immortal/pudge_meathook_witness_impact_ti6.vpcf",
  "particles/units/heroes/hero_stormspirit/stormspirit_ball_lightning_sphere.vpcf",
  "particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_explosion.vpcf",
  "particles/units/heroes/hero_pugna/pugna_ward_sphereinner.vpcf",
  "particles/units/heroes/hero_crystalmaiden/maiden_base_attack_trail_c.vpcf",
  "particles/units/heroes/hero_crystalmaiden/maiden_base_attack_trail.vpcf",
  "particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf",
}

g_ParticleFolderPrecache = {
  "particles/capture_point_ring",
  --"particles/econ/items", -- Precache all hero cosmetics
  "particles/items",
  "particles/items/dagger_of_moriah",
  "particles/items/devastator",
  "particles/items/dispel_orb",
  "particles/items/elixiers",
  "particles/items/enrage_crystal",
  "particles/items/heart_transplant",
  --"particles/items/reflection_shard",
  "particles/items/regen_crystal",
  "particles/items/sacred_skull",
  "particles/items/trumps_fists",
  "particles/items/vampire",
}

g_SoundPrecache = {
  "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts", -- For Ogre Boss kill sound
  "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", -- Midas Spark sounds
  "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", -- For Explosive Death modifier
  -- Ambient sounds
  --"soundevents/ambient/doors.vsndevts",
  "soundevents/music/music.vsndevts",
  -- Gameplay sounds
  "soundevents/game_sounds_creeps.vsndevts",
  "soundevents/game_sounds_items.vsndevts",
  "soundevents/items/oaa_items_sfx.vsndevts",
  "soundevents/abilities/fountain_attack.vsndevts",
  -- Boss sounds
  "soundevents/bosses/charger.vsndevts",
  "soundevents/bosses/game_sounds_dungeon_enemies.vsndevts",
  "soundevents/bosses/magma_boss.vsndevts",
}
