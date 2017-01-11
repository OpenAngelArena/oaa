
-- Taken from bb template
if PointsManager == nil then
    DebugPrint ( '[points/points] creating new PointsManager object' )
    PointsManager = class({})
end

function PointsManager:Init ()
  DebugPrint ( '[points/points] Initialize' )
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
end
