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
  local index
  for k, v in pairs(t) do
    if v == mod then
      table.remove(t, k)
      index = k
      break
    end
  end
  if index then
    table.remove(t, index)
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
  local name = parent:GetUnitName()

  self.modifier_list = {
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
    --"modifier_courier_kill_bonus_oaa",
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
    --"modifier_no_health_bar_oaa",
    "modifier_octarine_soul_oaa",
    "modifier_outworld_attack_oaa",
    "modifier_range_increase_oaa",
    "modifier_rend_oaa",
    --"modifier_rich_man_oaa",
    "modifier_roshan_power_oaa",
    "modifier_sorcerer_oaa",
    "modifier_speedster_oaa",
    "modifier_spell_block_oaa",
    "modifier_spoons_stash_oaa",
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

  for _, v in pairs(healer_heroes) do
    if name == v then
      table.insert(self.modifier_list, "modifier_healer_oaa")
    end
  end

  -- Remove Attack Range Switch from ranged heroes
  if name ~= "npc_dota_hero_lone_druid" and parent:IsRangedAttacker() then
    remove_mod_from_table(self.modifier_list, "modifier_troll_switch_oaa")
  end

  -- Add/remove some modifiers for Huskar
  if name == "npc_dota_hero_huskar" then
    remove_mod_from_table(self.modifier_list, "modifier_outworld_attack_oaa")
    remove_mod_from_table(self.modifier_list, "modifier_wisdom_oaa")
  end

  -- Add some modifiers for Medusa
  if name == "npc_dota_hero_medusa" then
    table.insert(self.modifier_list, "modifier_glass_cannon_oaa")
    table.insert(self.modifier_list, "modifier_puny_oaa")
  end

  -- Add/remove some modifiers for Ogre Magi
  if name == "npc_dota_hero_ogre_magi" then
    table.insert(self.modifier_list, "modifier_no_brain_oaa")
    remove_mod_from_table(self.modifier_list, "modifier_bad_design_2_oaa")
    remove_mod_from_table(self.modifier_list, "modifier_octarine_soul_oaa")
  end

  -- Add some modifiers for Tiny
  if name == "npc_dota_hero_tiny" then
    table.insert(self.modifier_list, "modifier_cursed_attack_oaa")
  end

  self.max_duration = 2 * 60 -- 2 minutes
  self.on_respawn_chance = 0

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
  }
end

if IsServer() then
  function modifier_ludo_oaa:ChangeModifier(hero)
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

    if self.on_respawn_chance == 100 then
      -- Reset think interval and change the modifier
      self:StartIntervalThink(self.max_duration)
      self:ChangeModifier(parent)
      self.on_respawn_chance = 0
    end
  end
end

function modifier_ludo_oaa:GetTexture()
  return "item_fluffy_hat"
end
