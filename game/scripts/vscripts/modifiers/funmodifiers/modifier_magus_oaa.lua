LinkLuaModifier("modifier_magus_cooldown_oaa", "modifiers/funmodifiers/modifier_magus_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_magus_oaa = class(ModifierBaseClass)

function modifier_magus_oaa:IsHidden()
  return false
end

function modifier_magus_oaa:IsDebuff()
  return false
end

function modifier_magus_oaa:IsPurgable()
  return false
end

function modifier_magus_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_magus_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_magus_oaa:OnCreated()
  self.chance = 25
  self.penalty_chance = 5
  self.cooldown = 0.5
  self.ignore_abilities = {
    abaddon_borrowed_time = 1,                           -- invulnerability
    abaddon_borrowed_time_oaa = 1,                       -- invulnerability
    alchemist_unstable_concoction = 1,                   -- self grief
    arc_warden_tempest_double = 1,                       -- multiple Tempest Doubles and lag
    bane_nightmare_end = 1,                              -- self grief
    brewmaster_primal_split = 1,                         -- invulnerability
    centaur_mount = 1,                                   -- self grief
    chaos_knight_phantasm = 1,                           -- invulnerability and lag
    chen_holy_persuasion = 1,                            -- dominating every creep or hero on attack
    chen_summon_convert = 1,                             -- self grief
    clinkz_death_pact = 1,                               -- instant kill
    clinkz_death_pact_oaa = 1,                           -- instant kill
    crystal_maiden_freezing_field_stop = 1,              -- self grief
    dark_willow_shadow_realm = 1,                        -- untargettable ranged hero, powerful
    dazzle_nothl_projection_end = 1,                     -- self grief
    dazzle_shallow_grave = 1,                            -- invulnerability
    doom_bringer_devour = 1,                             -- instant kill, DOTA_UNIT_TARGET_TEAM_CUSTOM
    earth_spirit_petrify = 1,                            -- invulnerability and trolling, DOTA_UNIT_TARGET_TEAM_CUSTOM
    elder_titan_move_spirit = 1,                         -- self grief
    elder_titan_return_spirit = 1,                       -- self grief
    ember_spirit_activate_fire_remnant = 1,              -- self grief
    enchantress_enchant = 1,                             -- dominating every creep on attack
    eul_tornado_collector_oaa = 1,                       -- self grief
    faceless_void_time_walk_reverse = 1,                 -- self grief
    furion_teleportation = 1,                            -- self grief
    --furion_wrath_of_nature = 1,                        -- powerful (but needs vision)
    --furion_wrath_of_nature_oaa = 1,                    -- powerful (but needs vision)
    hoodwink_sharpshooter_release = 1,                   -- self grief
    --invoker_sun_strike = 1,                            -- powerful, trolling (doesn't need vision), uncomment if Cataclysm procs
    keeper_of_the_light_illuminate_end = 1,              -- self grief
    keeper_of_the_light_spirit_form_illuminate_end = 1,  -- self grief
    kez_raptor_dance = 1,                                -- bugs out
    kunkka_return = 1,                                   -- self grief
    life_stealer_consume = 1,                            -- self grief
    life_stealer_infest = 1,                             -- self grief and maybe instant kill, DOTA_UNIT_TARGET_TEAM_CUSTOM
    meepo_megameepo_fling = 1,                           -- self grief
    meepo_petrify = 1,                                   -- invulnerability
    monkey_king_primal_spring = 1,                       -- breaks ability
    monkey_king_tree_dance = 1,                          -- self grief in most cases, breaks Primal Spring
    monkey_king_wukongs_command = 1,                     -- lag
    monkey_king_wukongs_command_oaa = 1,                 -- self grief, looping, lag maybe
    morphling_morph_replicate = 1,                       -- self grief
    morphling_replicate = 1,                             -- bugs out completely when attacking creeps, DOTA_UNIT_TARGET_TEAM_CUSTOM
    muerta_parting_shot = 1,                             -- buggy
    night_stalker_hunter_in_the_night = 1,               -- instant kill
    nyx_assassin_unburrow = 1,                           -- self grief
    oracle_false_promise = 1,                            -- invulnerability
    pangolier_gyroshell_stop = 1,                        -- self grief
    --phantom_assassin_phantom_strike = 1,               -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    phantom_lancer_doppelwalk = 1,                       -- invulnerability and lag
    phoenix_icarus_dive_stop = 1,                        -- self grief
    phoenix_sun_ray_stop = 1,                            -- self grief
    primal_beast_onslaught_release = 1,                  -- self grief
    puck_ethereal_jaunt = 1,                             -- self grief
    puck_phase_shift = 1,                                -- invulnerability
    pudge_eject = 1,                                     -- self grief
    --pugna_decrepify = 1,                               -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    --riki_blink_strike = 1,                             -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    riki_tricks_of_the_trade = 1,                        -- invulnerability and looping
    ringmaster_the_box = 1,                              -- grief
    rubick_spell_steal = 1,                              -- stealing boss spells
    rubick_telekinesis_land_self = 1,                    -- self grief
    shadow_demon_shadow_poison_release = 1,              -- self grief
    skeleton_king_reincarnation = 1,                     -- self grief
    snapfire_gobble_up = 1,                              -- instant kill and other bugs, DOTA_UNIT_TARGET_TEAM_CUSTOM
    sohei_flurry_of_blows = 1,                           -- invulnerability and looping
    spectre_haunt = 1,                                   -- lag, trolling (doesn't need vision)
    spectre_reality = 1,                                 -- self grief
    --storm_spirit_ball_lightning = 1,                   -- self grief
    techies_reactive_tazer_stop = 1,                     -- self grief
    templar_assassin_trap = 1,                           -- self grief
    terrorblade_conjure_image = 1,                       -- lag
    terrorblade_conjure_image_oaa = 1,                   -- lag
    --tiny_toss = 1,                                     -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    tiny_toss_tree = 1,                                  -- self grief
    tiny_tree_grab = 1,                                  -- bugged, DOTA_UNIT_TARGET_TEAM_CUSTOM
    treant_eyes_in_the_forest = 1,                       -- bugged
    tusk_snowball = 1,                                   -- invulnerability
    undying_tombstone_grab = 1,                          -- grief, invulnerability
    --undying_soul_rip = 1,                              -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    --vengefulspirit_nether_swap = 1,                    -- uncomment if there are issues, DOTA_UNIT_TARGET_TEAM_CUSTOM
    visage_gravekeepers_cloak = 1,                       -- invulnerability
    visage_gravekeepers_cloak_oaa = 1,                   -- invulnerability
    visage_stone_form_self_cast = 1,                     -- self grief
    void_spirit_astral_step = 1,                         -- looping, bugged
    void_spirit_dissimilate = 1,                         -- invulnerability
    winter_wyvern_cold_embrace = 1,                      -- grief
    wisp_tether_break = 1,                               -- self grief
    witch_doctor_voodoo_switcheroo_oaa = 1,              -- invulnerability
    zuus_thundergods_wrath = 1,                          -- powerful, trolling (doesn't need vision)
  }
  self.low_chance_to_proc = {
    antimage_mana_overload = 1,                          -- lag
    beastmaster_call_of_the_wild_boar_oaa = 1,           -- lag
    beastmaster_call_of_the_wild_hawk = 1,               -- lag
    broodmother_spin_web = 1,                            -- bugs out the screen
    clinkz_burning_army = 1,                             -- lag
    clinkz_burning_barrage = 1,                          -- looping
    crystal_maiden_arcane_magic_oaa = 1,                 -- self grief in most cases
    dark_seer_wall_of_replica = 1,                       -- lag
    dark_willow_bramble_maze = 1,                        -- lag
    dawnbreaker_fire_wreath = 1,                         -- looping
    doom_bringer_doom = 1,                               -- powerful
    electrician_electric_shield = 1,                     -- self grief in most cases
    ember_spirit_sleight_of_fist = 1,                    -- invulnerability and looping
    enigma_black_hole = 1,                               -- powerful
    enigma_demonic_conversion = 1,                       -- lag
    enigma_demonic_conversion_oaa = 1,                   -- lag
    eul_typhoon_oaa = 1,                                 -- lag
    faceless_void_chronosphere = 1,                      -- powerful
    faceless_void_time_dilation = 1,                     -- powerful
    faceless_void_time_walk = 1,                         -- invulnerability and looping with scepter
    faceless_void_time_zone = 1,                         -- powerful
    furion_force_of_nature = 1,                          -- lag
    hoodwink_acorn_shot = 1,                             -- looping
    hoodwink_decoy = 1,                                  -- lag
    invoker_chaos_meteor = 1,                            -- lag and maybe crash
    invoker_exort = 1,                                   -- self grief in most cases
    invoker_forge_spirit = 1,                            -- self grief in most cases
    invoker_invoke = 1,                                  -- self grief in most cases
    invoker_quas = 1,                                    -- self grief in most cases
    invoker_wex = 1,                                     -- self grief in most cases
    juggernaut_omnislash = 1,                            -- invulnerability and looping
    juggernaut_swift_slash = 1,                          -- invulnerability and looping
    kez_echo_slash = 1,                                  -- looping
    kez_switch_weapons = 1,                              -- self grief in most cases
    kunkka_torrent_storm = 1,                            -- lag
    leshrac_diabolic_edict = 1,                          -- powerful
    lone_druid_spirit_bear = 1,                          -- self grief in most cases
    lycan_summon_wolves = 1,                             -- self grief in most cases
    mars_bulwark = 1,                                    -- self grief in most cases, looping with scepter
    mars_gods_rebuke = 1,                                -- looping
    medusa_stone_gaze = 1,                               -- powerful
    mirana_leap = 1,                                     -- self grief in most cases
    --monkey_king_boundless_strike = 1,                  -- looping, sometimes doesn't do damage
    morphling_waveform = 1,                              -- invulnerability and looping with the facet
    muerta_pierce_the_veil = 1,                          -- powerful
    muerta_the_calling = 1,                              -- lag
    naga_siren_mirror_image = 1,                         -- invulnerability and lag
    naga_siren_song_of_the_siren = 1,                    -- self grief, trolling, sometimes unplayable
    nevermore_frenzy = 1,                                -- self grief in most cases
    obsidian_destroyer_astral_imprisonment = 1,          -- self grief, invulnerability, trolling
    oracle_fates_edict = 1,                              -- powerful, trolling
    pangolier_swashbuckle = 1,                           -- looping, powerful
    --phantom_assassin_stifling_dagger = 1,              -- looping
    phantom_lancer_juxtapose = 1,                        -- lag because of shard
    phantom_lancer_spirit_lance = 1,                     -- lag because of scepter
    --pugna_nether_ward_oaa = 1,                         -- lag
    --pugna_nether_ward = 1,                             -- lag
    rattletrap_power_cogs = 1,                           -- lag, annoying
    razor_eye_of_the_storm = 1,                          -- powerful
    shadow_demon_disruption = 1,                         -- self grief, invulnerability, trolling
    shadow_shaman_mass_serpent_ward = 1,                 -- lag
    shadow_shaman_mass_serpent_ward_oaa = 1,             -- lag
    silencer_global_silence = 1,                         -- powerful
    skeleton_king_bone_guard = 1,                        -- lag
    slark_depth_shroud = 1,                              -- untargettable melee hero, powerful
    slark_shadow_dance = 1,                              -- untargettable melee hero, powerful
    sniper_take_aim = 1,                                 -- self grief in most cases
    tidehunter_anchor_smash = 1,                         -- looping
    tidehunter_kraken_shell = 1,                         -- self grief in most cases
    tinkerer_laser_contraption = 1,                      -- lag
    troll_warlord_battle_trance = 1,                     -- self grief or unkillable
    undying_tombstone = 1,                               -- lag
    ursa_enrage = 1,                                     -- infinite
    venomancer_plague_ward = 1,                          -- lag
    visage_summon_familiars = 1,                         -- self grief in most cases
    visage_summon_familiars_oaa = 1,                     -- self grief in most cases
    void_spirit_aether_remnant = 1,                      -- lag
    warlock_rain_of_chaos = 1,                           -- lag
    weaver_time_lapse = 1,                               -- self grief or unkillable
    wisp_relocate = 1,                                   -- self grief in most cases
    zuus_cloud_oaa = 1,                                  -- lag
    zuus_heavenly_jump = 1,                              -- self grief in most cases
  }
end

if IsServer() then
  function modifier_magus_oaa:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacker is dead or silenced
    if not attacker:IsAlive() or attacker:IsSilenced() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is invulnerable, spell immune or dead
    if target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() or target:IsMagicImmune() then
      return
    end

    -- Don't proc if Magus is on cooldown
    if attacker:HasModifier("modifier_magus_cooldown_oaa") then
      return
    end

    local number = RandomInt(1, 100)
    if number <= self.chance then
      local lucky = number <= self.penalty_chance

      local go_on_cd = self:CastASpell(attacker, target, lucky)

      -- Start cooldown by adding a modifier
      if go_on_cd then
        attacker:AddNewModifier(attacker, nil, "modifier_magus_cooldown_oaa", {duration = self.cooldown})
      end
    end
  end
end

function modifier_magus_oaa:CastASpell(caster, target, lucky)
  local ability = self:GetRandomSpell(caster)

  if not ability then
    return true
  end

  local name = ability:GetAbilityName()
  if self.low_chance_to_proc[name] and not lucky then
    return false
  end

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
  local real_target = target
  local isNoTarget = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) > 0
  local isUnitTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) > 0
  local isPointTargetting = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0
  local isChannel = bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) > 0

  -- If bit.band of behavior is malfunctioning or we somehow got an invalid ability, recheck the kv of the ability
  if not isNoTarget and not isUnitTargetting and not isPointTargetting then
    local ability_data = GetAbilityKeyValuesByName(name)
    if not ability_data then
      return true
    end
    behavior = ability_data.AbilityBehavior
    if not behavior then
      return true
    end
    isNoTarget = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_NO_TARGET")
    isUnitTargetting = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET")
    isPointTargetting = string.find(behavior, "DOTA_ABILITY_BEHAVIOR_POINT")
    if not isNoTarget and not isUnitTargetting and not isPointTargetting then
      return true
    end
  end

  if target_team == DOTA_UNIT_TARGET_TEAM_FRIENDLY then
    real_target = self:FindRandomAlly(ability, target) or caster
  elseif target_team == DOTA_UNIT_TARGET_TEAM_BOTH then
    local rand = RandomInt(1, 4)
    if rand == 1 then
      real_target = caster
    elseif rand == 2 then
      real_target = self:FindRandomAlly(ability, target) or caster
    elseif rand == 3 then
      real_target = target
    else
      real_target = self:FindRandomEnemy(ability, target) or target
    end
  end

  if real_target then
    local real_caster = caster or ability:GetCaster()

    if isUnitTargetting then
      -- Spell Block check
      if real_target:TriggerSpellAbsorb(ability) and real_target:GetTeamNumber() ~= real_caster:GetTeamNumber() then
        return true
      end
      real_caster:SetCursorCastTarget(real_target)
    end

    if isPointTargetting then
      local target_loc = real_target:GetAbsOrigin()
      local caster_loc = real_caster:GetAbsOrigin()

      -- This shouldn't happen but it happens sometimes
      if not target_loc then
        target_loc = caster_loc
      end

      local distance = (target_loc - caster_loc):Length2D()
      local buffer = 250
      local base_cast_range = ability:GetCastRange(caster_loc, nil) -- it could return a weird result for global range abilities
      local eff_cast_range = ability:GetEffectiveCastRange(caster_loc, nil) -- it could return a weird result for global range abilities

      -- Checking cast range like this just in case if 'GetEffectiveCastRange' is not working
      -- and setting new target location to prevent global stuff
      if (distance > (base_cast_range + real_caster:GetCastRangeBonus()) and base_cast_range > 0) or (distance >= (real_caster:GetAttackRange() + buffer)) or (distance > eff_cast_range and eff_cast_range > 0) then
        target_loc = caster_loc + real_caster:GetForwardVector() * buffer
      end
      real_caster:SetCursorPosition(target_loc)
    end

    if isChannel then
      -- Channeling spells never end so we need to create a dummy and cast the spell
      return false
    end

    ability:OnAbilityPhaseStart()
    ability:OnSpellStart()
  end

  return true
end

function modifier_magus_oaa:GetRandomSpell(caster)
  if not caster or caster:IsIllusion() or caster:IsTempestDouble() then
    return nil
  end

  local candidates = {}
  for i = 0, caster:GetAbilityCount()-1 do
    local ability = caster:GetAbilityByIndex(i)
    if ability then
      if not ability:IsItem() and not ability:IsHidden() and not ability:IsToggle() and ability:IsTrained() and not ability:IsPassive() and not self.ignore_abilities[ability:GetName()] then
        table.insert(candidates, ability)
      end
    end
  end

  if #candidates > 0 then
    return candidates[RandomInt(1, #candidates)]
  end

  return nil
end

function modifier_magus_oaa:FindRandomAlly(ability, target)
  local random_ally
  local parent = self:GetParent()

  local allies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(parent:GetAbsOrigin(), parent),
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, ally in pairs(allies) do
    if ally and not ally:IsNull() and ally ~= parent and ally ~= target then
      random_ally = ally
      break
    end
  end

  return random_ally
end

function modifier_magus_oaa:FindRandomEnemy(ability, target)
  local random_enemy
  local parent = self:GetParent()

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    ability:GetEffectiveCastRange(parent:GetAbsOrigin(), nil),
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    ability:GetAbilityTargetType(),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and enemy ~= target then
      random_enemy = enemy
      break
    end
  end

  return random_enemy
end

function modifier_magus_oaa:GetTexture()
  return "warlock_golem_flaming_fists"
end

---------------------------------------------------------------------------------------------------

modifier_magus_cooldown_oaa = class(ModifierBaseClass)

function modifier_magus_cooldown_oaa:IsHidden()
  return true
end

function modifier_magus_cooldown_oaa:IsDebuff()
  return false
end

function modifier_magus_cooldown_oaa:IsPurgable()
  return false
end
