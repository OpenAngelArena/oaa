if PlayerConnection == nil then
  Debug.EnabledModules["player:connection"] = true
  DebugPrint("Creating PlayerConnection Object")
  PlayerConnection = class({})
end

function PlayerConnection:Init()
  Timers:CreateTimer(function()
    return self:Think()
  end)
  self.countdown = nil
end

function PlayerConnection:Think()
  local goodTeamPlayerCount = length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))
  local badTeamPlayerCount = length(PlayerResource:GetConnectedTeamPlayerIDsForTeam(DOTA_TEAM_BADGUYS))

  local emptyTeam = nil
  local otherTeam = nil

  -- First check that players exist on both teams and don't start countdown if either team has no players
  if PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS) == 0 or PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS) == 0 then
    return 1-- Don't do anything
  elseif goodTeamPlayerCount == 0 and badTeamPlayerCount == 0 then
    PointsManager:SetWinner(DOTA_TEAM_NEUTRALS)
  elseif goodTeamPlayerCount == 0 then
    emptyTeam = DOTA_TEAM_GOODGUYS
    otherTeam = DOTA_TEAM_BADGUYS
  elseif badTeamPlayerCount == 0 then
    emptyTeam = DOTA_TEAM_BADGUYS
    otherTeam = DOTA_TEAM_GOODGUYS
  end

  if not emptyTeam then
    self.countdown = nil
  elseif not self.countdown then
    self.countdown = GAME_ABANDON_TIME
    Notifications:TopToAll({
      text="#abandon_detected",
      duration=3,
      style={
        color="red"
      }
    })
    return 1
  end

  if self.countdown and self.countdown > 0 then
    -- TODO: Show Nice Message
    if otherTeam == DOTA_TEAM_GOODGUYS then
      Notifications:TopToAll({
        text="#abandon_good_auto_win",
        duration=1,
        replacement_map={
          seconds_remaining = self.countdown
        }
      })
    elseif otherTeam == DOTA_TEAM_BADGUYS then
      Notifications:TopToAll({
        text="#abandon_bad_auto_win",
        duration=1,
        replacement_map={
          seconds_remaining = self.countdown
        }
      })
    end
    self.countdown = self.countdown - 1
  elseif self.countdown == 0 then
    PointsManager:SetWinner(otherTeam)
    return -- don't loop again
  end

  return 1
end
