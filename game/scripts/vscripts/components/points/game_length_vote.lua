-- simple component, no need to break out into multiple files

-- Taken from bb template
if GameLengthVotes == nil then
    DebugPrint ( 'creating new GameLength voter object.' )
    GameLengthVotes = class({})
end

function GameLengthVotes:Init ()
  DebugPrint( 'Initializing.' )
  GameLengthVotes = self
  GameLengthVotes.Votes = {}

  Debug.EnabledModules["game_length_vote:*"] = true

  CustomGameEventManager:RegisterListener( "gamelength_vote", Dynamic_Wrap(GameLengthVotes, 'PlayerVote') )
end

function GameLengthVotes:PlayerVote (eventSourceIndex, args)
  DebugPrint ( 'player vote: ' .. eventSourceIndex.vote )
  DebugPrint ( 'player vote: ' .. eventSourceIndex.playerId )

  GameLengthVotes.Votes[eventSourceIndex.playerId] = eventSourceIndex.vote
end

function GameLengthVotes:SetGameLength ()
  local votes = {
    short = 0,
    normal = 0,
    long = 0
  }
  for playerId=0,19 do
    if GameLengthVotes.Votes[playerId] ~= nil then
      votes[GameLengthVotes.Votes[playerId]] = votes[GameLengthVotes.Votes[playerId]] + 1
    end
  end

  local length
  local scoreLimit
  if votes.long > votes.normal then
    if votes.long > votes.short then
      length = 'long'
      scoreLimit = 200
      CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = length } )
    else
      length = 'short'
      scoreLimit = 50
      CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = length } )
    end
  elseif votes.short > votes.normal then
    length = 'short'
    scoreLimit = 50
    CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = length } )
  else
    length = 'normal'
    scoreLimit = 100
    CustomNetTables:SetTableValue( 'team_scores', 'limit', { value = scoreLimit, name = length } )
  end
  DebugPrint ( 'votes ' .. votes.short .. ', ' .. votes.normal .. ', ' .. votes.long .. ' result: ' .. length)
  GameRules.GameLength = length
end
