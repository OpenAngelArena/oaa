-- simple component, no need to break out into multiple files

-- Taken from bb template
if GameLengthVotes == nil then
    DebugPrint ( '[points/game_length_vote] creating new GameLength voter object' )
    GameLengthVotes = class({})
end

function GameLengthVotes:Init ()
  GameLengthVotes = self
  GameLengthVotes.Votes = {}

  CustomGameEventManager:RegisterListener( "gamelength_vote", Dynamic_Wrap(GameLengthVotes, 'PlayerVote') )
end

function GameLengthVotes:PlayerVote (eventSourceIndex, args)
  DebugPrint ( '[points/game_length_vote] player vote: ' .. eventSourceIndex.vote )
  DebugPrint ( '[points/game_length_vote] player vote: ' .. eventSourceIndex.playerId )

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

  local length = 'normal'
  if votes.long > votes.normal then
    if votes.long > votes.short then
      length = 'long'
    else
      length = 'short'
    end
  elseif votes.short > votes.normal then
    length = 'short'
  end
  DebugPrint ( 'votes ' .. votes.short .. ', ' .. votes.normal .. ', ' .. votes.long .. ' result: ' .. length)
  GameRules.GameLength = length
end
