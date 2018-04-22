if SurrenderManager == nil then
  Debug.EnabledModules['surrender:*'] = true
  DebugPrint ( 'Creating new SurrenderManager object.' )
  SurrenderManager = class({})
end

local MINIMUM_KILLS_BEHIND = 50
local REQUIRED_YES_VOTES = {1, 2, 2, 3, 4}
local TIME_TO_DISPLAY = 10
local ONE_MINUTE = 60
local FIVE_MINUTES = 60 * 5
local lastTimeSurrenderWasCalled
local lastTimeSurrenderWasCalledByPlayer = {}
local votes = {}
local numberOfVotesCast = 0
local teamIdToSurrender

function SurrenderManager:Init ()
  DebugPrint ('Init SurrenderManager')
  -- Register chat commands
  ChatCommand:LinkCommand("-surrender", Dynamic_Wrap(SurrenderManager, "CheckSurrenderConditions"), self)
  CustomGameEventManager:RegisterListener('surrender_result', Dynamic_Wrap(SurrenderManager, 'PlayerVote'))
end

function SurrenderManager:CheckSurrenderConditions(keys)
  local teamId = PlayerResource:GetTeam(keys.playerid)
  local now = GameRules:GetGameTime()
  if SurrenderManager:ScoreAllowsSurrender(teamId) and
      SurrenderManager:TimeAllowsSurrender(keys.playerid, now) then
    lastTimeSurrenderWasCalled = GameRules:GetGameTime()
    lastTimeSurrenderWasCalledByPlayer[keys.playerid] = now
    teamIdToSurrender = teamId
    local timeout = 10
    local text = "Would you like to surrender?"
    PlayerResource:GetPlayerIDsForTeam(teamId):each(function (playerId)
      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerId), "show_yes_no_poll", {pollText = text, pollTimeout = timeout, returnEventName = 'surrender_result'} )
    end)

    Timers:CreateTimer(timeout + 1, Dynamic_Wrap(SurrenderManager, 'CalculateVotes'))
  end
end

function SurrenderManager:ScoreAllowsSurrender(teamId)
  local score = CustomNetTables:GetTableValue('team_scores', 'score')
  local scoreDiff
  if teamId == DOTA_TEAM_GOODGUYS then
    scoreDiff = score.badguys - score.goodguys
  elseif teamId == DOTA_TEAM_BADGUYS then
    scoreDiff = score.goodguys - score.badguys
  end

  return scoreDiff >= MINIMUM_KILLS_BEHIND
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
end

function SurrenderManager:CalculateVotes()
  local yesVotesCast = 0
  for key,value in pairs(votes) do
    yesVotesCast = yesVotesCast + value
  end

  DebugPrint("yesVotesCast = " .. yesVotesCast)
  if table.getn{REQUIRED_YES_VOTES} <= numberOfVotesCast then
    local requiredNumberOfYesVotes = REQUIRED_YES_VOTES[numberOfVotesCast]
    votes = {}
    numberOfVotesCast = 0
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
    DebugPrint("Error: table.getn{REQUIRED_YES_VOTES} > numberOfVotesCast  table.getn{REQUIRED_YES_VOTES} = " .. table.getn{REQUIRED_YES_VOTES} .. " numberOfVotesCast = " .. numberOfVotesCast)
  end
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
