--[[ Extension functions for CDOTA_BaseNPC

-HasLearnedAbility(abilityName)
  Checks if the unit has at least one point in ability abilityName.
  Primarily for checking if talents have been learned.
--]]

-- This file is also loaded on client
-- but client doesn't have FindAbilityByName
if IsServer() then
  function CDOTA_BaseNPC:HasLearnedAbility(abilityName)
    local ability = self:FindAbilityByName(abilityName)
    if ability then
      return ability:GetLevel() > 0
    end
    return false
  end

  function CDOTA_BaseNPC:GetValueChangedByStatusResistance(value)
    if self and value then
      local reduction = self:GetStatusResistance()

      -- Capping max status resistance
      if reduction >= 1 then
        return value*0.01
      end

      return value*(1-reduction)
    end
  end

  function CDOTA_BaseNPC:AbsolutePurge()
    local undispellable_item_buffs = {
      "modifier_black_king_bar_immune",
      "modifier_item_hood_of_defiance_barrier",
      "modifier_item_pipe_barrier",
      "modifier_item_shadow_amulet_fade",
      "modifier_item_invisibility_edge_windwalk",
      "modifier_item_silver_edge_windwalk",
      "modifier_rune_invis",
      "modifier_item_blade_mail_reflect",
      "modifier_item_lotus_orb_active",
      "modifier_item_sphere_target",               -- Linken's Sphere transferred buff
      "modifier_item_martyrs_mail_martyr_active",  -- Martyr's Mail buff
      "modifier_item_stoneskin_stone_armor",       -- Stoneskin Armor buff
      "modifier_item_ghost_king_bar_active",       -- Ghost King Bar buff
      "modifier_item_preemptive_purge",            -- Dispel Orb buff
      "modifier_item_preemptive_damage_reduction", -- Reduction Orb buff
    }

    local undispellable_item_debuffs = {
      "modifier_item_skadi_slow",
      "modifier_heavens_halberd_debuff",        -- Heaven's Halberd debuff
      "modifier_silver_edge_debuff",            -- Silver Edge debuff
      "modifier_item_nullifier_mute",           -- Nullifier debuff
      "modifier_item_trumps_fists_frostbite",   -- Blade of Judecca debuff
      "modifier_item_silver_staff_debuff",      -- Silver Staff debuff
    }

    local undispellable_ability_debuffs = {
      "modifier_ice_blast",
      "modifier_axe_berserkers_call",
      "modifier_bloodseeker_rupture",
      "modifier_bristleback_quill_spray",       -- Quill Spray stacks
      "modifier_dazzle_bad_juju_armor",         -- Bad Juju stacks
      "modifier_doom_bringer_doom",
      "modifier_earthspirit_petrify",           -- Earth Spirit Enchant Remnant debuff
      "modifier_grimstroke_soul_chain",
      "modifier_huskar_burning_spear_debuff",   -- Burning Spear stacks
      "modifier_invoker_deafening_blast_disarm",
      "modifier_forged_spirit_melting_strike_debuff",
      "modifier_razor_static_link_debuff",
      "modifier_razor_eye_of_the_storm_armor",  -- Eye of the Storm stacks
      "modifier_sand_king_caustic_finale_orb",  -- Caustic Finale initial debuff
      "modifier_shadow_demon_purge_slow",
      "modifier_slardar_amplify_damage",        -- Corrosive Haze becomes undispellable with the talent
      "modifier_slark_pounce_leash",
      "modifier_tusk_walrus_punch_slow",
      "modifier_tusk_walrus_kick_slow",
      "modifier_ursa_fury_swipes_damage_increase",
      "modifier_venomancer_poison_nova",
      "modifier_viper_viper_strike_slow",
      "modifier_maledict",
      "modifier_winter_wyvern_winters_curse_aura",
      "modifier_winter_wyvern_winters_curse",
      "modifier_windrunner_windrun_slow",
    }

    local undispellable_ability_buffs = {
      "modifier_axe_berserkers_call_armor",
      "modifier_bounty_hunter_wind_walk",
      "modifier_broodmother_insatiable_hunger",
      "modifier_centaur_stampede",
      "modifier_clinkz_wind_walk",
      "modifier_rattletrap_battery_assault",
      "modifier_dark_willow_shadow_realm_buff",
      "modifier_dazzle_shallow_grave",
      --"modifier_doom_bringer_devour",         -- There are no creeps in a duel, so removing this is dumb
      "modifier_doom_bringer_scorched_earth_effect_aura",
      "modifier_doom_bringer_scorched_earth_effect",
      "modifier_enchantress_natures_attendants",
      "modifier_gyrocopter_flak_cannon",
      "modifier_wisp_overcharge",
      "modifier_invoker_ghost_walk_self",
      "modifier_juggernaut_blade_fury",
      "modifier_kunkka_ghost_ship_damage_absorb",
      "modifier_kunkka_ghost_ship_damage_delay",
      "modifier_leshrac_diabolic_edict",        -- Removes only one instance
      "modifier_life_stealer_rage",
      "modifier_lone_druid_true_form_battle_cry",
      "modifier_luna_eclipse",
      "modifier_medusa_stone_gaze",
      "modifier_mirana_moonlight_shadow",
      "modifier_nyx_assassin_spiked_carapace",
      "modifier_nyx_assassin_vendetta",
      "modifier_omniknight_repel",              -- Heavenly Grace
      "modifier_pangolier_shield_crash_buff",
      "modifier_phantom_assassin_blur_active",
      "modifier_razor_static_link_buff",
      "modifier_razor_eye_of_the_storm",        -- Removes only one instance
      "modifier_slark_shadow_dance",
      "modifier_templar_assassin_refraction_absorb",
      "modifier_templar_assassin_refraction_damage",
      "modifier_ursa_enrage",
      "modifier_weaver_shukuchi",
      "modifier_winter_wyvern_cold_embrace",
      "modifier_windrunner_windrun_invis",
      "modifier_alpha_invisibility_oaa_buff",   -- Neutral Alpha Wolf invisibility buff
    }
    -- These are mostly transformation buffs, add them to the list above if they don't crash or break the ability and if fair
    local problematic_modifiers = {
      "modifier_abaddon_borrowed_time",         -- transformation modifier and an ultimate
      "modifier_oaa_borrowed_time_buff_caster", -- transformation modifier and an ultimate
      "modifier_abaddon_borrowed_time_damage_redirect",
      "modifier_alchemist_chemical_rage",       -- transformation modifier and an ultimate
      --"modifier_batrider_firefly",            -- Removes only one instance, bugs out the caster
      --"modifier_brewmaster_primal_split_duration", -- Coding nightmare
      --"modifier_bristleback_warpath",         -- Removing this breaks the ability
      "modifier_clinkz_death_pact_effect_oaa",  -- transformation modifier and an ultimate
      "modifier_clinkz_death_pact_oaa",         -- transformation modifier and an ultimate
      "modifier_death_prophet_exorcism",        -- transformation modifier and an ultimate
      --"modifier_dragon_knight_dragon_form",   -- transformation modifier and an ultimate, it shouldnt be removed if ability is at level 5
      --"modifier_lina_fiery_soul",             -- Removing this breaks the ability
      "modifier_lycan_shapeshift",              -- transformation modifier and an ultimate
      "modifier_lycan_shapeshift_speed",        -- transformation modifier and an ultimate
      "modifier_lone_druid_true_form",          -- transformation modifier and an ultimate
      --"modifier_medusa_mana_shield",
      --"modifier_monkey_king_quadruple_tap_counter", -- Jingu Mastery stacks
      --"modifier_morphling_replicate_timer",   -- Coding nightmare
      --"modifier_morphling_replicate_manager", -- Coding nightmare
      "modifier_night_stalker_darkness",        -- Nightstalker Dark Ascension (transformation modifier and an ultimate)
      --"modifier_nyx_assassin_burrow",         -- Bugs out the caster
      --"modifier_obsidian_destroyer_astral_imprisonment_prison",
      --"modifier_oracle_false_promise_timer",  -- Removing this can kill a hero right at the start of the duel
      "modifier_pangolier_gyroshell",           -- transformation modifier and an ultimate
      --"modifier_phoenix_fire_spirit_count",   -- Phoenix Fire Spirits buff on the caster
      "modifier_sand_king_epicenter",           -- transformation modifier and an ultimate
      --"modifier_shadow_demon_disruption",
      "modifier_sven_gods_strength",            -- transformation modifier and an ultimate
      "modifier_sven_gods_strength_child",      -- transformation modifier and an ultimate
      --"modifier_spectre_spectral_dagger_path",
      --"modifier_spectre_spectral_dagger",
      --"modifier_spectre_spectral_dagger_in_path",
      "modifier_terrorblade_metamorphosis",     -- transformation modifier
      "modifier_terrorblade_metamorphosis_transform_aura_applier",  -- transformation modifier
      "modifier_troll_warlord_battle_trance",   -- transformation modifier and an ultimate
      "modifier_undying_flesh_golem_plague_aura", -- transformation modifier and an ultimate
      "modifier_undying_flesh_golem",           -- transformation modifier and an ultimate
      --"modifier_windrunner_focusfire",
      "modifier_winter_wyvern_arctic_burn_flight", -- transformation modifier
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, undispellable_item_buffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_item_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_buffs)

    -- Dispel stuff
    local BuffsCreatedThisFrameOnly = false
    local RemoveExceptions = false              -- Offensive Strong Dispel (yes or no), can cause errors, crashes etc.
    local RemoveStuns = true                    -- Defensive Strong Dispel (yes or no)

    self:Purge(true, true, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
  end
end

-- On Server:
if CDOTA_BaseNPC then
  function CDOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end

  function CDOTA_BaseNPC:IsNeutralCreep( notAncient )
    local targetFlags = bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO )

    if notAncient then
      targetFlags = bit.bor( targetFlags, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS )
    end

    return ( UnitFilter( self, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, targetFlags, DOTA_TEAM_NEUTRALS ) == UF_SUCCESS and not self:IsControllableByAnyPlayer() )
  end

  function CDOTA_BaseNPC:IsOAABoss()
    return self:HasModifier("modifier_boss_resistance")
  end
end

-- On Client:
if C_DOTA_BaseNPC then
  function C_DOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end

  function C_DOTA_BaseNPC:IsNeutralCreep( notAncient )
    local targetFlags = bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO )

    if notAncient then
      targetFlags = bit.bor( targetFlags, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS )
    end

    return ( UnitFilter( self, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, targetFlags, DOTA_TEAM_NEUTRALS ) == UF_SUCCESS and not self:IsControllableByAnyPlayer() )
  end

  function C_DOTA_BaseNPC:IsOAABoss()
    return self:HasModifier("modifier_boss_resistance")
  end
end
