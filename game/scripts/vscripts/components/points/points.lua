-- Taken from bb template
if PointsManager == nil then
  Debug.EnabledModules['points:*'] = false

  DebugPrint ( 'Creating new PointsManager object.' )
  PointsManager = class({})
end

function PointsManager:Init ()
  DebugPrint ( 'Initializing.' )

  PointsManager.hasGameEnded = false

  CustomNetTables:SetTableValue( 'team_scores', 'score', {})

  GameEvents:OnHeroKilled(function (keys)
    -- increment points
    if keys.killer:GetTeam() ~= keys.killed:GetTeam() and not keys.killed:IsReincarnating() then
      PointsManager:AddPoints(keys.killer:GetTeam())
    end
  end)
end

function PointsManager:CheckWinCondition(score)
  if PointsManager.hasGameEnded then
    return
  end

  local limit = CustomNetTables:GetTableValue('team_scores', 'limit').value

  for teamID, points in pairs(score) do
    if points >= limit then
      Timers:CreateTimer(1, function()
        GameRules:SetGameWinner(teamID)
      end)
      PointsManager.hasGameEnded = true
      break
    end
  end
end

function PointsManager:SetPoints(teamID, amount)
  local score = CustomNetTables:GetTableValue( 'team_scores', 'score' )

  score[teamID] = amount

  CustomNetTables:SetTableValue( 'team_scores', 'score', score )
  PointsManager:CheckWinCondition(score)
end

function PointsManager:AddPoints(teamID, amount)
  if amount == nil then
    amount = 1
  end

  local score = CustomNetTables:GetTableValue( 'team_scores', 'score' )

  score[teamID] = score[teamID] + amount or amount

  CustomNetTables:SetTableValue( 'team_scores', 'score', score )
  PointsManager:CheckWinCondition(score)
end

function PointsManager:GetPoints(teamID)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')

  return score[teamID]
end

function PointsManager:GetLimit()
  return CustomNetTables:GetTableValue('team_scores', 'limit').value
end
