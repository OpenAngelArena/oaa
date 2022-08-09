/* global  GameEvents, GameUI, Players */

function AddToAndRemoveFromSelection (event) {
  const toAdd = event.entity_to_add;
  const toRemove = event.entity_to_remove;
  const alreadySelected = Players.GetSelectedEntities(Players.GetLocalPlayer());

  if (toRemove !== undefined) {
    GameUI.SelectUnit(toAdd, false);
    if (alreadySelected !== undefined) {
      for (const i in alreadySelected) {
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
