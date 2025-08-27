modifier_chaos_oaa = class(ModifierBaseClass)

function modifier_chaos_oaa:IsHidden()
  return self:GetElapsedTime() > 5 * 60
end

function modifier_chaos_oaa:IsDebuff()
  return false
end

function modifier_chaos_oaa:IsPurgable()
  return false
end

function modifier_chaos_oaa:RemoveOnDeath()
  return false
end

local function remove_mod_from_table(t, mod)
  local index
  for k, v in pairs(t) do
    if v == mod then
      index = k
      break
    end
  end
  if index then
    table.remove(t, index)
  end
end

-- local function TableContains(t, element)
  -- if t == nil then return false end
  -- for _, v in pairs(t) do
    -- if v == element then
      -- return true
    -- end
  -- end
  -- return false
-- end

function modifier_chaos_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local name = parent:GetUnitName()

  self.initial_modifiers = {
    "modifier_any_damage_splash_oaa",
    "modifier_blood_magic_oaa",
    "modifier_bonus_armor_negative_magic_resist_oaa",
    "modifier_bottle_collector_oaa",
    "modifier_brawler_oaa",
    "modifier_courier_kill_bonus_oaa",
    "modifier_diarrhetic_oaa",
    "modifier_drunk_oaa",
    "modifier_duelist_oaa",
    "modifier_glass_cannon_oaa",
    --"modifier_hero_anti_stun_oaa",
    "modifier_hp_mana_switch_oaa",
    "modifier_hybrid_oaa",
    "modifier_pro_active_oaa",
    "modifier_rend_oaa",
    --"modifier_rich_man_oaa",
    "modifier_roshan_power_oaa",
    "modifier_smurf_oaa",
    "modifier_sorcerer_oaa",
    "modifier_titan_soul_oaa",
    "modifier_troll_switch_oaa",
  }

  -- This table should contain ALL chaos modifiers (modifiers with downsides)
  -- and ALL niche modifiers except Courier Hunter and Wealthy
  self.chaos_modifiers = {
    "modifier_angel_oaa", -- chaos
    "modifier_blood_magic_oaa", -- chaos
    "modifier_bonus_armor_negative_magic_resist_oaa", -- chaos
    "modifier_boss_killer_oaa", -- niche
    "modifier_brawler_oaa", -- niche
    "modifier_cursed_attack_oaa", -- chaos
    "modifier_drunk_oaa", -- chaos
    "modifier_duelist_oaa", -- niche
    "modifier_glass_cannon_oaa", -- chaos
    "modifier_hero_anti_stun_oaa", -- niche
    "modifier_hp_mana_switch_oaa", -- chaos
    "modifier_mr_phys_weak_oaa", -- chaos
    "modifier_no_brain_oaa", -- chaos
    "modifier_no_health_bar_oaa", -- chaos
    "modifier_pro_active_oaa", -- chaos
    "modifier_puny_oaa", -- chaos
    "modifier_roshan_power_oaa", -- chaos
    "modifier_smurf_oaa", -- chaos
    "modifier_troll_switch_oaa", -- chaos
    "modifier_true_sight_strike_oaa", -- niche
  }

  -- This table should NOT contain chaos modifiers (modifiers with downsides)
  -- but it should contain ALL good modifiers (even if they are niche)
  self.good_modifiers = {
    "modifier_all_healing_amplify_oaa",
    "modifier_any_damage_crit_oaa",
    "modifier_any_damage_lifesteal_oaa",
    "modifier_any_damage_splash_oaa",
    "modifier_aoe_radius_increase_oaa",
    "modifier_bad_design_1_oaa",
    "modifier_bad_design_2_oaa",
    "modifier_battlemage_oaa",
    "modifier_boss_killer_oaa",
    "modifier_bottle_collector_oaa",
    "modifier_brawler_oaa",
    "modifier_brute_oaa",
    "modifier_crimson_magic_oaa",
    "modifier_debuff_duration_oaa",
    "modifier_diarrhetic_oaa",
    "modifier_duelist_oaa",
    "modifier_echo_strike_oaa",
    "modifier_explosive_death_oaa",
    "modifier_ham_oaa",
    "modifier_hero_anti_stun_oaa",
    "modifier_hybrid_oaa",
    "modifier_magus_oaa",
    "modifier_multicast_oaa",
    "modifier_nimble_oaa",
    "modifier_no_cast_points_oaa",
    "modifier_octarine_soul_oaa",
    "modifier_outworld_attack_oaa",
    "modifier_range_increase_oaa",
    "modifier_rend_oaa",
    "modifier_sorcerer_oaa",
    "modifier_speedster_oaa",
    "modifier_spell_block_oaa",
    "modifier_spoons_stash_oaa",
    "modifier_titan_soul_oaa",
    "modifier_true_sight_strike_oaa",
    "modifier_wisdom_oaa",
  }

  local healer_heroes = {
    "npc_dota_hero_abaddon",
    "npc_dota_hero_chen",
    "npc_dota_hero_dawnbreaker",
    "npc_dota_hero_dazzle",
    "npc_dota_hero_enchantress",
    "npc_dota_hero_faceless_void",
    "npc_dota_hero_keeper_of_the_light",
    "npc_dota_hero_necrolyte",
    "npc_dota_hero_omniknight",
    "npc_dota_hero_oracle",
    "npc_dota_hero_phoenix",
    "npc_dota_hero_pugna",
    "npc_dota_hero_shadow_demon",
    "npc_dota_hero_sohei",
    "npc_dota_hero_tinker",
    "npc_dota_hero_treant",
    "npc_dota_hero_undying",
    "npc_dota_hero_warlock",
    "npc_dota_hero_winter_wyvern",
    "npc_dota_hero_wisp",
    "npc_dota_hero_witch_doctor",
  }

  local bad_blood_magic_heroes = {
    "npc_dota_hero_ancient_apparition",
    "npc_dota_hero_clinkz",
    "npc_dota_hero_drow_ranger",
    "npc_dota_hero_electrician",
    "npc_dota_hero_enchantress",
    "npc_dota_hero_huskar",
    "npc_dota_hero_keeper_of_the_light",
    "npc_dota_hero_leshrac",
    "npc_dota_hero_medusa",
    "npc_dota_hero_morphling",
    "npc_dota_hero_obsidian_destroyer",
    "npc_dota_hero_shredder",
    "npc_dota_hero_silencer",
    "npc_dota_hero_storm_spirit",
    "npc_dota_hero_tusk",
    "npc_dota_hero_viper",
    "npc_dota_hero_winter_wyvern",
    "npc_dota_hero_witch_doctor",
  }

  for _, v in pairs(healer_heroes) do
    if name == v then
      table.insert(self.good_modifiers, "modifier_healer_oaa")
    end
  end

  -- Add/remove some modifiers for Huskar
  if name == "npc_dota_hero_huskar" then
    table.insert(self.good_modifiers, "modifier_no_brain_oaa")
    remove_mod_from_table(self.good_modifiers, "modifier_outworld_attack_oaa")
    remove_mod_from_table(self.good_modifiers, "modifier_wisdom_oaa")
    remove_mod_from_table(self.initial_modifiers, "modifier_hp_mana_switch_oaa")
    remove_mod_from_table(self.chaos_modifiers, "modifier_hp_mana_switch_oaa")
  end

  -- Add some good modifiers for Medusa
  if name == "npc_dota_hero_medusa" then
    table.insert(self.good_modifiers, "modifier_glass_cannon_oaa")
    table.insert(self.good_modifiers, "modifier_puny_oaa")
  end

  -- Add/remove some modifiers for Ogre Magi
  if name == "npc_dota_hero_ogre_magi" then
    table.insert(self.good_modifiers, "modifier_no_brain_oaa")
    remove_mod_from_table(self.good_modifiers, "modifier_bad_design_2_oaa")
    remove_mod_from_table(self.good_modifiers, "modifier_octarine_soul_oaa")
  end

  -- Add some good modifiers for Tiny
  if name == "npc_dota_hero_tiny" then
    table.insert(self.good_modifiers, "modifier_cursed_attack_oaa")
  end

  -- Attack Range Switch is good for melee heroes
  if name ~= "npc_dota_hero_lone_druid" and not parent:IsRangedAttacker() then
    table.insert(self.good_modifiers, "modifier_troll_switch_oaa")
  end

  -- Remove Blood Magic modifier for some heroes
  for _, v in pairs(bad_blood_magic_heroes) do
    if name == v then
      remove_mod_from_table(self.initial_modifiers, "modifier_blood_magic_oaa")
      remove_mod_from_table(self.chaos_modifiers, "modifier_blood_magic_oaa")
    end
  end

  --self.already_had = {}
  self.modifier_list = self.chaos_modifiers

  self.min_duration = 2 * 60
  self.max_duration = 5 * 60
  self.on_respawn_chance = 25
  self.on_kill_chance = 25

  -- Add an actual random modifier after a delay
  self:StartIntervalThink(1)
end

function modifier_chaos_oaa:OnIntervalThink()
  local parent = self:GetParent()
  if not self.initialized then
    -- Remove Cursed Attack modifier from AGI heroes, No Brain modifier from INT heroes and
    -- Puny from STR heroes
    local attribute = parent:GetPrimaryAttribute()
    if attribute == DOTA_ATTRIBUTE_AGILITY then
      remove_mod_from_table(self.initial_modifiers, "modifier_cursed_attack_oaa")
      remove_mod_from_table(self.chaos_modifiers, "modifier_cursed_attack_oaa")
      remove_mod_from_table(self.good_modifiers, "modifier_cursed_attack_oaa")
      remove_mod_from_table(self.modifier_list, "modifier_cursed_attack_oaa")
    elseif attribute == DOTA_ATTRIBUTE_INTELLECT then
      remove_mod_from_table(self.initial_modifiers, "modifier_no_brain_oaa")
      remove_mod_from_table(self.chaos_modifiers, "modifier_no_brain_oaa")
      remove_mod_from_table(self.good_modifiers, "modifier_no_brain_oaa")
      remove_mod_from_table(self.modifier_list, "modifier_no_brain_oaa")
    elseif attribute == DOTA_ATTRIBUTE_STRENGTH then
      remove_mod_from_table(self.initial_modifiers, "modifier_puny_oaa")
      remove_mod_from_table(self.chaos_modifiers, "modifier_puny_oaa")
      remove_mod_from_table(self.good_modifiers, "modifier_puny_oaa")
      remove_mod_from_table(self.modifier_list, "modifier_puny_oaa")
    end

    local mod_duration = RandomInt(self.min_duration, self.max_duration)
    -- Add a random modifier after a delay
    -- this part of the code is slightly different from ChangeModifier code
    local random_mod = self.initial_modifiers[RandomInt(1, #self.initial_modifiers)]
    if not parent:HasModifier(random_mod) then
      self.actual_mod = parent:AddNewModifier(parent, nil, random_mod, {duration = mod_duration})
      self.last_mod = random_mod
    else
      -- Remove the found modifier from the lists
      remove_mod_from_table(self.initial_modifiers, random_mod)
      remove_mod_from_table(self.modifier_list, random_mod)
      remove_mod_from_table(self.chaos_modifiers, random_mod)
      remove_mod_from_table(self.good_modifiers, random_mod)

      local new_random = self.initial_modifiers[RandomInt(1, #self.initial_modifiers)]
      if not parent:HasModifier(new_random) then
        self.actual_mod = parent:AddNewModifier(parent, nil, new_random, {duration = mod_duration})
        self.last_mod = new_random
      end
    end
    -- Make sure the code above doesn't happen again
    self.initialized = true
    -- Run code in the else branch after the mod_duration
    self:StartIntervalThink(mod_duration)
  else
    -- Change the modifier after duration
    if parent:IsAlive() then
      self:ChangeModifier(parent)
    else
      self.on_respawn_chance = 100
    end
  end
end

function modifier_chaos_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_EVENT_ON_HERO_KILLED,
  }
end

if IsServer() then
  function modifier_chaos_oaa:ChangeModifier(hero)
    local mid_game_time_start = FIRST_DUEL_TIMEOUT + DUEL_INTERVAL
    local late_game_time_start = 3*mid_game_time_start
    local current_time = HudTimer:GetGameTime()

    if self.last_mod then
      local mod = self.last_mod
      if self.actual_mod and not self.actual_mod:IsNull() then
        if self.actual_mod:GetName() == mod then
          self.actual_mod:Destroy()
        else
          hero:RemoveModifierByName(self.actual_mod:GetName())
        end
      else
        hero:RemoveModifierByName(mod)
      end

      -- Add old modifier to already_had table
      -- if not TableContains(self.already_had, mod) and mod ~= "modifier_courier_kill_bonus_oaa" and mod ~= "modifier_rich_man_oaa" then
        -- table.insert(self.already_had, mod)
      -- end

      -- Remove the modifier from the table because hero already had it
      remove_mod_from_table(self.initial_modifiers, mod)
      remove_mod_from_table(self.modifier_list, mod)

      -- Reset tables if low amount of elements
      if #self.initial_modifiers < 2 then
        self.initial_modifiers = self.good_modifiers
      end
      if #self.modifier_list < 2 then
        self.modifier_list = self.good_modifiers
      end

      if mod == "modifier_blood_magic_oaa" then
        hero:GiveMana(hero:GetMaxMana() + 1)
      end
    end

    local repeat_loop = true
    while repeat_loop do
      local random_mod
      if current_time <= mid_game_time_start then
        random_mod = self.initial_modifiers[RandomInt(1, #self.initial_modifiers)]
      elseif current_time > mid_game_time_start and current_time <= late_game_time_start then
        random_mod = self.modifier_list[RandomInt(1, #self.modifier_list)]
      elseif current_time > late_game_time_start then
        random_mod = self.good_modifiers[RandomInt(1, #self.good_modifiers)]
      end
      if random_mod ~= self.last_mod and not hero:HasModifier(random_mod) then
        local mod_duration = RandomInt(self.min_duration, self.max_duration)
        -- Reset think interval and change the modifier
        self:StartIntervalThink(mod_duration)
        self.actual_mod = hero:AddNewModifier(hero, nil, random_mod, {duration = mod_duration})
        self.last_mod = random_mod
        repeat_loop = false
      end
    end
  end

  function modifier_chaos_oaa:OnRespawn(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if not parent:IsRealHero() or parent:IsTempestDouble() then
      return
    end

    if RandomInt(1, 100) <= self.on_respawn_chance then
      self:ChangeModifier(parent)
      self.on_respawn_chance = 25
    end
  end

  function modifier_chaos_oaa:OnHeroKilled(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local target = event.target

    -- Check if killer exists
    if not killer or killer:IsNull() then
      return
    end

    -- Don't continue if the killer doesn't belong to the parent
    if UnitVarToPlayerID(killer) ~= UnitVarToPlayerID(parent) then
      return
    end

    -- Ignore self denies and denying allies
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Don't trigger on Meepo Clones, Tempest Doubles and Spirit Bears
    if target:IsClone() or target:IsTempestDouble() or target:IsSpiritBearOAA() then
      return
    end

    if RandomInt(1, 100) <= self.on_kill_chance then
      -- Check if parent is dead
      if parent:IsAlive() then
        self:ChangeModifier(parent)
      else
        self.on_respawn_chance = 100
      end
    end
  end
end

function modifier_chaos_oaa:GetTexture()
  return "chaos_knight_chaos_strike"
end
