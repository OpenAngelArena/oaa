
function SetPlayerVote (vote) {
  var options = [
    'short',
    'normal',
    'long'
  ];
  vote = vote.toLowerCase();
  if (options.indexOf(vote) === -1) {
    throw new Error('You can only vote for short, normal, or long games.');
  }

  GameEvents.SendCustomGameEventToServer('gamelength_vote', vote);
}
