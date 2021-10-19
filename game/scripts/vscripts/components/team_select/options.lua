
--OAAOptions = Components:Register('OAAOptions', COMPONENT_GAME_SETUP)
if OAAOptions == nil then
  --Debug:EnableDebugging()
  DebugPrint('Starting OAAOptions module')
  OAAOptions = class({})
end

function OAAOptions:Init ()
  --Debug:EnableDebugging()
  DebugPrint('OAAOptions module Initialization started!')
  self.moduleName = "OAA Game Mode Options"

  self.settings = {}
  self.settingsDefault = {}

  self:InitializeSettingsTable()

  CustomNetTables:SetTableValue("oaa_settings", "default", OAAOptions.settings)

  CustomGameEventManager:RegisterListener("oaa_setting_changed", function(_, kv)
    OAAOptions.settings[kv.setting] = kv.value
    DebugPrint(kv.setting, ":", kv.value)
  end)

  CustomGameEventManager:RegisterListener("oaa_button_clicked", function(_, kv)
    local name = kv.button
    if name == "RESET" then
      for k, v in pairs(OAAOptions.settingsDefault) do
        CustomGameEventManager:Send_ServerToAllClients("oaa_setting_changed", {setting = k, value = v})
      end
    end
  end)

  GameEvents:OnHeroSelection(partial(OAAOptions.AdjustGameMode, OAAOptions))

  DebugPrint('OAAOptions module Initialization finished!')
end

function OAAOptions:InitializeSettingsTable()
  self.settings = {
    GAME_MODE = "RD",                   -- "RD", "AR", "AP", "ARDM"
    small_player_pool = 0,              -- 1 - some heroes that are strong when there are 2-6 players are disabled; 0 - normal;
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
  --local gamemode = GameRules:GetGameModeEntity()
end
