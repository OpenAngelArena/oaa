--[[ Extension functions for CDOTA_BaseNPC

-HasLearnedAbility(abilityName)
  Checks if the unit has at least one point in ability abilityName.
  Primarily for checking if talents have been learned.
--]]

-- This file is also loaded on client

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

  function CDOTA_BaseNPC:DispelUndispellableDebuffs()
    local undispellable_item_debuffs = {
      "modifier_heavens_halberd_debuff",               -- Heaven's Halberd debuff
      "modifier_item_bloodstone_drained",              -- Bloodstone drained debuff
      "modifier_item_nullifier_mute",                  -- Nullifier debuff
      "modifier_item_skadi_slow",
      "modifier_silver_edge_debuff",                   -- Silver Edge debuff
      -- custom:
      "modifier_greater_tranquils_tranquilize_debuff", -- Greater Tranquil Boots debuff
      "modifier_item_rune_breaker_oaa_debuff",         -- Rune Breaker debuff
      "modifier_item_silver_staff_debuff",             -- Silver Staff debuff
      "modifier_item_trumps_fists_frostbite",          -- Blade of Judecca debuff
    }

    local undispellable_ability_debuffs = {
      "modifier_axe_berserkers_call",
      "modifier_bloodseeker_rupture",
      "modifier_bristleback_quill_spray",       -- Quill Spray stacks
      "modifier_dazzle_bad_juju_armor",         -- Bad Juju stacks
      "modifier_doom_bringer_doom",
      "modifier_earthspirit_petrify",           -- Earth Spirit Enchant Remnant debuff
      "modifier_forged_spirit_melting_strike_debuff",
      "modifier_grimstroke_soul_chain",
      "modifier_huskar_burning_spear_debuff",   -- Burning Spear stacks
      "modifier_ice_blast",
      "modifier_invoker_deafening_blast_disarm",
      "modifier_maledict",
      "modifier_obsidian_destroyer_astral_imprisonment_prison",
      "modifier_razor_eye_of_the_storm_armor",  -- Eye of the Storm stacks
      "modifier_razor_static_link_debuff",
      "modifier_sand_king_caustic_finale_orb",  -- Caustic Finale initial debuff
      "modifier_shadow_demon_disruption",
      "modifier_shadow_demon_purge_slow",
      "modifier_shadow_demon_shadow_poison",
      "modifier_silencer_curse_of_the_silent",  -- Arcane Curse becomes undispellable with the talent
      "modifier_slardar_amplify_damage",        -- Corrosive Haze becomes undispellable with the talent
      "modifier_slark_pounce_leash",
      "modifier_treant_overgrowth",             -- Overgrowth becomes undispellable with the talent
      "modifier_tusk_walrus_kick_slow",
      "modifier_tusk_walrus_punch_slow",
      "modifier_ursa_fury_swipes_damage_increase",
      "modifier_venomancer_poison_nova",
      "modifier_viper_viper_strike_slow",
      "modifier_windrunner_windrun_slow",
      "modifier_winter_wyvern_winters_curse",
      "modifier_winter_wyvern_winters_curse_aura",
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, undispellable_item_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_debuffs)
  end

  function CDOTA_BaseNPC:AbsolutePurge()
    -- Remove undispellable debuffs first
    self:DispelUndispellableDebuffs()

    local undispellable_item_buffs = {
      "modifier_black_king_bar_immune",
      "modifier_item_blade_mail_reflect",
      "modifier_item_bloodstone_active",
      "modifier_item_book_of_shadows_buff",
      "modifier_item_hood_of_defiance_barrier",
      "modifier_item_invisibility_edge_windwalk",
      "modifier_item_lotus_orb_active",
      "modifier_item_pipe_barrier",
      "modifier_item_satanic_unholy",
      "modifier_item_shadow_amulet_fade",
      "modifier_item_silver_edge_windwalk",
      "modifier_item_sphere_target",                 -- Linken's Sphere transferred buff
      -- custom:
      "modifier_eternal_shroud_oaa_barrier",         -- Eternal Shroud active buff
      "modifier_item_butterfly_oaa_active",          -- Butterfly active buff
      "modifier_item_dagger_of_moriah_sangromancy",  -- Dagger of Moriah active buff
      "modifier_item_dispel_orb_active",             -- Dispel Orb buff
      "modifier_item_heart_oaa_active",              -- Heart active buff
      --"modifier_item_heart_transplant_buff",       -- Heart Transplant buff
      "modifier_item_martyrs_mail_martyr_active",    -- Martyr's Mail buff
      "modifier_item_reduction_orb_active",          -- Reduction Orb buff
      "modifier_item_reflex_core_invulnerability",   -- Reflex Core buff
      "modifier_item_regen_crystal_active",          -- Regen Crystal buff
      "modifier_satanic_core_unholy",                -- Satanic Core buff
      "modifier_item_spiked_mail_active_return",     -- Spiked Mail active buff
      "modifier_item_stoneskin_stone_armor",         -- Stoneskin Armor buff
      "modifier_item_vampire_active",                -- Vampire Fang active buff
      --"modifier_pull_staff_active_buff",           -- Pull Staff motion controller
      --"modifier_shield_staff_active_buff",         -- Force Shield Staff motion controller
      "modifier_shield_staff_barrier_buff",          -- Force Shield Staff buff
    }

    local undispellable_ability_buffs = {
      "modifier_axe_berserkers_call_armor",
      "modifier_bounty_hunter_wind_walk",
      "modifier_broodmother_insatiable_hunger",
      "modifier_centaur_stampede",
      "modifier_clinkz_wind_walk",
      "modifier_dark_willow_shadow_realm_buff",
      "modifier_dazzle_shallow_grave",
      "modifier_doom_bringer_scorched_earth_effect",
      "modifier_doom_bringer_scorched_earth_effect_aura",
      "modifier_enchantress_natures_attendants",
      "modifier_gyrocopter_flak_cannon",
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
      "modifier_oracle_false_promise_timer",
      "modifier_pangolier_shield_crash_buff",
      "modifier_phantom_assassin_blur_active",
      "modifier_phoenix_supernova_hiding",
      "modifier_rattletrap_battery_assault",
      "modifier_razor_eye_of_the_storm",        -- Removes only one instance
      "modifier_razor_static_link_buff",
      "modifier_skeleton_king_reincarnation_scepter_active", -- Wraith King Wraith Form
      "modifier_slark_shadow_dance",
      "modifier_templar_assassin_refraction_absorb",
      "modifier_templar_assassin_refraction_damage",
      "modifier_ursa_enrage",
      "modifier_weaver_shukuchi",
      "modifier_windrunner_windrun",
      "modifier_windrunner_windrun_invis",
      "modifier_winter_wyvern_cold_embrace",
      "modifier_wisp_overcharge",
      -- custom:
      "modifier_alpha_invisibility_oaa_buff",   -- Neutral Alpha Wolf invisibility buff
      "modifier_sohei_flurry_self",
    }

    local undispellable_rune_modifiers = {
      "modifier_rune_invis",
      "modifier_rune_hill_tripledamage",
      "modifier_rune_hill_super_sight",
      "modifier_fountain_invulnerability",
    }

    -- These are mostly transformation buffs, add them to the list above if they don't crash or break the ability and if fair
    local problematic_modifiers = { --luacheck: ignore problematic_modifiers
      "modifier_abaddon_borrowed_time",                 -- transformation modifier and an ultimate
      "modifier_abaddon_borrowed_time_damage_redirect", -- transformation modifier and an ultimate
      "modifier_alchemist_chemical_rage",               -- transformation modifier and an ultimate
      "modifier_batrider_firefly",                      -- Removes only one instance, bugs out the caster
      "modifier_brewmaster_primal_split_duration",      -- Coding nightmare
      "modifier_bristleback_warpath",                   -- Warpath stacks - removing this breaks the ability
      "modifier_clinkz_death_pact_effect_oaa",          -- transformation modifier and an ultimate
      "modifier_clinkz_death_pact_oaa",                 -- transformation modifier and an ultimate
      "modifier_death_prophet_exorcism",                -- transformation modifier and an ultimate
      "modifier_doom_bringer_devour",                   -- There are no creeps in most duel arenas, so removing this is dumb
      "modifier_dragon_knight_dragon_form",             -- transformation modifier and an ultimate, it shouldnt be removed if ability is at level 5
      "modifier_lina_fiery_soul",                       -- Fiery Soul stacks - removing this breaks the ability
      "modifier_lone_druid_true_form",                  -- transformation modifier and an ultimate
      "modifier_lycan_shapeshift",                      -- transformation modifier and an ultimate
      "modifier_lycan_shapeshift_speed",                -- transformation modifier and an ultimate
      "modifier_medusa_mana_shield",                    -- removing this seems pointless and maybe it creates issues
      "modifier_monkey_king_quadruple_tap_counter",     -- Jingu Mastery stacks on enemies, needs testing if it's a problem
      "modifier_morphling_replicate_manager",           -- Coding nightmare
      "modifier_morphling_replicate_timer",             -- Coding nightmare
      "modifier_night_stalker_darkness",                -- Nightstalker Dark Ascension (transformation modifier and an ultimate)
      "modifier_nyx_assassin_burrow",                   -- Bugs out the caster
      "modifier_oaa_borrowed_time_buff_caster",         -- transformation modifier and an ultimate
      "modifier_pangolier_gyroshell",                   -- transformation modifier and an ultimate
      "modifier_phoenix_fire_spirit_count",             -- Phoenix Fire Spirits buff on the caster
      "modifier_sand_king_epicenter",                   -- transformation modifier and an ultimate
      "modifier_sven_gods_strength",                    -- transformation modifier and an ultimate
      "modifier_sven_gods_strength_child",              -- transformation modifier and an ultimate
      "modifier_terrorblade_metamorphosis",             -- transformation modifier
      "modifier_terrorblade_metamorphosis_transform_aura_applier",  -- transformation modifier
      "modifier_troll_warlord_battle_trance",           -- transformation modifier and an ultimate
      "modifier_undying_flesh_golem",                   -- transformation modifier and an ultimate
      "modifier_undying_flesh_golem_plague_aura",       -- transformation modifier and an ultimate
      "modifier_windrunner_focusfire",                  -- needs testing if it's a problem
      "modifier_winter_wyvern_arctic_burn_flight",      -- transformation modifier
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, undispellable_item_buffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_buffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_rune_modifiers)

    -- Dispel bools
    local BuffsCreatedThisFrameOnly = false
    local RemoveExceptions = false              -- Offensive Strong Dispel (yes or no), can cause errors, crashes etc.
    local RemoveStuns = true                    -- Defensive Strong Dispel (yes or no)

    self:Purge(true, true, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
  end

  function CDOTA_BaseNPC:CheckForAccidentalDamage(ability)
    if not ability or ability:IsNull() then
      return nil
    end

    if ability.GetAbilityName then
      local damagingByAccident = {
        item_radiance = true,
        item_radiance_2 = true,
        item_radiance_3 = true,
        item_radiance_4 = true,
        item_radiance_5 = true,
        item_cloak_of_flames = true,
        item_stormcrafter = true,
        doom_bringer_scorched_earth = true,
        mirana_starfall = true,
        wisp_spirits = true,
      }
      local name = ability:GetAbilityName()
      local hp = self:GetHealth()
      local max_hp = self:GetMaxHealth()
      if damagingByAccident[name] and hp/max_hp > 96/100 then
        return true
      end
    end

    return false
  end

  function CDOTA_BaseNPC:ForceKillOAA(param)
    --self:AbsolutePurge()
    self:AddNewModifier(self, nil, "modifier_generic_dead_tracker_oaa", {duration = MANUAL_GARBAGE_CLEANING_TIME})
    self:ForceKill(param)
  end
end

-- On Server:
if CDOTA_BaseNPC then
  function CDOTA_BaseNPC:GetAttackRange()
    return self:Script_GetAttackRange()
  end

  function CDOTA_BaseNPC:ReduceMana(amount, mana_burning_ability)
    return self:Script_ReduceMana(amount, mana_burning_ability)
  end

  function CDOTA_BaseNPC:IsNeutralCreep( notAncient )
    local targetFlags = bit.bor( DOTA_UNIT_TARGET_FLAG_DEAD, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO )

    if notAncient then
      targetFlags = bit.bor( targetFlags, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS )
    end

    return ( UnitFilter( self, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, targetFlags, DOTA_TEAM_NEUTRALS ) == UF_SUCCESS and not self:IsControllableByAnyPlayer() )
  end

  function CDOTA_BaseNPC:IsOAABoss()
    return self:HasModifier("modifier_boss_basic_properties_oaa")
  end

  function CDOTA_BaseNPC:IsSpiritBearOAA()
    return string.find(self:GetUnitName(), "npc_dota_lone_druid_bear")
  end

  function CDOTA_BaseNPC:HasShardOAA()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function CDOTA_BaseNPC:IsStrongIllusionOAA()
    local strong_illus = {
      "modifier_chaos_knight_phantasm_illusion",
      "modifier_vengefulspirit_hybrid_special",
      "modifier_chaos_knight_phantasm_illusion_shard",
    }
    for _, v in pairs(strong_illus) do
      if self:HasModifier(v) then
        return true
      end
    end
    return false
  end

  function CDOTA_BaseNPC:IsLeashedOAA()
    local normal_leashes = {
      "modifier_furion_sprout_tether",
      "modifier_grimstroke_soul_chain",
      "modifier_puck_coiled",
      "modifier_rattletrap_cog_leash", -- not sure if this modifier exists
      "modifier_slark_pounce_leash",
      -- custom:
      "modifier_tinkerer_laser_contraption_debuff",
    }

    for _, v in pairs(normal_leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    local power_cogs = self:FindModifierByName("modifier_rattletrap_cog_marker")
    if power_cogs then
      local caster = power_cogs:GetCaster()
      if caster then
        local talent = caster:FindAbilityByName("special_bonus_unique_clockwerk_2")
        if talent and talent:GetLevel() then
          return true
        end
      end
    end
    return false
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
    return self:HasModifier("modifier_boss_basic_properties_oaa")
  end

  function C_DOTA_BaseNPC:IsSpiritBearOAA()
    return string.find(self:GetUnitName(), "npc_dota_lone_druid_bear")
  end

  function C_DOTA_BaseNPC:HasShardOAA()
    return self:HasModifier("modifier_item_aghanims_shard")
  end

  function C_DOTA_BaseNPC:IsStrongIllusionOAA()
    local strong_illus = {
      "modifier_chaos_knight_phantasm_illusion",
      "modifier_vengefulspirit_hybrid_special",
      "modifier_chaos_knight_phantasm_illusion_shard",
    }
    for _, v in pairs(strong_illus) do
      if self:HasModifier(v) then
        return true
      end
    end
    return false
  end

  function C_DOTA_BaseNPC:IsLeashedOAA()
    local normal_leashes = {
      "modifier_furion_sprout_tether",
      "modifier_grimstroke_soul_chain",
      "modifier_puck_coiled",
      "modifier_rattletrap_cog_leash", -- not sure if this modifier exists
      "modifier_slark_pounce_leash",
      -- custom:
      "modifier_tinkerer_laser_contraption_debuff",
    }

    for _, v in pairs(normal_leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    return false
  end
end
