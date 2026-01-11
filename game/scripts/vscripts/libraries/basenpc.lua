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
      --"modifier_item_angels_demise_slow",              -- Khanda Slow
      "modifier_item_angels_demise_break",             -- Khanda Break
      -- custom:
      "modifier_item_shade_staff_trees_debuff",        -- Shade Staff debuff
      "modifier_item_rune_breaker_oaa_debuff",         -- Rune Breaker debuff
      "modifier_item_trumps_fists_frostbite",          -- Blade of Judecca debuff
    }

    local undispellable_ability_debuffs = {
      "modifier_antimage_empowered_mana_break_debuff", -- Anti-Mage scepter debuff
      "modifier_axe_berserkers_call",
      "modifier_bloodseeker_rupture",
      --"modifier_dazzle_bad_juju_armor",         -- Bad Juju stacks
      "modifier_doom_bringer_doom",
      "modifier_doom_bringer_doom_enemy",
      "modifier_earth_spirit_magnetize",        -- Magnetize becomes undispellable with the talent
      "modifier_earthspirit_petrify",           -- Earth Spirit Enchant Remnant debuff
      "modifier_enchantress_little_friends_aura", -- Enchantress scepter aura that affects neutral creeps
      "modifier_enchantress_little_friends_kill_credit", -- Enchantress scepter debuff that allows her to take credit for the kill made with neutrals
      "modifier_forged_spirit_melting_strike_debuff",
      "modifier_grimstroke_soul_chain",
      "modifier_huskar_burning_spear_debuff",   -- Burning Spear stacks
      "modifier_huskar_life_break_taunt",       -- Huskar Life Break scepter taunt
      "modifier_ice_blast",
      "modifier_invoker_deafening_blast_disarm",
      "modifier_maledict",
      "modifier_obsidian_destroyer_astral_imprisonment_prison",
      "modifier_obsidian_destroyer_equilibrium_debuff_counter",
      "modifier_queenofpain_sonic_wave_damage",
      "modifier_queenofpain_sonic_wave_knockback",
      "modifier_razor_eye_of_the_storm_armor",  -- Eye of the Storm stacks
      "modifier_razor_static_link_debuff",
      "modifier_rooted_undispellable",          -- generic undispellable root - Enchantress scepter uses this
      "modifier_sand_king_caustic_finale_orb",  -- Caustic Finale initial debuff
      "modifier_shadow_demon_disruption",
      "modifier_shadow_demon_purge_slow",
      "modifier_shadow_demon_shadow_poison",    -- Shadow Poison stacks
      "modifier_silencer_curse_of_the_silent",  -- Arcane Curse becomes undispellable with the talent
      "modifier_slardar_amplify_damage",        -- Corrosive Haze becomes undispellable with the talent
      "modifier_slark_pounce_leash",
      "modifier_treant_overgrowth",             -- Overgrowth becomes undispellable with the talent
      "modifier_tusk_walrus_kick_slow",
      "modifier_tusk_walrus_punch_slow",
      "modifier_ursa_fury_swipes_damage_increase",
      "modifier_venomancer_poison_nova",
      "modifier_venomancer_noxious_plague_primary",
      "modifier_venomancer_noxious_plague_secondary",
      "modifier_venomancer_noxious_plague_slow",
      "modifier_viper_viper_strike_slow",
      "modifier_windrunner_windrun_slow",
      "modifier_winter_wyvern_winters_curse",
      "modifier_winter_wyvern_winters_curse_aura",
    }

    local debuffs_with_multiple_instances = {
      "modifier_bristleback_quill_spray",                -- Quill Spray stacks
      "modifier_dazzle_innate_weave_armor",              -- same modifier used as a buff and debuff
      "modifier_huskar_burning_spear_counter",           -- these stacks do not do dmg without modifier_huskar_burning_spear_debuff
      "modifier_obsidian_destroyer_equilibrium_debuff",  -- these stacks reduce mana
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, undispellable_item_debuffs)
    RemoveTableOfModifiersFromUnit(self, undispellable_ability_debuffs)

    for i = 1, #debuffs_with_multiple_instances do
      self:RemoveAllModifiersOfName(debuffs_with_multiple_instances[i])
    end
  end

  function CDOTA_BaseNPC:DispelWeirdDebuffs()
    -- Debuffs that reduce cast range or increase cast time (reduce cast speed)
    local a = {
      "modifier_bane_enfeeble_effect",
      "modifier_faceless_void_time_zone_effect", -- it will probably get reapplied again
      "modifier_medusa_venomed_volley_slow",
      "modifier_tinker_warp_grenade",
    }

    local function RemoveTableOfModifiersFromUnit(unit, t)
      for i = 1, #t do
        unit:RemoveModifierByName(t[i])
      end
    end

    RemoveTableOfModifiersFromUnit(self, a)
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
      --"modifier_eternal_shroud_oaa_barrier",         -- Eternal Shroud active buff
      "modifier_item_butterfly_oaa_active",          -- Butterfly active buff
      "modifier_item_dagger_of_moriah_sangromancy",  -- Dagger of Moriah active buff
      "modifier_item_dispel_orb_active",             -- Dispel Orb buff
      "modifier_item_havoc_hammer_active",           -- Havoc Hammer active buff
      --"modifier_item_heart_transplant_buff",       -- Heart Transplant buff
      "modifier_item_martyrs_mail_martyr_active",    -- Martyr's Mail buff
      --"modifier_item_reduction_orb_active",          -- Reduction Orb buff
      "modifier_item_reflex_core_invulnerability",   -- Reflex Core buff
      "modifier_satanic_core_unholy",                -- Satanic Core buff
      "modifier_item_spiked_mail_active_return",     -- Spiked Mail active buff
      "modifier_item_stoneskin_stone_armor",         -- Stoneskin Armor buff
      "modifier_item_vampire_active",                -- Vampire Fang active buff
      --"modifier_pull_staff_active_buff",           -- Pull Staff motion controller
      --"modifier_shield_staff_active_buff",         -- Force Shield Staff motion controller
    }

    local undispellable_ability_buffs = {
      "modifier_axe_berserkers_call_armor",
      "modifier_bounty_hunter_wind_walk",
      "modifier_broodmother_insatiable_hunger",
      "modifier_centaur_stampede",
      "modifier_clinkz_wind_walk",
      "modifier_dark_willow_shadow_realm_buff",
      "modifier_dazzle_innate_weave_armor_counter",
      "modifier_dazzle_shallow_grave",
      "modifier_doom_bringer_doom_aura_self",
      "modifier_doom_bringer_scorched_earth_effect",
      "modifier_doom_bringer_scorched_earth_effect_aura",
      "modifier_enchantress_natures_attendants",
      "modifier_gyrocopter_flak_cannon",
      "modifier_invoker_ghost_walk_self",
      "modifier_juggernaut_blade_fury",
      "modifier_kunkka_ghost_ship_damage_absorb",
      "modifier_kunkka_ghost_ship_damage_delay",
      "modifier_life_stealer_rage",
      "modifier_lone_druid_true_form_battle_cry",
      "modifier_luna_eclipse",
      "modifier_luna_lucent_beam_damage_buff_counter",    -- Luna Moonstorm stacks
      "modifier_luna_moon_glaive_shield",                 -- Luna Lunar Orbit
      "modifier_medusa_stone_gaze",
      "modifier_mirana_moonlight_shadow",
      "modifier_nyx_assassin_spiked_carapace",
      "modifier_nyx_assassin_vendetta",
      "modifier_obsidian_destroyer_equilibrium_barrier",   -- OD scepter shield
      "modifier_obsidian_destroyer_equilibrium_buff_counter",
      "modifier_omniknight_martyr",
      "modifier_oracle_false_promise_timer",
      "modifier_pangolier_shield_crash_buff",
      "modifier_phantom_assassin_blur_active",
      "modifier_phoenix_supernova_hiding",
      "modifier_rattletrap_battery_assault",
      "modifier_razor_static_link_buff",
      "modifier_skeleton_king_reincarnation_scepter_active", -- Wraith King Wraith Form
      "modifier_skywrath_mage_shard_bonus_counter",
      "modifier_skywrath_mage_shield_barrier",
      "modifier_slark_shadow_dance",
      "modifier_sven_warcry",  -- Warcry becomes undispellable with shard
      "modifier_templar_assassin_refraction_absorb",
      "modifier_templar_assassin_refraction_damage",
      "modifier_ursa_enrage",
      "modifier_visage_summon_familiars_stone_form_buff", -- Visage and his familiars use the same Stone Form modifier
      "modifier_weaver_shukuchi",
      "modifier_windrunner_windrun",  -- Windrun becomes undispellable with the talent
      "modifier_windrunner_windrun_invis",
      "modifier_winter_wyvern_cold_embrace",
      "modifier_wisp_overcharge",
      -- custom:
      "modifier_alpha_invisibility_oaa_buff",   -- Neutral Alpha Wolf invisibility buff
      "modifier_sohei_flurry_self",
    }

    local buffs_with_multiple_instances = {
      "modifier_dazzle_innate_weave_armor",
      "modifier_leshrac_diabolic_edict",
      "modifier_obsidian_destroyer_equilibrium_buff",
      "modifier_razor_eye_of_the_storm",
      "modifier_skywrath_mage_shard_bonus",
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

    for i = 1, #buffs_with_multiple_instances do
      self:RemoveAllModifiersOfName(buffs_with_multiple_instances[i])
    end

    -- Dispel bools
    local BuffsCreatedThisFrameOnly = false
    local RemoveExceptions = true               -- For hex and similar
    local RemoveStuns = true                    -- For stuns

    -- Remove most dispellable modifiers
    self:Purge(true, true, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
  end

  function CDOTA_BaseNPC:CheckForAccidentalDamage(ability)
    if not ability or ability:IsNull() then
      return nil
    end

    if ability.GetAbilityName then
      local damagingByAccident = {
        item_cloak_of_flames = true,
        item_maelstrom = true, -- because of random bounces
        item_mjollnir = true, -- because of random bounces
        item_mjollnir_2 = true,
        item_mjollnir_3 = true,
        item_mjollnir_4 = true,
        item_mjollnir_5 = true,
        item_overwhelming_blink = true,
        item_overwhelming_blink_2 = true,
        item_overwhelming_blink_3 = true,
        item_overwhelming_blink_4 = true,
        item_overwhelming_blink_5 = true,
        item_radiance = true,
        item_radiance_2 = true,
        item_radiance_3 = true,
        item_radiance_4 = true,
        item_radiance_5 = true,
        item_stormcrafter = true,
        beastmaster_call_of_the_wild_hawk = true,
        brewmaster_fire_permanent_immolation = true,
        ember_spirit_immolation = true,
        furion_wrath_of_nature = true, -- because of random bounces
        --leshrac_diabolic_edict = true,
        lina_combustion = true,
        --mirana_starfall = true, -- because of Scepter Arrow
        phoenix_dying_light = true,
        razor_storm_surge = true,
        --sandking_epicenter = true, -- because of shard?
        sandking_sand_storm = true, -- because of moving Sand Storm facet
        warlock_golem_permanent_immolation = true,
        wisp_spirits = true,
      }
      local name = ability:GetAbilityName()
      local hp = self:GetHealth()
      local max_hp = self:GetMaxHealth()
      if damagingByAccident[name] and hp/max_hp > 0.95 then
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

  function CDOTA_BaseNPC:ResetHeroOAA(resetAbilities)
    local hero = self

    -- Reset the hero, respawn if the hero is dead
    if not hero:ResetUnitOAA(resetAbilities) then
      hero:RespawnHero(false, false)
      hero:ResetUnitOAA(resetAbilities)
    end

    -- Remove offside penalties
    if hero:HasModifier("modifier_offside") then
      hero:RemoveModifierByName("modifier_offside")
    end
    if hero:HasModifier("modifier_is_in_offside") then
      hero:RemoveModifierByName("modifier_is_in_offside")
    end
  end

  function CDOTA_BaseNPC:ResetUnitOAA(resetAbilities)
    local unit = self

    if not unit:IsAlive() then
      -- ResetUnitOAA called on a dead unit, respawning it is not a good idea
      return false
    end

    -- Disjoint disjointable projectiles
    ProjectileManager:ProjectileDodge(unit)

    -- Reset health before purge to avoid some weird interactions
    unit:SetHealth(unit:GetMaxHealth())

    -- Absolute Purge (Strong Dispel + removing most undispellable buffs and debuffs)
    unit:AbsolutePurge()

    if not unit or unit:IsNull() then
      -- Unit got deleted so fast from the memory after purge, nothing we can do
      return false
    end

    if not unit:IsAlive() then
      -- Unit died after purge but still exists in memory, respawning it is not a good idea
      return false
    end

    -- Reset health again just in case purge damaged the unit
    unit:SetHealth(unit:GetMaxHealth())

    -- Reset mana
    unit:SetMana(unit:GetMaxMana())

    -- Do not continue if resetAbilities bool is false
    if not resetAbilities then
      return true
    end

    if unit.GetAbilityCount ~= nil then
      -- Reset cooldown for abilities
      for abilityIndex = 0, unit:GetAbilityCount() - 1 do
        local ability = unit:GetAbilityByIndex(abilityIndex)
        if ability ~= nil and ability:GetAbilityType() ~= ABILITY_TYPE_ULTIMATE then
          ability:EndCooldown()
          if not IsFakeItemCustom(ability) then
            ability:RefreshCharges()
          end
        end
      end
    end

    if unit.GetItemInSlot ~= nil and unit:HasInventory() then
      local exempt_item_table = {
        item_ex_machina = true,
        item_hand_of_midas_1 = true,
        item_refresher = true,
        item_refresher_2 = true,
        item_refresher_3 = true,
        item_refresher_4 = true,
        item_refresher_5 = true,
        item_refresher_shard_oaa = true,
      }

      -- Reset cooldown for items that are not in backpack and not in stash
      for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        local item = unit:GetItemInSlot(i)
        if item and not exempt_item_table[item:GetAbilityName()] then
          item:EndCooldown()
        end
      end

      -- Reset cooldown for items that are in backpack
      for j = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
        local backpack_item = unit:GetItemInSlot(j)
        if backpack_item and not exempt_item_table[backpack_item:GetAbilityName()] then
          backpack_item:EndCooldown()
        end
      end

      -- Reset neutral item cooldown
      local neutral_item = unit:GetItemInSlot(DOTA_ITEM_NEUTRAL_SLOT)
      if neutral_item and not exempt_item_table[neutral_item:GetAbilityName()] then
        neutral_item:EndCooldown()
      end
    end

    -- Special thing for Ward Stack - set counts to at least 1 ward
    if unit.sentryCount then
      if unit.sentryCount == 0 then
        unit.sentryCount = 1
      end
    end

    if unit.observerCount then
      if unit.observerCount == 0 then
        unit.observerCount = 1
      end
    end

    return true
  end

  -- Apply a modifier only if it's not from the same source ability otherwise just refresh
  function CDOTA_BaseNPC:ApplyNonStackableBuff(caster, ability, mod_name, duration)
    if not ability then
      return
    end
    local applied_by_this_ability = false
    local ability_name = ability:GetAbilityName()
    local mods = self:FindAllModifiersByName(mod_name)
    for _, mod in pairs(mods) do
      if mod and not mod:IsNull() then
        local mod_ability = mod:GetAbility()
        if mod_ability then
          local mod_ability_name = mod_ability:GetAbilityName()
          if string.find(mod_ability_name, string.sub(ability_name, 0, string.len(ability_name)-4)) then
            applied_by_this_ability = true
            mod:ForceRefresh()
            break
          end
        end
      end
    end
    if not applied_by_this_ability then
      return self:AddNewModifier(caster, ability, mod_name, {duration = duration})
    end
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
      --"modifier_chaos_knight_phantasm_illusion",
      "modifier_vengefulspirit_hybrid_special",
      --"modifier_chaos_knight_phantasm_illusion_shard",
      "modifier_chaos_knight_phantasmagoria",
      "modifier_morphling_replicate_illusion",
      --"modifier_morphling_replicate_morphed_illusions_effect",
      "modifier_grimstroke_scepter_buff",
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
      --"modifier_furion_sprout_tether",
      "modifier_grimstroke_soul_chain",
      "modifier_puck_coiled",
      --"modifier_rattletrap_cog_leash", -- not sure if this modifier exists
      "modifier_slark_pounce_leash",
      "modifier_tidehunter_anchor_clamp",
      -- custom:
      --"modifier_tinkerer_laser_contraption_debuff",
      "modifier_mars_arena_of_blood_leash_oaa",
    }

    -- Check for Leash immunities first (Sonic for example)
    if self:HasModifier("modifier_sonic_fly") then
      return false
    end

    -- Debuff Immunity interactions
    if self:IsDebuffImmune() then
      -- Grimstroke ult always pierces debuff immunity
      if self:HasModifier("modifier_grimstroke_soul_chain") then
        return true
      end

      -- Puck Dream Coil pierce debuff immunity with the talent
      local dream_coil_mod = self:FindModifierByName("modifier_puck_coiled")
      if dream_coil_mod then
        local dream_coil_ab = dream_coil_mod:GetAbility()
        --local caster = dream_coil_mod:GetCaster()
        if dream_coil_ab then
          local pierce = dream_coil_ab:GetSpecialValueFor("pierces_debuff_immunity") == 1
          --if caster then
            --local talent = caster:FindAbilityByName("special_bonus_unique_puck_5")
            --if talent and talent:GetLevel() > 0 then
          if pierce then
            return true
          end
        end
      end

      return false
    end

    for _, v in pairs(normal_leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    local power_cogs_mod = self:FindModifierByName("modifier_rattletrap_cog_marker")
    if power_cogs_mod then
      local power_cogs_ab = power_cogs_mod:GetAbility()
      if power_cogs_ab then
        local check = power_cogs_ab:GetSpecialValueFor("leash") == 1
        if check then
          return true
        end
      end
    end

    return false
  end

  function CDOTA_BaseNPC:InstantAttackCanProcCleave()
    -- If it's on this list and uncommented then it can proc Giant Form
    local list = {
      "modifier_ember_spirit_sleight_of_fist_caster",
      "modifier_ember_spirit_sleight_of_fist_caster_invulnerability",
      "modifier_ember_spirit_sleight_of_fist_in_progress",
      --"modifier_dawnbreaker_fire_wreath_caster",                  -- Dawnbreaker Q
      "modifier_juggernaut_omnislash",
      "modifier_juggernaut_omnislash_invulnerability",
      --"modifier_mars_gods_rebuke_crit",                         -- Mars W
      --"modifier_monkey_king_boundless_strike_crit",               -- MK Q
      "modifier_wukongs_command_oaa_buff",                        -- MK R
      "modifier_pangolier_swashbuckle",
      "modifier_pangolier_swashbuckle_attack",
      "modifier_phantom_assassin_stiflingdagger_caster",          -- PA Q
      "modifier_riki_tricks_of_the_trade_phase",
      --"modifier_sand_king_scorpion_strike",                     -- Sand King E
      --"modifier_sand_king_scorpion_strike_attack_bonus",        -- Sand King E
      "modifier_sohei_flurry_self",
      "modifier_tiny_tree_channel",
      --"modifier_void_spirit_astral_step_caster",                  -- Void Spirit R
    }
    for _, v in pairs(list) do
      if self:HasModifier(v) then
        return true
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
      --"modifier_chaos_knight_phantasm_illusion",
      "modifier_vengefulspirit_hybrid_special",
      --"modifier_chaos_knight_phantasm_illusion_shard",
      "modifier_chaos_knight_phantasmagoria",
      "modifier_morphling_replicate_illusion",
      --"modifier_morphling_replicate_morphed_illusions_effect",
      "modifier_grimstroke_scepter_buff",
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
      --"modifier_furion_sprout_tether",
      "modifier_grimstroke_soul_chain",
      "modifier_puck_coiled",
      --"modifier_rattletrap_cog_leash", -- not sure if this modifier exists
      "modifier_slark_pounce_leash",
      "modifier_tidehunter_anchor_clamp",
      -- custom:
      --"modifier_tinkerer_laser_contraption_debuff",
      "modifier_mars_arena_of_blood_leash_oaa",
    }

    -- Check for Leash immunities first (Sonic for example)
    if self:HasModifier("modifier_sonic_fly") then
      return false
    end

    -- Debuff Immunity interactions
    if self:IsDebuffImmune() then
      -- Grimstroke ult always pierces debuff immunity
      if self:HasModifier("modifier_grimstroke_soul_chain") then
        return true
      end

      return false
    end

    for _, v in pairs(normal_leashes) do
      if self:HasModifier(v) then
        return true
      end
    end

    return false
  end
end
