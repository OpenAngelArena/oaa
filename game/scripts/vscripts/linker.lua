--LinkLuaModifier("modifier_legacy_armor", "modifiers/modifier_legacy_armor.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom thinker, used for multiple things
LinkLuaModifier("modifier_oaa_thinker", "modifiers/modifier_oaa_thinker.lua", LUA_MODIFIER_MOTION_NONE)

-- Manual garbage collection for dead units
LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom Talent System (every hero has it)
LinkLuaModifier("modifier_talent_tracker_oaa", "components/abilities/custom_talent_system.lua", LUA_MODIFIER_MOTION_NONE)

-- Boss capture points
LinkLuaModifier("modifier_boss_capture_point", "modifiers/modifier_boss_capture_point.lua", LUA_MODIFIER_MOTION_NONE)

-- Vision providers, used for multiple things
LinkLuaModifier("modifier_provides_vision_oaa", "modifiers/modifier_provides_vision_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_vision_dummy_stuff", "modifiers/modifier_generic_vision_dummy_stuff.lua", LUA_MODIFIER_MOTION_NONE)

-- Capture Points
LinkLuaModifier("modifier_standard_capture_point", "modifiers/modifier_standard_capture_point.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_standard_capture_point_dummy_stuff", "modifiers/modifier_standard_capture_point_dummy_stuff.lua", LUA_MODIFIER_MOTION_NONE)

-- Wanderer buff
LinkLuaModifier("modifier_wanderer_boss_buff", "abilities/boss/wanderer/modifier_wanderer_boss_buff.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wanderer_team_buff", "abilities/boss/wanderer/modifier_wanderer_team_buff.lua", LUA_MODIFIER_MOTION_NONE)

-- Offside protection/penalty
LinkLuaModifier('modifier_is_in_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_onside_buff', 'modifiers/modifier_onside_buff.lua', LUA_MODIFIER_MOTION_NONE)

-- Core Points counter (every hero has it)
LinkLuaModifier("modifier_core_points_counter_oaa", "components/corepoints/core_points.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom Courier stuff
LinkLuaModifier("modifier_custom_courier_stuff", "components/courier/courier.lua", LUA_MODIFIER_MOTION_NONE)

-- Neutral Creeps buff (bottles etc.)
LinkLuaModifier("modifier_creep_loot", "modifiers/modifier_creep_loot.lua", LUA_MODIFIER_MOTION_NONE)

-- Duels
LinkLuaModifier("modifier_out_of_duel", "modifiers/modifier_out_of_duel.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duel_invulnerability", "modifiers/modifier_duel_invulnerability", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_duel_rune_hill', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_duel_rune_hill_enemy', 'modifiers/modifier_duel_rune_hill.lua', LUA_MODIFIER_MOTION_NONE)

-- Passive Experience
LinkLuaModifier("modifier_xpm_thinker", "modifiers/modifier_xpm_thinker.lua", LUA_MODIFIER_MOTION_NONE)

-- Passive Gold
LinkLuaModifier("modifier_oaa_passive_gpm", "components/gold/gold.lua", LUA_MODIFIER_MOTION_NONE)

-- Additional ability effects: TODO: Refactor this to be linked somewhere else
-- Requiem Fear duration manipulation and Requiem Fear immunity:
LinkLuaModifier("modifier_oaa_requiem_allowed", "modifiers/modifyabilitiesfilter/requiem_fear_manager.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_requiem_not_allowed", "modifiers/modifyabilitiesfilter/requiem_fear_manager.lua", LUA_MODIFIER_MOTION_NONE)
-- Time Dilation additional effect:
LinkLuaModifier("modifier_faceless_void_time_dilation_degen_oaa", "modifiers/modifyabilitiesfilter/time_dilation_degen.lua", LUA_MODIFIER_MOTION_NONE)
-- Natural Order magic resistance reduction correction:
LinkLuaModifier("modifier_elder_titan_natural_order_correction_oaa", "modifiers/modifyabilitiesfilter/natural_order_correction.lua", LUA_MODIFIER_MOTION_NONE)
-- Tidehunter custom Anchor Smash modifier for bosses
LinkLuaModifier("modifier_tidehunter_anchor_smash_oaa_boss", "modifiers/modifier_tidehunter_anchor_smash_oaa_boss.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom Wards Buttons
LinkLuaModifier("modifier_ward_invisibility", "modifiers/modifier_ward_invisibility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier('modifier_ward_invisibility_enemy', 'modifiers/modifier_ward_invisibility.lua', LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ui_custom_observer_ward_charges", "components/glyph/customwardbuttons.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ui_custom_sentry_ward_charges", "components/glyph/customwardbuttons.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom Scan
LinkLuaModifier("modifier_scan_true_sight_thinker", "modifiers/modifier_scan_true_sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_scan_thinker", "modifiers/modifier_oaa_scan_thinker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_oaa_scan_debuff", "modifiers/modifier_oaa_scan_thinker.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom Glyph
LinkLuaModifier("modifier_custom_glyph_knockback", "components/glyph/glyph.lua", LUA_MODIFIER_MOTION_HORIZONTAL)

-- ARDM modifiers
LinkLuaModifier("modifier_ardm", "modifiers/ardm/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ardm_disable_hero", "modifiers/ardm/modifier_ardm_disable_hero.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_legion_commander_duel_damage_oaa_ardm", "modifiers/ardm/modifier_legion_commander_duel_damage_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_silencer_int_steal_oaa_ardm", "modifiers/ardm/modifier_silencer_int_steal_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pudge_flesh_heap_oaa_ardm", "modifiers/ardm/modifier_pudge_flesh_heap_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_slark_essence_shift_oaa_ardm", "modifiers/ardm/modifier_slark_essence_shift_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_axe_armor_oaa_ardm", "modifiers/ardm/modifier_axe_armor_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrophos_regen_oaa_ardm", "modifiers/ardm/modifier_necrophos_regen_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_moonshard_consumed_oaa_ardm", "modifiers/ardm/modifier_moonshard_consumed_oaa_ardm.lua", LUA_MODIFIER_MOTION_NONE)

-- Custom hero skins
LinkLuaModifier("modifier_arcana_dbz", "modifiers/modifier_arcana_dbz.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcana_rockelec", "modifiers/modifier_arcana_rockelec.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_arcana_pepsi", "modifiers/modifier_arcana_pepsi.lua", LUA_MODIFIER_MOTION_NONE)

-- Global item modifiers:
LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)
-- Spell Lifesteal
LinkLuaModifier("modifier_item_spell_lifesteal_oaa", "modifiers/modifier_item_spell_lifesteal_oaa.lua", LUA_MODIFIER_MOTION_NONE)
-- Aura upgrader
LinkLuaModifier("modifier_aura_item_upgrade", "modifiers/modifier_aura_item_upgrade.lua", LUA_MODIFIER_MOTION_NONE)

-- Minimap icons (for creeps, capture points and bosses)
LinkLuaModifier("modifier_minimap", "modifiers/modifier_minimap", LUA_MODIFIER_MOTION_NONE)

-- Sparks
LinkLuaModifier("modifier_spark_gpm", "modifiers/sparks/modifier_spark_gpm.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spark_cleave", "modifiers/sparks/modifier_spark_cleave.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spark_midas", "modifiers/sparks/modifier_spark_midas.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spark_power", "modifiers/sparks/modifier_spark_power.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spark_power_effect", "modifiers/sparks/modifier_spark_power.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_spark_xp", "modifiers/sparks/modifier_spark_xp.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_spark_gold", "modifiers/sparks/modifier_spark_gold.lua", LUA_MODIFIER_MOTION_NONE)

-- Healing Shrines
LinkLuaModifier("modifier_shrine_oaa", "modifiers/modifier_shrine_oaa.lua", LUA_MODIFIER_MOTION_NONE)

-- Fun modifiers
LinkLuaModifier("modifier_any_damage_lifesteal_oaa", "modifiers/funmodifiers/modifier_any_damage_lifesteal_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aoe_radius_increase_oaa", "modifiers/funmodifiers/modifier_aoe_radius_increase_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blood_magic_oaa", "modifiers/funmodifiers/modifier_blood_magic_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_debuff_duration_oaa", "modifiers/funmodifiers/modifier_debuff_duration_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_echo_strike_oaa", "modifiers/funmodifiers/modifier_echo_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ham_oaa", "modifiers/funmodifiers/modifier_ham_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_no_cast_points_oaa", "modifiers/funmodifiers/modifier_no_cast_points_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_physical_immunity_oaa", "modifiers/funmodifiers/modifier_physical_immunity_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_pro_active_oaa", "modifiers/funmodifiers/modifier_pro_active_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_spell_block_oaa", "modifiers/funmodifiers/modifier_spell_block_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_troll_switch_oaa", "modifiers/funmodifiers/modifier_troll_switch_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hyper_experience_oaa", "modifiers/funmodifiers/modifier_hyper_experience_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_diarrhetic_oaa", "modifiers/funmodifiers/modifier_diarrhetic_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_rend_oaa", "modifiers/funmodifiers/modifier_rend_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_range_increase_oaa", "modifiers/funmodifiers/modifier_range_increase_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_healer_oaa", "modifiers/funmodifiers/modifier_healer_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_explosive_death_oaa", "modifiers/funmodifiers/modifier_explosive_death_oaa.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_no_health_bar_oaa", "modifiers/funmodifiers/modifier_no_health_bar_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_aggresive_oaa", "modifiers/funmodifiers/modifier_boss_aggresive_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brute_oaa", "modifiers/funmodifiers/modifier_brute_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_wisdom_oaa", "modifiers/funmodifiers/modifier_wisdom_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aghanim_oaa", "modifiers/funmodifiers/modifier_aghanim_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nimble_oaa", "modifiers/funmodifiers/modifier_nimble_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sorcerer_oaa", "modifiers/funmodifiers/modifier_sorcerer_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_any_damage_crit_oaa", "modifiers/funmodifiers/modifier_any_damage_crit_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hp_mana_switch_oaa", "modifiers/funmodifiers/modifier_hp_mana_switch_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_magus_oaa", "modifiers/funmodifiers/modifier_magus_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_brawler_oaa", "modifiers/funmodifiers/modifier_brawler_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_chaos_oaa", "modifiers/funmodifiers/modifier_chaos_oaa.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_double_multiplier_oaa", "modifiers/funmodifiers/modifier_double_multiplier_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hybrid_oaa", "modifiers/funmodifiers/modifier_hybrid_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_drunk_oaa", "modifiers/funmodifiers/modifier_drunk_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_any_damage_splash_oaa", "modifiers/funmodifiers/modifier_any_damage_splash_oaa.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_all_healing_amplify_oaa", "modifiers/funmodifiers/modifier_all_healing_amplify_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_bonus_armor_negative_magic_resist_oaa", "modifiers/funmodifiers/modifier_bonus_armor_negative_magic_resist_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_cursed_attack_oaa", "modifiers/funmodifiers/modifier_cursed_attack_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_no_brain_oaa", "modifiers/funmodifiers/modifier_no_brain_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_courier_kill_bonus_oaa", "modifiers/funmodifiers/modifier_courier_kill_bonus_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_true_sight_strike_oaa", "modifiers/funmodifiers/modifier_true_sight_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_mr_phys_weak_oaa", "modifiers/funmodifiers/modifier_mr_phys_weak_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_angel_oaa", "modifiers/funmodifiers/modifier_angel_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hero_anti_stun_oaa", "modifiers/funmodifiers/modifier_hero_anti_stun_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_roshan_power_oaa", "modifiers/funmodifiers/modifier_roshan_power_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_titan_soul_oaa", "modifiers/funmodifiers/modifier_titan_soul_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_glass_cannon_oaa", "modifiers/funmodifiers/modifier_glass_cannon_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_duelist_oaa", "modifiers/funmodifiers/modifier_duelist_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_killer_oaa", "modifiers/funmodifiers/modifier_boss_killer_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_octarine_soul_oaa", "modifiers/funmodifiers/modifier_octarine_soul_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_smurf_oaa", "modifiers/funmodifiers/modifier_smurf_oaa.lua", LUA_MODIFIER_MOTION_NONE)
