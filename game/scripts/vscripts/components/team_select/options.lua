
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
  HM08 = "modifier_physical_immunity_oaa",
  HM09 = "modifier_pro_active_oaa",
  HM10 = "modifier_spell_block_oaa",
  HM11 = "modifier_troll_switch_oaa",
}
local boss_mods = {
  BMN  = false,
  BM01 = "modifier_any_damage_lifesteal_oaa",
  BM02 = "modifier_echo_strike_oaa",
  BM03 = "modifier_physical_immunity_oaa",
  BM04 = "modifier_spell_block_oaa",
}
local global_mods = {
  GMN  = false,
  GM01 = false,--"modifier_any_damage_lifesteal_oaa",
  GM02 = "modifier_aoe_radius_increase_oaa",
  GM03 = "modifier_blood_magic_oaa",
  GM04 = "modifier_debuff_duration_oaa",
  GM05 = false, --"modifier_echo_strike_oaa",
  GM06 = "modifier_ham_oaa",
  GM07 = "modifier_no_cast_points_oaa",
  GM08 = "modifier_physical_immunity_oaa",
  GM09 = "modifier_pro_active_oaa",
  GM10 = "modifier_spell_block_oaa",
  GM11 = "modifier_troll_switch_oaa",
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
      return
    end
    if name == "RANDOMIZE" then
      self.settings.HEROES_MODS = self:GetRandomHeroModifier()
      self.settings.BOSSES_MODS = self:GetRandomBossModifier()
      self.settings.GLOBAL_MODS = self:GetRandomGlobalModifier()
      self:SaveSettings()
      return
    end
  end)

  GameEvents:OnHeroSelection(partial(OAAOptions.AdjustGameMode, OAAOptions))
  GameEvents:OnCustomGameSetup(partial(OAAOptions.ChangeDefaultSettings, OAAOptions))
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

function OAAOptions:InitializeSettingsTable()
  self.settings = {
    GAME_MODE = "AP",                   -- "RD", "AR", "AP", "ARDM"
    small_player_pool = 0,              -- 1 - some heroes that are strong when there are 2-6 players are disabled; 0 - normal;
    HEROES_MODS = "HMN",
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
      self.settings.HEROES_MODS = self:GetRandomHeroModifier()
    end
    self.heroes_mod = hero_mods[self.settings.HEROES_MODS]
  end

  if self.settings.BOSSES_MODS ~= "BMN" then
    if self.settings.BOSSES_MODS == "BMR" then
      self.settings.BOSSES_MODS = self:GetRandomBossModifier()
    end
    self.bosses_mod = boss_mods[self.settings.BOSSES_MODS]
  end

  if self.settings.GLOBAL_MODS ~= "GMN" then
    if self.settings.GLOBAL_MODS == "GMR" then
      self.settings.GLOBAL_MODS = self:GetRandomGlobalModifier()
    end
    self.global_mod = global_mods[self.settings.GLOBAL_MODS]

    if self.global_mod == false then
      local global_event_mods = {
        GM01 = "modifier_any_damage_lifesteal_oaa",
        GM05 = "modifier_echo_strike_oaa",
      }
      local global_event_mod = global_event_mods[self.settings.GLOBAL_MODS]
      if global_event_mod then
        local global_thinker = CreateUnitByName("npc_dota_custom_dummy_unit", Vector(0, 0, 0), false, nil, nil, DOTA_TEAM_NEUTRALS)
        global_thinker:AddNewModifier(global_thinker, nil, "modifier_oaa_thinker", {})
        global_thinker:AddNewModifier(global_thinker, nil, global_event_mod, {isGlobal = 1})
      end
    end
  end

  self:SaveSettings()
end

function OAAOptions:GetRandomHeroModifier()
  local options = {}
  for k,v in pairs(hero_mods) do
    table.insert(options, k)
  end
  return self:GetRandomModifierFromOptions(options)
end
function OAAOptions:GetRandomBossModifier()
  local options = {}
  for k,v in pairs(boss_mods) do
    table.insert(options, k)
  end
  return self:GetRandomModifierFromOptions(options)
end
function OAAOptions:GetRandomGlobalModifier()
  local options = {}
  for k,v in pairs(global_mods) do
    table.insert(options, k)
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

  if not npc:IsBaseNPC() then
    -- npc is not an npc
    return
  end
  
  if npc:HasModifier("modifier_minimap") or npc:HasModifier("modifier_oaa_thinker") then
    return
  end

  if self.global_mod then
    if not npc:HasModifier(self.global_mod) then
      npc:AddNewModifier(npc, nil, self.global_mod, {})
    end
  end

  if (npc:IsRealHero() or npc:IsTempestDouble() or npc:IsClone()) and npc:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
    -- npc is a non-neutral hero
    if self.heroes_mod and self.heroes_mod ~= self.global_mod then
      if not npc:HasModifier(self.heroes_mod) then
        npc:AddNewModifier(npc, nil, self.heroes_mod, {})
      end
    end
  elseif npc:IsOAABoss() then
    -- npc is a boss
    if self.bosses_mod and self.bosses_mod ~= self.global_mod then
      if not npc:HasModifier(self.bosses_mod) then
        npc:AddNewModifier(npc, nil, self.bosses_mod, {})
      end
    end
  end
end

function OAAOptions:FindHostID()
  local hostId = 0
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
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
