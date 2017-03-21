var console = {
  log: $.Msg.bind($)
};

function SetPlayerVote (vote) {
  // return;

  var options = [
    'short',
    'normal',
    'long'
  ];
  vote = vote.toLowerCase();
  if (options.indexOf(vote) === -1) {
    console.log('You can only vote for short, normal, or long games.');
    return;
  }

  console.log(Players.GetLocalPlayer() + ' votes for ' + vote)
  GameEvents.SendCustomGameEventToServer('gamelength_vote', {
    playerId: Players.GetLocalPlayer(),
    vote: vote
  });
}
