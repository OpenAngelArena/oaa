-- Taken from bb template
if PointsManager == nil then
  Debug.EnabledModules['points:*'] = true

  DebugPrint ( 'Creating new PointsManager object.' )
  PointsManager = class({})
end

function PointsManager:Init ()
  DebugPrint ( 'Initializing.' )

  PointsManager.haveBadguysWon = false
  PointsManager.haveGoodguysWon = false
  PointsManager.goodguysName = 'Radiant'
  PointsManager.badguysName = 'Dire'
  PointsManager.goodguysID = 2
  PointsManager.badguysID = 3

  if GameRules.GameLength == 'long' then
    CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = 200 } )
  elseif GameRules.GameLength == 'short' then
    CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = 50 } )
  else
    -- default to 100 in case of no selection / invalid selection
    CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = 100 } )
  end

  -- set initial values for current scores
  CustomNetTables:SetTableValue( 'team_scores', 'score', { goodguys = 0,
                                                           badguys = 0
                                                         })
end

function PointsManager:CheckWinCondition ( scores )
  if PointsManager.haveGoodguysWon or PointsManager.haveBadguysWon then
    return
  end

  local limit = CustomNetTables:GetTableValue('team_scores', 'limit').value
  local goodguys = scores.goodguys
  local badguys = scores.badguys

  DebugPrint (math.max(goodguys, badguys) .. ' / ' .. limit)

  if goodguys >= limit then
    PointsManager:handleVictory( PointsManager.goodguysName )
  elseif badguys >= limit then
    PointsManager:handleVictory( PointsManager.badguysName )
  end
end

function PointsManager:handleVictory ( side )
  DebugPrint( side .. ' wins!' )
  local winner = nil

  if side == PointsManager.goodguysName then
    PointsManager.haveGoodguysWon = true
    winner = PointsManager.goodguysID
  elseif side == PointsManager.badguysName then
    PointsManager.haveBadguysWon = true
    winner = PointsManager.badguysID
  end

  Timers:CreateTimer(1, function()
    GameRules:SetGameWinner( winner )
  end)
end

function PointsManager:SetPoints ( side, newPoints )
  DebugPrint('Set Score of ' .. side .. ' to ' .. newScore .. '.')

  local score = CustomNetTables:GetTableValue( 'team_scores', 'score' )

  if side == PointsManager.goodguysName then
    score.goodguys = newPoints
  elseif side == PointsManager.badguysName then
    score.badguys = newPoints
  end

  CustomNetTables:SetTableValue( 'team_scores', 'score', score )
  PointsManager:CheckWinCondition(score)
end

function PointsManager:AddPoints ( side, amount )
  if amount == nil then
    amount = 1
  end

  DebugPrint( 'Increase Score of ' .. side .. ' by ' .. amount .. '.' )

  local score = CustomNetTables:GetTableValue( 'team_scores', 'score' )

  DebugPrintTable(score)

  if side == PointsManager.goodguysName or side == PointsManager.goodguysID then
    score.goodguys = score.goodguys + amount
  elseif side == PointsManager.badguysName or side == PointsManager.badguysID then
    score.badguys = score.badguys + amount
  else
    DebugPrint('What is ' .. side)
  end

  CustomNetTables:SetTableValue( 'team_scores', 'score', score )
  PointsManager:CheckWinCondition(score)
end
