
--OAAOptions = Components:Register('OAAOptions', COMPONENT_GAME_SETUP)
if OAAOptions == nil then
  --Debug:EnableDebugging()
  DebugPrint('Starting OAAOptions module')
  OAAOptions = class({})
end

local hero_mods = {
  HMN  = false,
  HM01 = "modifier_any_damage_lifesteal_oaa",
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
  HM13 = "modifier_diarrhetic_oaa",
  HM14 = "modifier_rend_oaa",
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
  HM25 = "modifier_hp_mana_switch_oaa",
  HM26 = "modifier_magus_oaa",
  HM27 = "modifier_brawler_oaa",
  HM28 = "modifier_chaos_oaa",
  --HM29 = "modifier_double_multiplier_oaa",
  HM30 = "modifier_hybrid_oaa",
  --HM31 = "modifier_drunk_oaa",
  HM32 = "modifier_any_damage_splash_oaa",
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

function OAAOptions:Init ()
  --Debug:EnableDebugging()
  DebugPrint('OAAOptions module Initialization started!')
  self.moduleName = "OAA Game Mode Options"

  self.settings = {}
  self.settingsDefault = {}

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
    elseif name == "RANDOMIZE" then
      self.settings.HEROES_MODS = self:GetRandomModifier(hero_mods)
      self.settings.HEROES_MODS_2 = self:GetRandomModifier(hero_mods)
      --self.settings.BOSSES_MODS = self:GetRandomModifier(boss_mods)
      --self.settings.GLOBAL_MODS = self:GetRandomModifier(global_mods)
      self:SaveSettings()
    end
  end)

  GameEvents:OnHeroSelection(partial(OAAOptions.AdjustGameMode, OAAOptions))
  GameEvents:OnCustomGameSetup(partial(OAAOptions.ChangeDefaultSettings, OAAOptions))
  GameEvents:OnGameInProgress(partial(OAAOptions.SetupGame, OAAOptions))

  ListenToGameEvent("npc_spawned", Dynamic_Wrap(OAAOptions, 'OnUnitSpawn'), OAAOptions)

  LinkLuaModifier("modifier_any_damage_lifesteal_oaa", "modifiers/funmodifiers/modifier_any_damage_lifesteal_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_aoe_radius_increase_oaa", "modifiers/funmodifiers/modifier_aoe_radius_increase_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_blood_magic_oaa", "modifiers/funmodifiers/modifier_blood_magic_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_debuff_duration_oaa", "modifiers/funmodifiers/modifier_debuff_duration_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_echo_strike_oaa", "modifiers/funmodifiers/modifier_echo_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_ham_oaa", "modifiers/funmodifiers/modifier_ham_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_no_cast_points_oaa", "modifiers/funmodifiers/modifier_no_cast_points_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_physical_immunity_oaa", "modifiers/funmodifiers/modifier_physical_immunity_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_pro_active_oaa", "modifiers/funmodifiers/modifier_pro_active_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spell_block_oaa", "modifiers/funmodifiers/modifier_spell_block_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_troll_switch_oaa", "modifiers/funmodifiers/modifier_troll_switch_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_hyper_experience_oaa", "modifiers/funmodifiers/modifier_hyper_experience_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_diarrhetic_oaa", "modifiers/funmodifiers/modifier_diarrhetic_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_rend_oaa", "modifiers/funmodifiers/modifier_rend_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_range_increase_oaa", "modifiers/funmodifiers/modifier_range_increase_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_healer_oaa", "modifiers/funmodifiers/modifier_healer_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_explosive_death_oaa", "modifiers/funmodifiers/modifier_explosive_death_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  --LinkLuaModifier("modifier_no_health_bar_oaa", "modifiers/funmodifiers/modifier_no_health_bar_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_boss_aggresive_oaa", "modifiers/funmodifiers/modifier_boss_aggresive_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_brute_oaa", "modifiers/funmodifiers/modifier_brute_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_wisdom_oaa", "modifiers/funmodifiers/modifier_wisdom_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_aghanim_oaa", "modifiers/funmodifiers/modifier_aghanim_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_nimble_oaa", "modifiers/funmodifiers/modifier_nimble_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_sorcerer_oaa", "modifiers/funmodifiers/modifier_sorcerer_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_any_damage_crit_oaa", "modifiers/funmodifiers/modifier_any_damage_crit_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_hp_mana_switch_oaa", "modifiers/funmodifiers/modifier_hp_mana_switch_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_magus_oaa", "modifiers/funmodifiers/modifier_magus_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_brawler_oaa", "modifiers/funmodifiers/modifier_brawler_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_chaos_oaa", "modifiers/funmodifiers/modifier_chaos_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  --LinkLuaModifier("modifier_double_multiplier_oaa", "modifiers/funmodifiers/modifier_double_multiplier_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_hybrid_oaa", "modifiers/funmodifiers/modifier_hybrid_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_drunk_oaa", "modifiers/funmodifiers/modifier_drunk_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_any_damage_splash_oaa", "modifiers/funmodifiers/modifier_any_damage_splash_oaa.lua", LUA_MODIFIER_MOTION_NONE)

  LinkLuaModifier("modifier_all_healing_amplify_oaa", "modifiers/funmodifiers/modifier_all_healing_amplify_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_bonus_armor_negative_magic_resist_oaa", "modifiers/funmodifiers/modifier_bonus_armor_negative_magic_resist_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_cursed_attack_oaa", "modifiers/funmodifiers/modifier_cursed_attack_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_no_brain_oaa", "modifiers/funmodifiers/modifier_no_brain_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_courier_kill_bonus_oaa", "modifiers/funmodifiers/modifier_courier_kill_bonus_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_true_sight_strike_oaa", "modifiers/funmodifiers/modifier_true_sight_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_mr_phys_weak_oaa", "modifiers/funmodifiers/modifier_mr_phys_weak_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_angel_oaa", "modifiers/funmodifiers/modifier_angel_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_hero_anti_stun_oaa", "modifiers/funmodifiers/modifier_hero_anti_stun_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_roshan_power_oaa", "modifiers/funmodifiers/modifier_roshan_power_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_titan_soul_oaa", "modifiers/funmodifiers/modifier_titan_soul_oaa.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_glass_cannon_oaa", "modifiers/funmodifiers/modifier_glass_cannon_oaa.lua", LUA_MODIFIER_MOTION_NONE)

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
  if self.settings.HEROES_MODS == "HM13" or self.settings.HEROES_MODS_2 == "HM13" then
    POOP_WARD_COOLDOWN = 30
    CustomWardButtons.obs_cooldown = 30
    CustomWardButtons.sentry_cooldown = 30
  end
  if self.settings.GLOBAL_MODS == "GM12" then
    local mode = GameRules:GetGameModeEntity()
    mode:SetBuybackEnabled(true)
  end
end

function OAAOptions:InitializeSettingsTable()
  self.settings = {
    GAME_MODE = "AP",                   -- "RD", "AR", "AP", "ARDM", "LP"
    small_player_pool = 0,              -- 1 - some heroes that are strong when there are 2-6 players are disabled; 0 - normal;
    HEROES_MODS = "HMN",
    HEROES_MODS_2 = "HMN",
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
    self.heroes_mod = hero_mods[self.settings.HEROES_MODS]
  end

  if self.settings.HEROES_MODS_2 ~= "HMN" and self.settings.HEROES_MODS_2 ~= self.settings.HEROES_MODS then
    if self.settings.HEROES_MODS_2 == "HMR" then
      self.settings.HEROES_MODS_2 = self:GetRandomModifier(hero_mods)
    end
    if self.settings.HEROES_MODS_2 ~= self.settings.HEROES_MODS then
      self.heroes_mod_2 = hero_mods[self.settings.HEROES_MODS_2]
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
    -- elseif global_setting == "GM13" then
      -- self.heroes_extra_mod =
    end
  end

  self:SaveSettings()
end

function OAAOptions:GetRandomModifier(mod_list)
  local options = {}
  for k, v in pairs(mod_list) do
    if v ~= false and v ~= "modifier_hyper_experience_oaa" and v ~= "modifier_aghanim_oaa" and v ~= "modifier_diarrhetic_oaa" then
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
    if self.heroes_mod then
      if not npc:HasModifier(self.heroes_mod) then
        npc:AddNewModifier(npc, nil, self.heroes_mod, {})
      end
    end

    if self.heroes_mod_2 then
      if not npc:HasModifier(self.heroes_mod_2) then
        npc:AddNewModifier(npc, nil, self.heroes_mod_2, {})
      end
    end

    if self.settings.GLOBAL_MODS == "GM12" then
      PlayerResource:SetCustomBuybackCooldown(npc:GetPlayerID(), math.max(DUEL_INTERVAL, CAPTURE_INTERVAL))
    end

    -- if self.heroes_extra_mod then
      -- if not npc:HasModifier(self.heroes_extra_mod) then
        -- npc:AddNewModifier(npc, nil, self.heroes_extra_mod, {})
      -- end
    -- end
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
    self.settingsDefault.GAME_MODE = "RD"
  end

  self:RestoreDefaults()
  self:SaveSettings()
end
