/* global  GameEvents, GameUI, Players */

function AddToAndRemoveFromSelection (event) {
  let toAdd = event.entity_to_add;
  let toRemove = event.entity_to_remove;
  let alreadySelected = Players.GetSelectedEntities(Players.GetLocalPlayer());

  if (toRemove !== undefined) {
    GameUI.SelectUnit(toAdd, false);
    if (alreadySelected !== undefined) {
      for (let i in alreadySelected) {
        if (alreadySelected[i] !== toRemove) {
          GameUI.SelectUnit(alreadySelected[i], true);
        }
      }
    }
  } else {
    GameUI.SelectUnit(toAdd, true);
  }
}

(function () {
  GameEvents.Subscribe('AddRemoveSelection', AddToAndRemoveFromSelection);
})();
