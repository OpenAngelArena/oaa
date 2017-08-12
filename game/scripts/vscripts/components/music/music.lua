if Music == nil then
  Debug.EnabledModules['music:music'] = true
  DebugPrint ( 'Creating new Music object.' )
  Music = class({})
end

function Music:Init ()
  DebugPrint('Init music')
  Music:SetMusic("game", "starts")
end

function Music:SetMusic(title, subtitle)
  Music.currentTrack = ttitle
  CustomNetTables:SetTableValue("info", "music", { title = title, subtitle = subtitle })
end
