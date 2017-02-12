
-- Taken from bb template
if PointsManager == nil then
  DebugPrint ( '[points/PointsManager] creating new PointsManager object' )
  PointsManager = class({})
end

function PointsManager:Init ()
  DebugPrint ( '[points/PointsManager] Initialize' )
  PointsManager.hasDireWon = false
  PointsManager.hasRadiantWon = false

  if GameRules.GameLength == "long" then
    CustomNetTables:SetTableValue( "team_scores", "limit", { value = 200 } )
  elseif GameRules.GameLength == "short" then
    CustomNetTables:SetTableValue( "team_scores", "limit", { value = 50 } )
  else
    -- default to 100 in case of no selection / invalid selection
    CustomNetTables:SetTableValue( "team_scores", "limit", { value = 100 } )
  end

  -- set initial values for current scores
  CustomNetTables:SetTableValue( "team_scores", "score", { radiant = 0, dire = 0 } )

  Timers:CreateTimer(0, Dynamic_Wrap(PointsManager, "Think"))
end


function PointsManager:Debug ()
  local scores = CustomNetTables:GetTableValue("team_scores", "score")
  CustomNetTables:SetTableValue("team_scores", "score", { radiant = scores.radiant + 1,
                                                          dire = scores.dire })
end

function PointsManager:Think ()
  DebugPrint("[points/PointsManager] Thinking..")
  PointsManager:Debug()

  local interval = 5 -- when do we want to check for win conditions
  local limit = CustomNetTables:GetTableValue("team_scores", "limit").value
  local scores = CustomNetTables:GetTableValue("team_scores", "score")
  local radiant = scores.radiant
  local dire = scores.dire

  DebugPrintTable(limit)
  DebugPrintTable(scores)
  DebugPrint("hasRadiantWon" .. hasRadiantWon)
  DebugPrint("hasDireWon" .. hasDireWon)

  if hasRadiantWon or hasDireWon then return end

  if radiant >= limit then
    PointsManager:OnRadiantWin()
  elseif dire >= limit then
    PointsManager:OnDireWin()
  end

  PointsManager:UpdatePoints()
  return interval
end

function PointsManager:OnRadiantWin ()
  --GameRules.SetMode(DOTA_GAMERULES_STATE_POST_GAME)
  DebugPrint("[points/PointsManager] Radiant win!")
  hasRadiantWon = true
end

function PointsManager:OnDireWin ()
  --GameRules.SetMode(DOTA_GAMERULES_STATE_POST_GAME)
  DebugPrint("[points/PointsManager] Dire win!")
  hasDireWon = true
end

function PointsManager:UpdatePoints ()
  local limit = CustomNetTables:GetTableValue("team_scores", "limit").value
  local scores = CustomNetTables:GetTableValue("team_scores", "score")
  local radiant = scores.radiant
  local dire = scores.dire
  CustomGameEventManager:Send_ServerToAllClients("points", {
    scores = scores,
    hasWon = {
      radiant = hasRadiantWon,
      dire = hasDireWon
    }
  })
end
