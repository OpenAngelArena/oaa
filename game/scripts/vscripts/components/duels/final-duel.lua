-- Taken from bb template
if FinalDuel == nil then
  DebugPrint ( 'Creating new FinalDuel object.' )
  FinalDuel = class({})
  Debug.EnabledModules['duels:final-duel'] = true
end

-- Duels.onStart = DuelStartEvent.listen
-- Duels.onPreparing = DuelPreparingEvent.listen
-- Duels.onEnd = DuelEndEvent.listen

local limitIncreaseAmounts = {
  short = 7,
  normal = 10,
  long = 13,
}

function FinalDuel:Init ()
  Duels.onEnd(partial(FinalDuel.EndDuelHandler, FinalDuel))
  Duels.onPreparing(partial(FinalDuel.PreparingDuelHandler, FinalDuel))
  Duels.onStart(partial(FinalDuel.StartDuelHandler, FinalDuel))
  PointsManager.onWinner(partial(FinalDuel.Trigger, FinalDuel))
end

function FinalDuel:Trigger (team)
  self.needsFinalDuel = true

  if Duels.currentDuel then
    -- let end of duel handler sort it out
    return
  end

  Duels:StartDuel({
    players = 5, -- TODO: 10v10 compatibility
    timeout = FINAL_DUEL_TIMEOUT
  })
end

function FinalDuel:PreparingDuelHandler (keys)
  if self.needsFinalDuel then
    self.isCurrentlyFinalDuel = true
    self.needsFinalDuel = false
    Notifications:TopToAll({text="#duel_final_duel_imminent", duration=4.0})

    local limit = PointsManager:GetLimit()
    local goodPoints = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS)
    local badPoints = PointsManager:GetPoints(DOTA_TEAM_BADGUYS)
    self.goodCanWin = goodPoints >= limit
    self.badCanWin = badPoints >= limit
  end
end

function FinalDuel:StartDuelHandler (keys)
  if self.isCurrentlyFinalDuel then
    local extraMessage = ""
    if self.goodCanWin then
      if self.badCanWin then
        extraMessage = "#duel_final_duel_both_can_win"
      else
        extraMessage = "#duel_final_duel_good_can_win"
      end
    else
      extraMessage = "#duel_final_duel_bad_can_win"
    end

    Notifications:TopToAll({text="#duel_final_duel_start", duration=10.0})
    Notifications:TopToAll({text=extraMessage, duration=10.0})
  end
end

function FinalDuel:EndDuelHandler (currentDuel)
  if not self.isCurrentlyFinalDuel then
    DebugPrint('Normal Duel has ended')
    if self.needsFinalDuel then
      -- a duel just ended and we need to trigger the final duel
      Timers:CreateTimer(10, function ()
        self:Trigger()
      end)
    end
    return
  end
  DebugPrint('Final Duel has ended')
  self.isCurrentlyFinalDuel = false

  -- currentDuel.duelEnd1
  -- currentDuel.duelEnd2
  local loser = currentDuel.duelEnd1
  if loser == true then
    loser = currentDuel.duelEnd2
  end

  if loser == "bad" and self.goodCanWin then
    PointsManager:SetWinner(DOTA_TEAM_GOODGUYS)
    return
  end
  if loser == "good" and self.badCanWin then
    PointsManager:SetWinner(DOTA_TEAM_BADGUYS)
    return
  end
  local addToLimit = limitIncreaseAmounts[PointsManager:GetGameLength()]
  Notifications:TopToAll({text="#duel_final_duel_objective_extended", duration=5.0, replacement_map={extend_amount=addToLimit}})

  PointsManager:SetLimit(PointsManager:GetLimit() + addToLimit)
end
