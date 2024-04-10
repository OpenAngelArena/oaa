modifier_ludo_oaa = class(ModifierBaseClass)

function modifier_ludo_oaa:IsHidden()
  return false
end

function modifier_ludo_oaa:IsDebuff()
  return false
end

function modifier_ludo_oaa:IsPurgable()
  return false
end

function modifier_ludo_oaa:RemoveOnDeath()
  return false
end

local function remove_mod_from_table(t, mod)
  for k, v in pairs(t) do
    if v == mod then
      table.remove(t, k)
    end
  end
end

local function TableContains(t, element)
  if t == nil then return false end
  for _, v in pairs(t) do
    if v == element then
      return true
    end
  end
  return false
end

function modifier_ludo_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  self.modifier_list = {
    "modifier_all_healing_amplify_oaa",
    "modifier_angel_oaa",
    "modifier_any_damage_crit_oaa",
    "modifier_any_damage_lifesteal_oaa",
    "modifier_any_damage_splash_oaa",
    "modifier_aoe_radius_increase_oaa",
    "modifier_battlemage_oaa",
    "modifier_blood_magic_oaa",
    "modifier_bonus_armor_negative_magic_resist_oaa",
    "modifier_boss_killer_oaa",
    "modifier_bottle_collector_oaa",
    "modifier_brawler_oaa",
    "modifier_brute_oaa",
    "modifier_crimson_magic_oaa",
    --"modifier_courier_kill_bonus_oaa",
    "modifier_cursed_attack_oaa",
    "modifier_debuff_duration_oaa",
    "modifier_diarrhetic_oaa",
    "modifier_drunk_oaa",
    "modifier_duelist_oaa",
    "modifier_echo_strike_oaa",
    "modifier_explosive_death_oaa",
    "modifier_glass_cannon_oaa",
    "modifier_ham_oaa",
    "modifier_hero_anti_stun_oaa",
    "modifier_hp_mana_switch_oaa",
    "modifier_hybrid_oaa",
    "modifier_magus_oaa",
    "modifier_mr_phys_weak_oaa",
    "modifier_nimble_oaa",
    "modifier_no_brain_oaa",
    "modifier_no_cast_points_oaa",
    "modifier_no_health_bar_oaa",
    "modifier_octarine_soul_oaa",
    "modifier_pro_active_oaa",
    "modifier_range_increase_oaa",
    "modifier_rend_oaa",
    --"modifier_rich_man_oaa",
    "modifier_roshan_power_oaa",
    "modifier_smurf_oaa",
    "modifier_sorcerer_oaa",
    "modifier_speedster_oaa",
    "modifier_spell_block_oaa",
    "modifier_titan_soul_oaa",
    "modifier_troll_switch_oaa",
    "modifier_true_sight_strike_oaa",
    "modifier_wisdom_oaa",
  }

  self.already_had = {}

  local healer_heroes = {
    "npc_dota_hero_abaddon",
    "npc_dota_hero_chen",
    "npc_dota_hero_dawnbreaker",
    "npc_dota_hero_dazzle",
    "npc_dota_hero_death_prophet",
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
    if parent:GetUnitName() == v then
      table.insert(self.modifier_list, "modifier_healer_oaa")
    end
  end

  -- Remove Blood Magic modifier for some heroes
  for _, v in pairs(bad_blood_magic_heroes) do
    if parent:GetUnitName() == v then
      remove_mod_from_table(self.modifier_list, "modifier_blood_magic_oaa")
    end
  end

  -- Remove Cursed Attack modifier from AGI heroes, No Brain modifier from INT heroes and
  -- Glass Cannon from STR heroes
  if parent:GetPrimaryAttribute() == DOTA_ATTRIBUTE_AGILITY then
    remove_mod_from_table(self.modifier_list, "modifier_cursed_attack_oaa")
  elseif parent:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT then
    remove_mod_from_table(self.modifier_list, "modifier_no_brain_oaa")
  elseif parent:GetPrimaryAttribute() == DOTA_ATTRIBUTE_STRENGTH then
    remove_mod_from_table(self.modifier_list, "modifier_glass_cannon_oaa")
  end

  self.max_duration = 2 * 60 -- 2 minutes
  self.on_respawn_chance = 5
  self.on_kill_chance = 5

  -- Add an actual random modifier after a delay
  self:StartIntervalThink(1)
end

function modifier_ludo_oaa:OnIntervalThink()
  local parent = self:GetParent()
  if not self.initialized then
    -- Add a random modifier after 1 second delay
    -- this part of the code is slightly different from ChangeModifier code
    local random_mod = self.modifier_list[RandomInt(1, #self.modifier_list)]
    if not parent:HasModifier(random_mod) then
      self.actual_mod = parent:AddNewModifier(parent, nil, random_mod, {duration = self.max_duration})
      self.last_mod = random_mod
    else
      -- Remove the found modifier from the lists
      remove_mod_from_table(self.modifier_list, random_mod)

      local new_random = self.modifier_list[RandomInt(1, #self.modifier_list)]
      if not parent:HasModifier(new_random) then
        self.actual_mod = parent:AddNewModifier(parent, nil, new_random, {duration = self.max_duration})
        self.last_mod = new_random
      end
    end
    -- Make sure the code above doesn't happen again
    self.initialized = true
    -- Run code in the else branch after the duration
    self:StartIntervalThink(self.max_duration)
  else
    -- Change the modifier after max allowed duration
    if parent:IsAlive() then
      self:ChangeModifier(parent)
    else
      self.on_respawn_chance = 100
    end
  end
end

function modifier_ludo_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_EVENT_ON_HERO_KILLED,
  }
end

if IsServer() then
  function modifier_ludo_oaa:ChangeModifier(hero)
    if self.last_mod then
      local mod = self.last_mod
      if self.actual_mod and self.actual_mod:GetName() == mod then
        self.actual_mod:Destroy()
      else
        hero:RemoveModifierByName(mod)
      end

      -- Add old modifier to already_had table
      if not TableContains(self.already_had, mod) then
        table.insert(self.already_had, mod)
      end

      -- Remove the modifier from the table because hero already had it
      remove_mod_from_table(self.modifier_list, mod)

      -- Reset tables if low amount of elements
      if #self.modifier_list < 2 then
        self.modifier_list = self.already_had
      end
    end

    if self.last_mod == "modifier_blood_magic_oaa" then
      hero:GiveMana(hero:GetMaxMana() + 1)
    end

    local repeat_loop = true
    while repeat_loop do
      local random_mod = self.modifier_list[RandomInt(1, #self.modifier_list)]
      if random_mod ~= self.last_mod and not hero:HasModifier(random_mod) then
        self.actual_mod = hero:AddNewModifier(hero, nil, random_mod, {duration = self.max_duration})
        self.last_mod = random_mod
        repeat_loop = false
      end
    end
  end

  function modifier_ludo_oaa:OnRespawn(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if not parent:IsRealHero() or parent:IsTempestDouble() then
      return
    end

    if RandomInt(1, 100) <= self.on_respawn_chance then
      -- Reset think interval and change the modifier
      self:StartIntervalThink(self.max_duration)
      self:ChangeModifier(parent)
      self.on_respawn_chance = 5
    end
  end

  function modifier_ludo_oaa:OnHeroKilled(event)
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
        -- Reset think interval and change the modifier
        self:StartIntervalThink(self.max_duration)
        self:ChangeModifier(parent)
      else
        self.on_respawn_chance = 100
      end
    end
  end
end

function modifier_ludo_oaa:GetTexture()
  return "item_fluffy_hat"
end
