if SurrenderManager == nil then
  Debug.EnabledModules['surrender:*'] = true
  DebugPrint ( 'Creating new SurrenderManager object.' )
  SurrenderManager = class({})
end


local ONE_MINUTE = 60
local FIVE_MINUTES = 60 * 5
local lastTimeSurrenderWasCalled
local lastTimeSurrenderWasCalledByPlayer = {}
local votes = {}
local numberOfVotesCast = 0
local numberOfVotesExpected = 0
local teamIdToSurrender

function SurrenderManager:Init ()
  DebugPrint ('Init SurrenderManager')
  -- Register chat commands
  ChatCommand:LinkCommand("-surrender", Dynamic_Wrap(SurrenderManager, "CheckSurrenderConditions"), self)
  CustomGameEventManager:RegisterListener('surrender_result', Dynamic_Wrap(SurrenderManager, 'PlayerVote'))
  CustomGameEventManager:RegisterListener('surrender_start_vote', Dynamic_Wrap(SurrenderManager, 'CheckSurrenderConditions'))

  PointsManager.onScoreChanged(partial(SurrenderManager.UpdateVisibility, SurrenderManager))
end

function SurrenderManager:UpdateVisibility()
  local score = CustomNetTables:GetTableValue('team_scores', 'score')
  local radiantScore = score.goodguys
  local direScore = score.badguys
  local loserTeamID = 0
  local now = HudTimer:GetGameTime()
  if direScore < radiantScore then loserTeamID = DOTA_TEAM_BADGUYS else loserTeamID = DOTA_TEAM_GOODGUYS end
  PlayerResource:GetPlayerIDsForTeam(loserTeamID):each(function (playerId)
    local isSurrenderEnabled = SurrenderManager:ScoreAllowsSurrender(loserTeamID) and SurrenderManager:TimeAllowsSurrender(playerId, now)
    CustomGameEventManager:Send_ServerToPlayer ( PlayerResource:GetPlayer(playerId), "surrender_visbility_changed", { visible = isSurrenderEnabled } )
  end)
end


function SurrenderManager:CheckSurrenderConditions(keys)
  local teamId = PlayerResource:GetTeam(keys.PlayerID)
  local now = HudTimer:GetGameTime()
  if SurrenderManager:ScoreAllowsSurrender(teamId) and
      SurrenderManager:TimeAllowsSurrender(keys.PlayerID, now) then
    lastTimeSurrenderWasCalled = GameRules:GetGameTime()
    lastTimeSurrenderWasCalledByPlayer[keys.PlayerID] = now
    teamIdToSurrender = teamId
    local timeout = SURRENDER_TIME_TO_DISPLAY
    local text = "#surrender_suggestion"
    PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
      numberOfVotesExpected = numberOfVotesExpected + 1
      DebugPrint("numberOfVotesExpected = " .. numberOfVotesExpected)
      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "show_yes_no_poll", {pollText = text, pollTimeout = timeout, returnEventName = 'surrender_result'} )
    end)

-- Start a timer - just in case there's an error at a player's machine (crash etc.)
    Timers:CreateTimer(timeout + 2, Dynamic_Wrap(SurrenderManager, 'CalculateVotesFromTimer'))
  end
  SurrenderManager:UpdateVisibility()
end

function SurrenderManager:ScoreAllowsSurrender(teamId)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')
  local scoreDiff
  if teamId == DOTA_TEAM_GOODGUYS then
    scoreDiff = score.badguys - score.goodguys
  elseif teamId == DOTA_TEAM_BADGUYS then
    scoreDiff = score.goodguys - score.badguys
  end

  return scoreDiff >= SURRENDER_MINIMUM_KILLS_BEHIND
end

function SurrenderManager:TimeAllowsSurrender(playerId, now)
  local result
  if lastTimeSurrenderWasCalled == nil then
    DebugPrint("SurrenderManager:TimeAllowsSurrender --> lastTimeSurrenderWasCalled == nil")
    result = true
  else
    if now - lastTimeSurrenderWasCalled > ONE_MINUTE then
      DebugPrint("SurrenderManager:TimeAllowsSurrender --> now - lastTimeSurrenderWasCalled = " .. (now - lastTimeSurrenderWasCalled))
      if lastTimeSurrenderWasCalledByPlayer[playerId] == nil or
          now - lastTimeSurrenderWasCalledByPlayer[playerId] > FIVE_MINUTES then
        if lastTimeSurrenderWasCalledByPlayer[playerId] == nil then
          DebugPrint("SurrenderManager:TimeAllowsSurrender --> lastTimeSurrenderWasCalledByPlayer[playerId] == nil")
        else
          DebugPrint("SurrenderManager:TimeAllowsSurrender --> now - lastTimeSurrenderWasCalled = " .. (now - lastTimeSurrenderWasCalledByPlayer[playerId]))
        end
        result = true
      else
        result = false
      end
    else
      result = false
    end
  end

  return result
end

function SurrenderManager:PlayerVote (eventSourceIndex, args)
  local playerId = eventSourceIndex.PlayerID
  local selection = eventSourceIndex.result
  votes[playerId] = selection
  numberOfVotesCast = numberOfVotesCast + 1
  DebugPrint("numberOfVotesCast = " .. numberOfVotesCast)
  if numberOfVotesCast == numberOfVotesExpected then
    SurrenderManager:CalculateVotes()
  end
end

function SurrenderManager:CalculateVotesFromTimer()
DebugPrint("numberOfVotesExpected = " .. numberOfVotesExpected)
  if numberOfVotesExpected > 0 then -- if CalculateVotes has already ran this will be 0
    SurrenderManager:CalculateVotes()
  end
end

function SurrenderManager:CalculateVotes()
  local yesVotesCast = 0
  for key,value in pairs(votes) do
    yesVotesCast = yesVotesCast + value
  end

  DebugPrint("yesVotesCast = " .. yesVotesCast)
  if table.getn{SURRENDER_REQUIRED_YES_VOTES} <= numberOfVotesCast then
    local requiredNumberOfYesVotes = SURRENDER_REQUIRED_YES_VOTES[numberOfVotesCast]
    votes = {}
    numberOfVotesCast = 0
    numberOfVotesExpected = 0
    DebugPrint("requiredNumberOfYesVotes = " .. requiredNumberOfYesVotes)
    if requiredNumberOfYesVotes <= yesVotesCast then
      DebugPrint("End game")
      local teamText = nil
      if teamIdToSurrender == DOTA_TEAM_GOODGUYS then
        teamText = "Radiant"
      elseif teamIdToSurrender == DOTA_TEAM_BADGUYS then
        teamText = "Dire"
      end

      if teamText ~= nil then
        Notifications:TopToAll({text="#team_has_surrendered", duration=5.0, replacement_map={team_text = teamText}})
        Timers:CreateTimer(5, Dynamic_Wrap(SurrenderManager, 'EndGame'))
      end
    else
      DebugPrint("Do not end game")
    end
  else
    DebugPrint("Error: table.getn{SURRENDER_REQUIRED_YES_VOTES} > numberOfVotesCast  table.getn{SURRENDER_REQUIRED_YES_VOTES} = " .. table.getn{SURRENDER_REQUIRED_YES_VOTES} .. " numberOfVotesCast = " .. numberOfVotesCast)
  end
  SurrenderManager:UpdateVisibility()
end

function SurrenderManager:EndGame()
  local teamId
  if teamIdToSurrender == DOTA_TEAM_GOODGUYS then
    teamId = DOTA_TEAM_BADGUYS
  elseif teamIdToSurrender == DOTA_TEAM_BADGUYS then
    teamId = DOTA_TEAM_GOODGUYS
  end

  PointsManager:SetWinner(teamId)
end
