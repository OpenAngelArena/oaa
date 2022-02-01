/* global  GameEvents, GameUI, Players */

function AddToAndRemoveFromSelection (event) {
  let to_add = event.entity_to_add;
  let to_remove = event.entity_to_remove;
  let already_selected = Players.GetSelectedEntities(Players.GetLocalPlayer());
  
  if (to_remove !== undefined) {
    GameUI.SelectUnit(to_add, false);

    if (already_selected !== undefined) {
      for (let i in already_selected) {
        if (already_selected[i] !== to_remove) {
          GameUI.SelectUnit(already_selected[i], true);
        };
      };
    };
  } else {
    GameUI.SelectUnit(to_add, true);
  };
}

(function () {
  GameEvents.Subscribe("AddRemoveSelection", AddToAndRemoveFromSelection);
})();
