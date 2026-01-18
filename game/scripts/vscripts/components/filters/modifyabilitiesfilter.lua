-- This module is for modifying vanilla abilities and modifiers through filters without reworking them completely
if ModifyAbilitiesFilter == nil then
  ModifyAbilitiesFilter = class({})
end

function ModifyAbilitiesFilter:Init()
  self.moduleName = "ModifyAbilitiesFilter"

  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ModifierFilter"))
  --FilterManager:AddFilter(FilterManager.TrackingProjectile, self, Dynamic_Wrap(ModifyAbilitiesFilter, "ProjectileFilter"))
  --FilterManager:AddFilter(FilterManager.AbilityTuningValue, self, Dynamic_Wrap(ModifyAbilitiesFilter, "TuningValuesFilter"))
end

function ModifyAbilitiesFilter:ModifierFilter(keys)
  -- Remove fountain invulnerability
  if keys.name_const == "modifier_fountain_invulnerability" then
    return false
  end

  if not keys.entindex_parent_const or not keys.entindex_caster_const or not keys.entindex_ability_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local victim = EntIndexToHScript(keys.entindex_parent_const)
  local ability = EntIndexToHScript(keys.entindex_ability_const)
  local modifier_name = keys.name_const
  local modifier_duration = keys.duration

  local ability_name
  if ability then
    ability_name = ability:GetName()
  end

  if ability_name == "nevermore_requiem" and (modifier_name == "modifier_nevermore_requiem_slow" or modifier_name == "modifier_nevermore_requiem_fear") then
    if victim:HasModifier("modifier_oaa_requiem_not_allowed") then
      return false
    end
    if caster:HasScepter() and not victim:HasModifier("modifier_oaa_requiem_allowed") then
      local max_duration = ability:GetSpecialValueFor("requiem_slow_duration_max") + 1.5 * (ability:GetSpecialValueFor("requiem_radius") / ability:GetSpecialValueFor("requiem_line_speed"))
      victim:AddNewModifier(caster, ability, "modifier_oaa_requiem_allowed", {duration = math.min(max_duration, 6.5), immune_time = 2})
    end
  elseif ability_name == "faceless_void_time_dilation" and modifier_name == "modifier_faceless_void_time_dilation_slow" then
    victim:AddNewModifier(caster, ability, "modifier_faceless_void_time_dilation_degen_oaa", {duration = modifier_duration})
    victim:ApplyNonStackableBuff(caster, ability, "modifier_item_enhancement_crude", modifier_duration)
  elseif (ability_name == "elder_titan_natural_order" or ability_name == "elder_titan_natural_order_spirit") and modifier_name == "modifier_elder_titan_natural_order_magic_resistance" then
    if not victim:HasModifier("modifier_elder_titan_natural_order_correction_oaa") and ability:GetLevel() > 4 and not victim:IsOAABoss() then
      victim:AddNewModifier(caster, ability, "modifier_elder_titan_natural_order_correction_oaa", {})
    end
  elseif ability_name == "tidehunter_anchor_smash" and modifier_name == "modifier_tidehunter_anchor_smash" and victim:IsOAABoss() then
    victim:AddNewModifier(caster, ability, "modifier_tidehunter_anchor_smash_oaa_boss", {duration = modifier_duration})
    return false
  elseif ability_name == "rubick_fade_bolt" and modifier_name == "modifier_rubick_fade_bolt_debuff" and victim:IsOAABoss() then
    victim:AddNewModifier(caster, ability, "modifier_rubick_fade_bolt_debuff_oaa_boss", {duration = modifier_duration})
    return false
  elseif modifier_name == "modifier_windrunner_windrun_invis" then
    victim:AddNewModifier(caster, ability, "modifier_windranger_scepter_oaa", {duration = modifier_duration})
    return false
  elseif modifier_name == "modifier_muerta_pierce_the_veil_buff" then
    victim:AddNewModifier(caster, ability, "modifier_muerta_pierce_the_veil_penalty_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_skeleton_king_reincarnation_scepter_active" then
    victim:AddNewModifier(caster, ability, "modifier_wraith_form_penalty_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_legion_commander_duel" and caster:HasScepter() then
    if victim ~= caster then
      victim:AddNewModifier(caster, ability, "modifier_legion_duel_debuff_oaa", {duration = modifier_duration})
    -- else
      -- victim:AddNewModifier(caster, ability, "modifier_legion_duel_buff_oaa", {duration = modifier_duration})
    end
  elseif ability_name == "viper_viper_strike" and modifier_name ~= "modifier_viper_viper_strike_silence" then
    local talent = caster:FindAbilityByName("special_bonus_unique_viper_3_oaa")
    if talent and talent:GetLevel() > 0 then
      -- Basic Dispel (for enemies)
      local RemovePositiveBuffs = true
      local RemoveDebuffs = false
      local BuffsCreatedThisFrameOnly = false
      local RemoveStuns = false
      local RemoveExceptions = false
      victim:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)
      -- Viper Strike Silences
      victim:AddNewModifier(caster, ability, "modifier_viper_viper_strike_silence", {duration = modifier_duration})
    end
  elseif modifier_name == "modifier_mars_arena_of_blood_leash" and victim ~= caster then
    local facet = caster:GetHeroFacetID()
    if tostring(facet) == "2" then
      victim:AddNewModifier(caster, ability, "modifier_mars_arena_of_blood_leash_oaa", {})
    end
  elseif modifier_name == "modifier_wisp_relocate_return" then
    victim:AddNewModifier(caster, ability, "modifier_wisp_relocate_shield_oaa", {})
  elseif modifier_name == "modifier_bristleback_warpath_active" then
    victim:AddNewModifier(caster, ability, "modifier_bristleback_seeing_red_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_slark_shadow_dance_aura" then
    victim:AddNewModifier(caster, ability, "modifier_slark_shadow_dance_oaa", {duration = modifier_duration})
  elseif modifier_name == "modifier_item_overwhelming_blink_debuff" and ability_name ~= "item_overwhelming_blink" then
    victim:AddNewModifier(caster, ability, "modifier_item_overwhelming_blink_debuff_oaa", {duration = modifier_duration})
  end

  local real_caster = caster
  if caster.IsRealHero == nil then
    -- Caster is something weird
    -- try to find the real caster
    local owner = caster:GetOwner()
    local playerID = UnitVarToPlayerID(caster)
    local ownerID = UnitVarToPlayerID(owner)
    if playerID ~= -1 then
      real_caster = PlayerResource:GetSelectedHeroEntity(playerID)
    elseif ownerID ~= -1 then
      real_caster = PlayerResource:GetSelectedHeroEntity(ownerID)
    end
  elseif caster:IsPhantom() or caster:IsPhantomBlocker() or caster:IsOther() then
    -- Caster is a thinker, a ward-like unit or a phantom blocker
    local playerID = UnitVarToPlayerID(caster)
    if playerID ~= -1 then
      real_caster = PlayerResource:GetSelectedHeroEntity(playerID)
    end
  end

  if real_caster:HasModifier("modifier_item_nether_core") and modifier_duration ~= -1 and modifier_duration > 0.5 then
    local nether_core_mod = real_caster:FindModifierByNameAndCaster("modifier_item_nether_core", real_caster)
    if nether_core_mod and nether_core_mod:IsFirstItemInInventory() then
      local nether_core_item = nether_core_mod:GetAbility()
      if nether_core_item then
        local duration_decrease = nether_core_item:GetSpecialValueFor("modifier_duration_decrease")
        local exceptions = {
          modifier_battlemage_cooldown_oaa = true,
          modifier_bloodseeker_bloodbath_thinker = true,
          modifier_dark_willow_cursed_crown = true,
          modifier_dawnbreaker_solar_guardian_air_time = true,
          modifier_echo_strike_cooldown_oaa = true,
          modifier_elder_titan_earth_splitter_thinker = true,
          modifier_invoker_sun_strike = true,
          modifier_invoker_sun_strike_cataclysm = true,
          modifier_item_bubble_orb_effect_cd = true,
          modifier_item_crimson_guard_nostack = true,
          modifier_item_harpoon_internal_cd = true,
          modifier_item_mekansm_noheal = true,
          modifier_item_reflex_core_cooldown = true,
          modifier_item_sphere_target = true,
          modifier_item_ward_true_sight = true,
          modifier_keeper_of_the_light_illuminate = true,
          modifier_magnataur_skewer_movement = true,
          modifier_magus_cooldown_oaa = true,
          modifier_manta = true,
          modifier_marci_unleash_flurry_cooldown = true,
          modifier_observer_ward_recharger = true,
          modifier_phoenix_sun = true,
          modifier_primal_beast_onslaught_movement_adjustable = true,
          modifier_primal_beast_onslaught_windup = true,
          modifier_pull_staff_echo_strike_cd = true,
          modifier_roshan_bash_cooldown_oaa = true,
          modifier_sentry_ward_recharger = true,
          modifier_shredder_reactive_armor = true,
          modifier_spell_block_cooldown_oaa = true,
          modifier_techies_sticky_bomb_countdown = true,
          modifier_teleporting = true,
          modifier_ui_custom_observer_ward_charges = true,
          modifier_ui_custom_sentry_ward_charges = true,
        }
        local isDebuff = victim:GetTeamNumber() ~= caster:GetTeamNumber()
        local allowed
        -- Enable buff duration decrease if we cannot determine if the buff is applied by an ability or item, check if debuff later
        if not ability then
          allowed = true
        else
          -- Disable buff duration decrease for items and passive abilities without cooldown
          if ability:IsItem() or (ability:IsPassive() and ability:GetCooldown(-1) == 0) then
            allowed = false
          else
            allowed = true
          end
        end
        -- Disable buff duration increase for debuffs and buffs on the exception list
        -- Exception list should contain 'internal cd buffs', delays and stuff that looks unnatural and scuffed
        if not exceptions[modifier_name] and allowed and not isDebuff then
          keys.duration = modifier_duration * (100 - duration_decrease) / 100
        end
      end
    end
  end

  return true
end

function ModifyAbilitiesFilter:ProjectileFilter(keys)
  local source_index = keys.entindex_source_const
  local is_an_attack_projectile = keys.is_attack    -- values: 1 for yes or 0 for no

  local attacker
  if source_index then
    attacker = EntIndexToHScript(source_index)
  end

  if attacker and not attacker:IsNull() then
    if attacker:IsRealHero() and attacker:HasLearnedAbility("special_bonus_unique_wisp_4") and is_an_attack_projectile == 1 then
      if attacker:IsDisarmed() or attacker:IsStunned() or attacker:IsOutOfGame() or attacker:IsHexed() then
        return false
      end
    end
  end

  return true
end
