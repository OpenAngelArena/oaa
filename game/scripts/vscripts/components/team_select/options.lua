
--OAAOptions = Components:Register('OAAOptions', COMPONENT_GAME_SETUP)
if OAAOptions == nil then
  --Debug:EnableDebugging()
  DebugPrint('Starting OAAOptions module')
  OAAOptions = class({})
end

local hero_mods = {
  HMN  = false,
  --HM01 = "modifier_any_damage_lifesteal_oaa",
  HM02 = "modifier_aoe_radius_increase_oaa",
  HM03 = "modifier_blood_magic_oaa",
  HM04 = "modifier_debuff_duration_oaa",
  HM05 = "modifier_echo_strike_oaa",
  HM06 = "modifier_ham_oaa",
  HM07 = "modifier_no_cast_points_oaa",
  --HM08 = "modifier_physical_immunity_oaa",
  HM09 = "modifier_pro_active_oaa",
  --HM10 = "modifier_spell_block_oaa",
  HM11 = "modifier_troll_switch_oaa",
  HM12 = "modifier_hyper_experience_oaa",
  --HM13 = "modifier_diarrhetic_oaa",
  --HM14 = "modifier_rend_oaa",
  HM15 = "modifier_range_increase_oaa",
  --HM16 = "modifier_healer_oaa",
  HM17 = "modifier_explosive_death_oaa",
  --HM18 = "modifier_no_health_bar_oaa",
  HM19 = "modifier_brute_oaa",
  HM20 = "modifier_wisdom_oaa",
  HM21 = "modifier_aghanim_oaa",
  HM22 = "modifier_nimble_oaa",
  HM23 = "modifier_sorcerer_oaa",
  HM24 = "modifier_any_damage_crit_oaa",
  --HM25 = "modifier_hp_mana_switch_oaa",
  HM26 = "modifier_magus_oaa",
  --HM27 = "modifier_brawler_oaa",
  HM28 = "modifier_chaos_oaa",
  HM29 = "modifier_double_multiplier_oaa",
  --HM30 = "modifier_hybrid_oaa",
  --HM31 = "modifier_drunk_oaa",
  HM32 = "modifier_any_damage_splash_oaa",
  HM33 = "modifier_titan_soul_oaa",
  --HM34 = "modifier_hero_anti_stun_oaa",
  HM35 = "modifier_octarine_soul_oaa",
  --HM36 = "modifier_smurf_oaa",
  HM37 = "modifier_speedster_oaa",
  HM38 = "modifier_universal_oaa",
  HM39 = "modifier_rich_man_oaa",
  HM40 = "modifier_bottle_collector_oaa",
  HM41 = "modifier_crimson_magic_oaa",
  HM42 = "modifier_ludo_oaa",
  HM43 = "modifier_battlemage_oaa",
  HM44 = "modifier_multicast_oaa",
}
local boss_mods = {
  BMN  = false,
  BM01 = "modifier_any_damage_lifesteal_oaa",
  BM02 = "modifier_echo_strike_oaa",
  BM03 = "modifier_physical_immunity_oaa",
  --BM04 = "modifier_spell_block_oaa",
  BM05 = "modifier_no_cast_points_oaa",
  BM06 = "modifier_ham_oaa",
  BM07 = "modifier_boss_aggresive_oaa",
  BM08 = "modifier_brawler_oaa",
}
local global_mods = {
  GMN  = false,
  GM01 = false,--"modifier_any_damage_lifesteal_oaa",
  --GM02 = "modifier_aoe_radius_increase_oaa",
  --GM03 = "modifier_blood_magic_oaa",                    -- lags
  --GM04 = "modifier_debuff_duration_oaa",                -- doesn't work on non-hero units
  --GM05 = false, --"modifier_echo_strike_oaa",           -- lags
  --GM06 = "modifier_ham_oaa",                            -- mostly useless for neutral creeps
  --GM07 = "modifier_no_cast_points_oaa",                 -- mostly useless for any creep
  --GM08 = "modifier_physical_immunity_oaa",
  --GM09 = "modifier_pro_active_oaa",                     -- mostly useless for neutral creeps
  --GM10 = "modifier_spell_block_oaa",                    -- lags
  --GM11 = "modifier_troll_switch_oaa",                   -- lags
  GM12 = true,
}

local bundles = {
  HMBN = false,
  HMB01 = {"modifier_titan_soul_oaa", "modifier_brute_oaa", "modifier_aoe_radius_increase_oaa"}, -- Giant
  HMB02 = {"modifier_speedster_oaa", "modifier_no_cast_points_oaa", "modifier_ham_oaa"}, -- League
  HMB03 = {"modifier_rich_man_oaa", "modifier_hyper_experience_oaa", "modifier_boss_killer_oaa"}, -- Turbo
  HMB04 = {"modifier_echo_strike_oaa", "modifier_magus_oaa", "modifier_hybrid_oaa", "modifier_rend_oaa"}, -- Striker
  HMB05 = {"modifier_nimble_oaa", "modifier_speedster_oaa", "modifier_brawler_oaa", "modifier_change_to_agi_oaa"}, -- Cunning
  HMB06 = {"modifier_wisdom_oaa", "modifier_octarine_soul_oaa", "modifier_debuff_duration_oaa", "modifier_change_to_int_oaa"}, -- Magician
  HMB07 = {"modifier_brute_oaa", "modifier_smurf_oaa", "modifier_any_damage_crit_oaa", "modifier_change_to_str_oaa"}, -- Mighty
  HMB08 = {"modifier_sangromancer_oaa", "modifier_crimson_magic_oaa", "modifier_debuff_duration_oaa", "modifier_explosive_death_oaa"}, -- Sangromancer
  HMB09 = {"modifier_titan_soul_oaa", "modifier_diarrhetic_oaa", "modifier_any_damage_splash_oaa", "modifier_explosive_death_oaa"}, -- Radioactive
  HMB10 = {"modifier_titan_soul_oaa", "modifier_brute_oaa", "modifier_nimble_oaa", "modifier_wisdom_oaa", "modifier_universal_oaa"}, -- Jack-Of-All-Trades
}

function OAAOptions:Init ()
  --Debug:EnableDebugging()
  DebugPrint('OAAOptions module Initialization started!')
  self.moduleName = "OAA Game Mode Options"

  self.settings = {}
  self.settingsDefault = {}
  self.heroes_mods = {}

  self:InitializeSettingsTable()
  self:SaveSettings()

  CustomGameEventManager:RegisterListener("oaa_setting_changed", function(_, kv)
    self.settings[kv.setting] = kv.value
    self:SaveSettings()
    DebugPrint(kv.setting, ":", kv.value)
  end)

  CustomGameEventManager:RegisterListener("oaa_button_clicked", function(_, kv)
    local name = kv.button
    DebugPrint('Received button press ' .. name)
    if name == "RESET" then
      self:RestoreDefaults()
      self:SaveSettings()
    --elseif name == "RANDOMIZE" then
      --self.settings.HEROES_MODS = self:GetRandomModifier(hero_mods)
      --self.settings.HEROES_MODS_2 = self:GetRandomModifier(hero_mods)
      --self.settings.BOSSES_MODS = self:GetRandomModifier(boss_mods)
      --self.settings.GLOBAL_MODS = self:GetRandomModifier(global_mods)
      --self:SaveSettings()
    end
  end)

  GameEvents:OnHeroSelection(partial(OAAOptions.AdjustGameMode, OAAOptions))
  GameEvents:OnCustomGameSetup(partial(OAAOptions.ChangeDefaultSettings, OAAOptions))
  GameEvents:OnGameInProgress(partial(OAAOptions.SetupGame, OAAOptions))
  ChatCommand:LinkDevCommand("-testheromod", Dynamic_Wrap(OAAOptions, "TestHeroModifier"), OAAOptions)

  ListenToGameEvent("npc_spawned", Dynamic_Wrap(OAAOptions, 'OnUnitSpawn'), OAAOptions)

  DebugPrint('OAAOptions module Initialization finished!')
end

function OAAOptions:RestoreDefaults()
  for k, v in pairs(self.settingsDefault) do
    self.settings[k] = v
  end
  CustomNetTables:SetTableValue("oaa_settings", "settings", self.settings)
end

function OAAOptions:SaveSettings()
  CustomNetTables:SetTableValue("oaa_settings", "settings", self.settings)
end

function OAAOptions:SetupGame()
  local mode = GameRules:GetGameModeEntity()
  if self.settings.HEROES_MODS == "HM13" or self.settings.HEROES_MODS_2 == "HM13" then
    POOP_WARD_COOLDOWN = 30
    if CustomWardButtons then
      CustomWardButtons.obs_cooldown = 30
      CustomWardButtons.sentry_cooldown = 30
    end
  end
  if self.settings.HEROES_MODS == "HM21" or self.settings.HEROES_MODS_2 == "HM21" then
    mode:SetLoseGoldOnDeath(false)
  end
  if self.settings.GLOBAL_MODS == "GM12" then
    mode:SetBuybackEnabled(true)
  end
end

function OAAOptions:InitializeSettingsTable()
  self.settings = {
    GAME_MODE = "AP",                   -- "RD", "AR", "AP", "ARDM", "LP", "SD"
    small_player_pool = 0,              -- 1 - some heroes that are strong when there are 2-6 players are disabled; 0 - normal;
    HEROES_MODS = "HMN",
    HEROES_MODS_2 = "HMN",
    HEROES_MODS_BUNDLE = "HMBN",
    BOSSES_MODS = "BMN",
    GLOBAL_MODS = "GMN",
  }

  for k, v in pairs(self.settings) do
    self.settingsDefault[k] = v
  end
end

function OAAOptions:AdjustGameMode()
  --Debug:EnableDebugging()
  DebugPrint("OAAOptions Lock game mode settings and rules.")
  CustomNetTables:SetTableValue("oaa_settings", "locked", OAAOptions.settings)
  DeepPrintTable(self.settings)
  DebugPrint("OAAOptions Adjusting game mode settings and rules that were set by the host.")
  if self.settings.GAME_MODE == "ARDM" then
    DebugPrint("Initializing ARDM")
    if ARDMMode then
      ARDMMode:Init()
    end
  end

  if self.settings.HEROES_MODS ~= "HMN" then
    if self.settings.HEROES_MODS == "HMR" then
      self.settings.HEROES_MODS = self:GetRandomModifier(hero_mods)
    end
    table.insert(self.heroes_mods, hero_mods[self.settings.HEROES_MODS])
  end

  if self.settings.HEROES_MODS_2 ~= "HMN" then
    if self.settings.HEROES_MODS_2 == "HMR" then
      self.settings.HEROES_MODS_2 = self:GetRandomModifier(hero_mods)
    end
    if self.settings.HEROES_MODS_2 ~= self.settings.HEROES_MODS then
      table.insert(self.heroes_mods, hero_mods[self.settings.HEROES_MODS_2])
    end
  end

  if self.settings.HEROES_MODS_BUNDLE ~= "HMBN" then
    local bundle = bundles[self.settings.HEROES_MODS_BUNDLE]
    for _, mod in pairs(bundle) do
      if mod then
        table.insert(self.heroes_mods, mod)
      end
    end
  end

  if self.settings.BOSSES_MODS ~= "BMN" then
    if self.settings.BOSSES_MODS == "BMR" then
      self.settings.BOSSES_MODS = self:GetRandomModifier(boss_mods)
    end
    self.bosses_mod = boss_mods[self.settings.BOSSES_MODS]
  end

  if self.settings.GLOBAL_MODS ~= "GMN" then
    if self.settings.GLOBAL_MODS == "GMR" then
      self.settings.GLOBAL_MODS = self:GetRandomModifier(global_mods)
    end
    local global_setting = self.settings.GLOBAL_MODS
    self.global_mod = global_mods[global_setting]

    if self.global_mod == false then
      local global_event_mods = {
        GM01 = "modifier_any_damage_lifesteal_oaa",
        GM05 = "modifier_echo_strike_oaa",
      }
      local global_event_mod = global_event_mods[global_setting]
      if global_event_mod then
        local global_thinker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
        global_thinker:AddNewModifier(global_thinker, nil, "modifier_oaa_thinker", {})
        global_thinker:AddNewModifier(global_thinker, nil, global_event_mod, {isGlobal = 1})
      end
    end
  end

  self:SaveSettings()
end

function OAAOptions:GetRandomModifier(mod_list)
  local options = {}
  for k, v in pairs(mod_list) do
    if v ~= false and v ~= "modifier_hyper_experience_oaa" and v ~= "modifier_aghanim_oaa" and v ~= "modifier_diarrhetic_oaa" and v ~= "modifier_double_multiplier_oaa" then
      table.insert(options, k)
    end
  end
  return self:GetRandomModifierFromOptions(options)
end

function OAAOptions:GetRandomModifierFromOptions(options)
  return options[RandomInt(1, #options)]
end

function OAAOptions:OnUnitSpawn(event)
  local npc
  if event.entindex then
    npc = EntIndexToHScript(event.entindex)
  end
  if not npc or npc:IsNull() then
    return
  end

  if npc.IsBaseNPC == nil or npc.HasModifier == nil or npc.GetUnitName == nil then
    return
  end

  if not npc:IsBaseNPC() then
    -- npc is not an npc
    return
  end

  if npc:HasModifier("modifier_minimap") or npc:HasModifier("modifier_oaa_thinker") or npc:GetUnitName() == "npc_dota_custom_dummy_unit" then
    return
  end

  if (npc:IsRealHero() or npc:IsTempestDouble() or npc:IsClone()) and npc:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
    -- npc is a non-neutral hero
    if self.heroes_mods then
      for _, mod in pairs(self.heroes_mods) do
        if mod and not npc:HasModifier(mod) then
          npc:AddNewModifier(npc, nil, mod, {})
        end
      end
    end

    if self.settings.GLOBAL_MODS == "GM12" then
      PlayerResource:SetCustomBuybackCooldown(npc:GetPlayerID(), math.max(DUEL_INTERVAL, CAPTURE_INTERVAL))
    end
  elseif npc:IsOAABoss() then
    -- npc is a boss
    if self.bosses_mod then
      if not npc:HasModifier(self.bosses_mod) then
        npc:AddNewModifier(npc, nil, self.bosses_mod, {})
      end
    end
  end
end

function OAAOptions:FindHostID()
  local hostId = 0
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
    local steamid = PlayerResource:GetSteamAccountID(playerID) -- PlayerResource:GetSteamID(playerID)
    local player = PlayerResource:GetPlayer(playerID)
    if player and GameRules:PlayerHasCustomGameHostPrivileges(player) then
      hostId = steamid
      break
    end
  end

  return hostId
end

function OAAOptions:ChangeDefaultSettings()
  if self:FindHostID() == 7131038 then
    -- Chris is the host
    if not IsInToolsMode() then
      -- annoying in tools though
      self.settingsDefault.GAME_MODE = "RD"
    end
  end

  self:RestoreDefaults()
  self:SaveSettings()
end

function OAAOptions:TestHeroModifier(keys)
  local short_names = {
    aghanim = "modifier_aghanim_oaa",
    angels_wings = "modifier_angel_oaa",
    anti_judecca = "modifier_all_healing_amplify_oaa",
    aoe_increase = "modifier_aoe_radius_increase_oaa",
    attack_range_switch = "modifier_troll_switch_oaa",
    bad_design_1 = "modifier_bad_design_1_oaa",
    bad_design_2 = "modifier_bad_design_2_oaa",
    battlemage = "modifier_battlemage_oaa",
    blood_magic = "modifier_blood_magic_oaa",
    boss_killer = "modifier_boss_killer_oaa",
    bottle_collector = "modifier_bottle_collector_oaa",
    brawler = "modifier_brawler_oaa",
    brute = "modifier_brute_oaa",
    chaos = "modifier_chaos_oaa",
    courier_hunter = "modifier_courier_kill_bonus_oaa",
    crimson_magic = "modifier_crimson_magic_oaa",
    cursed_attack = "modifier_cursed_attack_oaa",
    diar = "modifier_diarrhetic_oaa",
    drunk = "modifier_drunk_oaa",
    duelist = "modifier_duelist_oaa",
    echo_strike = "modifier_echo_strike_oaa",
    explosive_death = "modifier_explosive_death_oaa",
    fates_madness = "modifier_mr_phys_weak_oaa",
    glass_cannon = "modifier_glass_cannon_oaa",
    guardians_weakness = "modifier_bonus_armor_negative_magic_resist_oaa",
    healer = "modifier_healer_oaa",
    hybrid = "modifier_hybrid_oaa",
    hyper_active = "modifier_ham_oaa",
    hyper_lifesteal = "modifier_any_damage_lifesteal_oaa",
    hyper_xp = "modifier_hyper_experience_oaa",
    keeper_of_the_truth = "modifier_true_sight_strike_oaa",
    ludo = "modifier_ludo_oaa",
    magus = "modifier_magus_oaa",
    max_power = "modifier_any_damage_crit_oaa",
    moriah_shield = "modifier_hp_mana_switch_oaa",
    multicast = "modifier_multicast_oaa",
    nimble = "modifier_nimble_oaa",
    no_brain = "modifier_no_brain_oaa",
    no_hp_bar = "modifier_no_health_bar_oaa",
    octarine_soul = "modifier_octarine_soul_oaa",
    outworld_attack = "modifier_outworld_attack_oaa",
    phys_immune = "modifier_physical_immunity_oaa",
    pro_active = "modifier_pro_active_oaa",
    puny = "modifier_puny_oaa",
    quick_spells = "modifier_no_cast_points_oaa",
    rend = "modifier_rend_oaa",
    roshans_body = "modifier_roshan_power_oaa",
    smurf = "modifier_smurf_oaa",
    sorcerer = "modifier_sorcerer_oaa",
    speedster = "modifier_speedster_oaa",
    spell_resist = "modifier_spell_block_oaa",
    splasher = "modifier_any_damage_splash_oaa",
    spoons_stash = "modifier_spoons_stash_oaa",
    telescope = "modifier_range_increase_oaa",
    timeless = "modifier_debuff_duration_oaa",
    titan_soul = "modifier_titan_soul_oaa",
    two_x = "modifier_double_multiplier_oaa",
    universal = "modifier_universal_oaa",
    wealthy = "modifier_rich_man_oaa",
    white_queen = "modifier_hero_anti_stun_oaa",
    wisdom = "modifier_wisdom_oaa",
  }
  local text = keys.text
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local splitted = split(text, " ")
  local name = splitted[2]
  local extra = splitted[3]
  if name then
    if short_names[name] or hero_mods[name] then
      local mod_name = short_names[name] or hero_mods[name]
      if extra and extra == "remove" then
        hero:RemoveModifierByName(mod_name)
      else
        hero:AddNewModifier(hero, nil, mod_name, {})
      end
      return
    end
    -- For detecting string without underscore
    if extra and extra ~= "remove" then
      local full_name = name.."_"..extra
      local extra2 = splitted[4]
      if short_names[full_name] then
        local mod_name = short_names[full_name]
        if extra2 and extra2 == "remove" then
          hero:RemoveModifierByName(mod_name)
        else
          hero:AddNewModifier(hero, nil, mod_name, {})
        end
      end
    end
  end
end
