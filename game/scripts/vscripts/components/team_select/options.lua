
OAAOptions = Components:Register('OAAOptions', COMPONENT_GAME_SETUP)

function OAAOptions:Init ()
  Debug:EnableDebugging()
  --DebugPrint('OAAOptions Init started!')
  if self.initialized then
    print("OAAOptions should be initialized only once -> preventing multiple times")
    return nil
  end

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

  self.initialized = true
  --DebugPrint('OAAOptions Init finished!')
end

function OAAOptions:InitializeSettingsTable()
  self.settings = {
    GAME_MODE = "AP",                   -- "RD", "AR", "AP"
    small_player_pool = 0,              -- 1 - some heroes that are strong when there are 2-6 players are disabled; 0 - normal;
	  --ALLOW_SAME_HERO_SELECTION = 0,      -- 0 = everyone must pick a different hero, 1 = can pick same
  }

  for k, v in pairs(self.settings) do
    self.settingsDefault[k] = v
  end
end

function OAAOptions:AdjustGameMode()
  DebugPrint("OAAOptions Lock game mode settings and rules.")
  CustomNetTables:SetTableValue("oaa_settings", "locked", OAAOptions.settings)
  DeepPrintTable(self.settings)
  DebugPrint("OAAOptions Adjusting game mode settings and rules that were set by the host.")
  --ALLOW_SAME_HERO_SELECTION = self.settings.ALLOW_SAME_HERO_SELECTION == 1
  --GameRules:SetSameHeroSelectionEnabled(ALLOW_SAME_HERO_SELECTION)

  --local gamemode = GameRules:GetGameModeEntity()
end
