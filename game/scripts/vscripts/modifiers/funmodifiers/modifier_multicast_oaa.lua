
modifier_multicast_oaa = class(ModifierBaseClass)

function modifier_multicast_oaa:IsHidden()
  return false
end

function modifier_multicast_oaa:IsDebuff()
  return false
end

function modifier_multicast_oaa:IsPurgable()
  return false
end

function modifier_multicast_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_multicast_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
  }
end

function modifier_multicast_oaa:OnCreated()
  self.double_chance = 60
  self.triple_chance = 30
  self.quad_chance = 15
  self.delay = 0.6

  self.ignore_abilities = {
    abyssal_underlord_cancel_dark_rift_oaa = 1,          -- useless
    alchemist_unstable_concoction = 1,                   -- self grief
    --alchemist_unstable_concoction_throw = 1,           -- useless or powerful?
    ancient_apparition_ice_blast_release = 1,            -- useless
    --antimage_mana_overload = 1,                        -- lag
    arc_warden_tempest_double = 1,                       -- multiple Tempest Doubles and lag
    bane_nightmare_end = 1,                              -- useless
    --beastmaster_call_of_the_wild_boar_oaa = 1,         -- lag
    --beastmaster_call_of_the_wild_hawk = 1,             -- lag
    brewmaster_primal_split = 1,                         -- bugs out?
    broodmother_spin_web = 1,                            -- bugs out the screen
    centaur_mount = 1,                                   -- bugs out?
    centaur_work_horse = 1,                              -- bugs out?
    chaos_knight_phantasm = 1,                           -- lag
    chen_holy_persuasion = 1,                            -- dominating every creep or hero
    clinkz_burning_army = 1,                             -- lag
    clinkz_death_pact = 1,                               -- instant kill
    clinkz_death_pact_oaa = 1,                           -- instant kill
    crystal_maiden_arcane_magic_oaa = 1,                 -- useless
    crystal_maiden_freezing_field_stop = 1,              -- useless
    dark_seer_wall_of_replica = 1,                       -- lag
    dark_willow_bramble_maze = 1,                        -- lag
    dawnbreaker_converge = 1,                            -- useless
    --dawnbreaker_fire_wreath = 1,                       -- bugs out?
    dazzle_nothl_projection = 1,                         -- multiple projections?
    dazzle_nothl_projection_end = 1,                     -- useless
    doom_bringer_devour = 1,                             -- instant kill, DOTA_UNIT_TARGET_TEAM_CUSTOM
    --doom_bringer_doom = 1,                             -- powerful
    earth_spirit_petrify = 1,                            -- grief, trolling, DOTA_UNIT_TARGET_TEAM_CUSTOM
    earth_spirit_rolling_boulder = 1,                    -- bugs out
    earth_spirit_stone_caller = 1,                       -- self grief
    elder_titan_move_spirit = 1,                         -- useless
    elder_titan_return_spirit = 1,                       -- useless
    electrician_electric_shield = 1,                     -- self grief in most cases
    ember_spirit_activate_fire_remnant = 1,              -- useless
    --ember_spirit_sleight_of_fist = 1,                  -- bugs out?
    enigma_demonic_conversion = 1,                       -- lag
    enigma_demonic_conversion_oaa = 1,                   -- lag
    eul_tornado_collector_oaa = 1,                       -- self grief
    eul_typhoon_oaa = 1,                                 -- lag
    faceless_void_time_dilation = 1,                     -- powerful
    faceless_void_time_walk_reverse = 1,                 -- useless
    --furion_force_of_nature = 1,                        -- lag (but needs trees)
    --furion_wrath_of_nature = 1,                        -- powerful (but needs vision)
    --furion_wrath_of_nature_oaa = 1,                    -- powerful (but needs vision)
    hoodwink_decoy = 1,                                  -- lag
    hoodwink_sharpshooter_release = 1,                   -- useless
    --invoker_chaos_meteor = 1,                          -- lag and maybe crash
    invoker_exort = 1,                                   -- self grief in most cases
    invoker_invoke = 1,                                  -- self grief in most cases
    invoker_quas = 1,                                    -- self grief in most cases
    --invoker_sun_strike = 1,                            -- powerful
    invoker_wex = 1,                                     -- self grief in most cases
    keeper_of_the_light_illuminate_end = 1,              -- useless
    keeper_of_the_light_spirit_form_illuminate_end = 1,  -- useless
    kez_raptor_dance = 1,                                -- bugs out?
    kez_shodo_sai_parry_cancel = 1,                      -- useless
    kez_switch_weapons = 1,                              -- self grief in most cases
    kunkka_return = 1,                                   -- useless
    kunkka_torrent_storm = 1,                            -- lag
    --leshrac_diabolic_edict = 1,                        -- powerful
    life_stealer_consume = 1,                            -- useless
    life_stealer_infest = 1,                             -- bugs out, DOTA_UNIT_TARGET_TEAM_CUSTOM
    lone_druid_spirit_bear = 1,                          -- multiple bears?
    meepo_megameepo_fling = 1,                           -- bugs out when out of meepos?
    mirana_leap = 1,                                     -- self grief in most cases
    --monkey_king_boundless_strike = 1,                  -- powerful
    monkey_king_primal_spring = 1,                       -- breaks ability
    monkey_king_tree_dance = 1,                          -- breaks Primal Spring
    monkey_king_untransform = 1,                         -- useless
    monkey_king_wukongs_command = 1,                     -- lag
    monkey_king_wukongs_command_oaa = 1,                 -- lag
    morphling_morph_replicate = 1,                       -- useless
    morphling_replicate = 1,                             -- bugs out, DOTA_UNIT_TARGET_TEAM_CUSTOM
    muerta_parting_shot = 1,                             -- bugs out
    muerta_the_calling = 1,                              -- lag
    naga_siren_song_of_the_siren_cancel = 1,             -- useless
    nevermore_frenzy = 1,                                -- self grief in most cases
    night_stalker_hunter_in_the_night = 1,               -- instant kill
    nyx_assassin_burrow = 1,                             -- bugs out?
    nyx_assassin_unburrow = 1,                           -- self grief
    --obsidian_destroyer_astral_imprisonment = 1,        -- grief, trolling
    --oracle_false_promise = 1,                          -- powerful
    pangolier_gyroshell_stop = 1,                        -- useless
    pangolier_rollup_stop = 1,                           -- useless
    --phantom_lancer_doppelwalk = 1,                     -- lag
    --phantom_lancer_juxtapose = 1,                      -- lag because of shard
    --phantom_lancer_spirit_lance = 1,                   -- lag because of scepter
    phoenix_icarus_dive_stop = 1,                        -- useless
    phoenix_sun_ray_stop = 1,                            -- useless
    phoenix_sun_ray_toggle_move = 1,                     -- useless
    primal_beast_onslaught_release = 1,                  -- useless
    puck_ethereal_jaunt = 1,                             -- useless
    pudge_eject = 1,                                     -- useless
    --pudge_meat_hook = 1,                               -- bugs out?
    --pugna_nether_ward = 1,                             -- lag
    --pugna_nether_ward_oaa = 1,                         -- lag, powerful
    --rattletrap_power_cogs = 1,                         -- lag, annoying
    --razor_eye_of_the_storm = 1,                        -- powerful
    ringmaster_tame_the_beasts_crack = 1,                -- useless
    --ringmaster_the_box = 1,                            -- grief
    rubick_spell_steal = 1,                              -- stealing boss spells
    rubick_telekinesis_land = 1,                         -- useless
    rubick_telekinesis_land_self = 1,                    -- useless
    --shadow_demon_disruption = 1,                       -- grief, trolling
    shadow_demon_shadow_poison_release = 1,              -- useless
    shadow_shaman_mass_serpent_ward = 1,                 -- lag, powerful
    shadow_shaman_mass_serpent_ward_oaa = 1,             -- lag, powerful
    shredder_chakram = 1,                                -- multiplies Chakrams
    shredder_chakram_2 = 1,                              -- multiplies Chakrams
    shredder_return_chakram = 1,                         -- useless
    shredder_return_chakram_2 = 1,                       -- useless
    --shredder_timber_chain = 1,                         -- bugs out?
    --silencer_global_silence = 1,                       -- powerful because of scepter?
    skeleton_king_bone_guard = 1,                        -- lag because of the talent that grants free skeletons
    skeleton_king_reincarnation = 1,                     -- lag because of the skeletons
    snapfire_gobble_up = 1,                              -- instant kill and other bugs, DOTA_UNIT_TARGET_TEAM_CUSTOM
    snapfire_spit_creep = 1,                             -- useless
    sniper_take_aim = 1,                                 -- useless
    sohei_flurry_of_blows = 1,                           -- self grief
    spectre_haunt = 1,                                   -- lag, trolling (doesn't need vision)
    spectre_reality = 1,                                 -- useless
    storm_spirit_ball_lightning = 1,                     -- self grief (spends mana)
    techies_reactive_tazer_stop = 1,                     -- useless
    templar_assassin_trap = 1,                           -- self grief
    --terrorblade_conjure_image = 1,                     -- lag
    --terrorblade_conjure_image_oaa = 1,                 -- lag
    --terrorblade_reflection = 1,                        -- lag
    terrorblade_sunder = 1,                              -- self grief, can proc on creeps
    tinkerer_laser_contraption = 1,                      -- lag
    tiny_toss_tree = 1,                                  -- useless
    tiny_tree_grab = 1,                                  -- bugged, DOTA_UNIT_TARGET_TEAM_CUSTOM
    treant_leech_seed = 1,                               -- crashes (changes targetting)
    treant_eyes_in_the_forest = 1,                       -- bugged
    tusk_launch_snowball = 1,                            -- useless
    tusk_snowball = 1,                                   -- bugs out
    undying_tombstone = 1,                               -- lag
    undying_tombstone_grab = 1,                          -- grief, bugs out?
    --ursa_enrage = 1,                                   -- increases duration?
    --vengefulspirit_nether_swap = 1,                    -- grief in some cases, DOTA_UNIT_TARGET_TEAM_CUSTOM
    venomancer_plague_ward = 1,                          -- crashes (changes targetting)
    visage_stone_form_self_cast = 1,                     -- self grief
    void_spirit_aether_remnant = 1,                      -- lag
    --void_spirit_astral_step = 1,                       -- bugs out?
    --warlock_rain_of_chaos = 1,                         -- lag
    --weaver_time_lapse = 1,                             -- powerful or grief with scepter?
    --winter_wyvern_cold_embrace = 1,                    -- grief
    wisp_tether_break = 1,                               -- useless
    --witch_doctor_voodoo_switcheroo_oaa = 1,            -- bugs out?
    --zuus_cloud_oaa = 1,                                -- powerful
    zuus_heavenly_jump = 1,                              -- self grief in most cases
    --zuus_thundergods_wrath = 1,                        -- powerful
  }
end

if IsServer() then
  function modifier_multicast_oaa:OnAbilityFullyCast(event)
    local parent = self:GetParent()
    local unit = event.unit
    local ability = event.ability

    -- Check if caster unit exists
    if not unit or unit:IsNull() then
      return
    end

    -- Check if caster unit has this modifier
    if unit ~= parent then
      return
    end

    -- Check if caster is alive
    if not parent:IsAlive() then
      return
    end

    -- Check if used ability exists
    if not ability or ability:IsNull() then
      return
    end

    if self:canMulticast(ability) then
      -- Calculate level of multicast based on hero lvl
      local hero_lvl = parent:GetLevel()
      local lvl
      if hero_lvl < 12 then
        lvl = 1
      elseif hero_lvl < 18 then
        lvl = 2
      else
        lvl = 3
      end

      -- How many times we will cast the spell
      local mult = 0

      -- Grab a random number
      local r = RandomInt(0, 100)

      -- Calculate multiplier
      if lvl == 1 then
        if r < self.double_chance then
          mult = 2
        end
      elseif lvl == 2 then
        if r < self.triple_chance then
          mult = 3
        elseif r < self.double_chance then
          mult = 2
        end
      elseif lvl == 3 then
        if r < self.quad_chance then
          mult = 4
        elseif r < self.triple_chance then
          mult = 3
        elseif r < self.double_chance then
          mult = 2
        end
      end

      -- Are we doing any multiplying?
      if mult > 0 and ability then
        -- How long to delay each cast
        local delay = self.delay

        local name = ability:GetAbilityName()
        local target_team = ability:GetAbilityTargetTeam()
        if target_team ~= DOTA_UNIT_TARGET_TEAM_FRIENDLY and target_team ~= DOTA_UNIT_TARGET_TEAM_ENEMY and target_team ~= DOTA_UNIT_TARGET_TEAM_BOTH then
          -- DOTA_UNIT_TARGET_TEAM_NONE or DOTA_UNIT_TARGET_TEAM_CUSTOM - if there are issues it's because of this
          target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
        end
        --local behavior = ability:GetBehaviorInt()
        local behavior = ability:GetBehavior()
        if type(behavior) == 'userdata' then
          behavior = tonumber(tostring(behavior))
        end
        if not behavior then
          behavior = DOTA_ABILITY_BEHAVIOR_NONE
        end

        local isNoTarget = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) > 0
        local isUnitTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) > 0
        local isPointTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0
        local isChannel = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) > 0

        -- If bit.band of behavior is malfunctioning or we somehow got an invalid ability, recheck the kv of the ability
        if not isNoTarget and not isUnitTargetting and not isPointTargetting then
          local ability_data = GetAbilityKeyValuesByName(name)
          if not ability_data then
            return
          end
          behavior = ability_data.AbilityBehavior
          if not behavior then
            return
          end
          isNoTarget = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET")
          isUnitTargetting = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET")
          isPointTargetting = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_POINT")
          if not isNoTarget and not isUnitTargetting and not isPointTargetting then
            return
          end
        end
        local target = parent:GetCursorCastTarget()
        local pos = parent:GetCursorPosition()
        local targets = {target}
        local real_pos = pos
        if isChannel then
          -- Channeling spells never end so we need to create a dummy and cast the spell
          return
        end
        if isUnitTargetting then
          if target_team == DOTA_UNIT_TARGET_TEAM_FRIENDLY then
            targets = self:FindRandomAllies(ability, target, mult)
          elseif target_team == DOTA_UNIT_TARGET_TEAM_BOTH then
            local rand = RandomInt(1, 4)
            if rand == 1 then
              targets = {parent, parent, parent, target}
            elseif rand == 2 then
              targets = self:FindRandomAllies(ability, target, mult)
            elseif rand == 3 then
              targets = {target, target, target, parent}
            else
              targets = self:FindRandomEnemies(ability, target, mult)
            end
          else
            targets = self:FindRandomEnemies(ability, target, mult)
          end
        elseif isPointTargetting then
          if not real_pos then
            local caster_loc = parent:GetAbsOrigin()
            if target then
              real_pos = target:GetAbsOrigin()
            else
              real_pos = caster_loc
            end

            local distance = (real_pos - caster_loc):Length2D()
            local buffer = 250
            local base_cast_range = ability:GetCastRange(caster_loc, nil) -- it could return a weird result for global range abilities
            local eff_cast_range = ability:GetEffectiveCastRange(caster_loc, nil) -- it could return a weird result for global range abilities

            -- Checking cast range like this just in case if 'GetEffectiveCastRange' is not working
            -- and setting new target location to prevent global stuff
            if (distance > (base_cast_range + parent:GetCastRangeBonus()) and base_cast_range > 0) or (distance >= (parent:GetAttackRange() + buffer)) or (distance > eff_cast_range and eff_cast_range > 0) then
              real_pos = caster_loc + parent:GetForwardVector() * buffer
            end
          end
        end

        if mult > 1 then
          -- Create sexy particles
          local prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf', PATTACH_OVERHEAD_FOLLOW, parent)
          ParticleManager:SetParticleControl(prt, 1, Vector(mult, 0, 0))
          ParticleManager:ReleaseParticleIndex(prt)

          prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, parent:GetCursorCastTarget() or parent)
          prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_b.vpcf', PATTACH_OVERHEAD_FOLLOW, parent)
          ParticleManager:ReleaseParticleIndex(prt)

          prt = ParticleManager:CreateParticle('particles/units/heroes/hero_ogre_magi/ogre_magi_multicast_c.vpcf', PATTACH_OVERHEAD_FOLLOW, parent:GetCursorCastTarget() or parent)
          ParticleManager:SetParticleControl(prt, 1, Vector(mult, 0, 0))
          ParticleManager:ReleaseParticleIndex(prt)

          -- Play the sound
          parent:EmitSound('Hero_OgreMagi.Fireblast.x'..(mult-1))
        end

        Timers:CreateTimer(delay, function()
          -- Ensure it still exists
          if IsValidEntity(ability) and targets then
            -- Position cursor
            parent:SetCursorPosition(real_pos)

            if isUnitTargetting then
              local index = RandomInt(1, #targets)
              local multicast_target = targets[index]
              table.remove(targets, index)
              -- Null check
              if not multicast_target or multicast_target:IsNull() or not multicast_target:IsAlive() then
                return
              end
              -- Spell Block check
              if multicast_target:TriggerSpellAbsorb(ability) and multicast_target:GetTeamNumber() ~= parent:GetTeamNumber() then
                return
              end
              parent:SetCursorCastTarget(multicast_target)
            end

            --ability:OnAbilityPhaseStart()
            ability:OnSpellStart()

            mult = mult - 1
            if mult > 1 then
              return delay
            end
          end
        end)
      end
    end
  end
end

function modifier_multicast_oaa:canMulticast(ability)
  if not ability or ability:IsNull() then
    return false
  end
  return not ability:IsItem() and not ability:IsHidden() and not ability:IsToggle() and ability:IsTrained() and not ability:IsPassive() and not self.ignore_abilities[ability:GetName()]
end

function modifier_multicast_oaa:FindRandomAllies(ability, target, n)
  local parent = self:GetParent()
  local random_allies = {}

  local target_type = ability:GetAbilityTargetType()
  if target_type == DOTA_UNIT_TARGET_CUSTOM then
    target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  end

  local allies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(parent:GetAbsOrigin(), parent),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    target_type,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() and ally ~= parent and ally ~= target then
      table.insert(random_allies, ally)
      if #random_allies == n then
        break
      end
    end
  end

  if #random_allies < n then
    table.insert(random_allies, parent)
    while #random_allies < n do
      table.insert(random_allies, target)
    end
  end

  return random_allies
end

function modifier_multicast_oaa:FindRandomEnemies(ability, target, n)
  local parent = self:GetParent()
  local random_enemies = {}

  local target_type = ability:GetAbilityTargetType()
  if target_type == DOTA_UNIT_TARGET_CUSTOM then
    target_type = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
  end

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(parent:GetAbsOrigin(), nil),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    target_type,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy ~= target then
      table.insert(random_enemies, enemy)
      if #random_enemies == n then
        break
      end
    end
  end

  while #random_enemies < n do
    table.insert(random_enemies, target)
  end

  return random_enemies
end

function modifier_multicast_oaa:GetTexture()
  return "ogre_magi_multicast"
end
