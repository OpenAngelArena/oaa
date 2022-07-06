/* global Game, GameEvents, GameUI, Players, Entities, Buffs, Abilities */

'use strict';

function FindModifier (unit, modifier) {
  for (let i = 0; i < Entities.GetNumBuffs(unit); i++) {
    if (Buffs.GetName(unit, Entities.GetBuff(unit, i)) === modifier) {
      return Entities.GetBuff(unit, i);
    }
  }
}

function HasModifier (unit, modifier) {
  return !!FindModifier(unit, modifier);
}

function GetStackCount (unit, modifier) {
  let m = FindModifier(unit, modifier);
  return m ? Buffs.GetStackCount(unit, m) : 0;
}

function GetStackCountLocal(modifier) {
  let hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
  return GetStackCount(hero, modifier)
}

function CreateAllButtons () {
  let ObserverWardMain = $("#ObserverWardPanel");
  let SentryWardMain = $("#SentryWardPanel");

  SetObserver(ObserverWardMain);
  SetSentry(SentryWardMain);

  let ObserverWard = $("#ObserverWardIcon");
  let SentryWard = $("#SentryWardIcon");

  $.CreatePanelWithProperties("DOTAItemImage", ObserverWard, "observer_image", { style: "width:100%;height:100%;", src: "file://{images}/items/ward_observer.png",});
  $.CreatePanelWithProperties("DOTAItemImage", SentryWard, "sentry_image", { style: "width:100%;height:100%;", src: "file://{images}/items/ward_sentry.png" });

  $.Schedule(1/144, ButtonsUpdate);
}

function ButtonsUpdate () {
  let ObserverWardPanel = $("#ObserverWardPanel");
  let SentryWardPanel = $("#SentryWardPanel");
  let ObserverCooldownLabel = $("#ObserverCooldownLabel");
  let SentryCooldownLabel = $("#SentryCooldownLabel");

  if (Players.GetLocalPlayerPortraitUnit() != Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()) ) {
    ObserverWardPanel.style.opacity = 0;
    ObserverWardPanel.style.visibility = 'collapse';
    SentryWardPanel.style.opacity = 0;
    SentryWardPanel.style.visibility = 'collapse';
  } else {
    ObserverWardPanel.style.opacity = 1;
    ObserverWardPanel.style.visibility = 'visible';
    SentryWardPanel.style.opacity = 1;
    SentryWardPanel.style.visibility = 'visible';
  }

	let observer_button_label = $("#ObserverWardCountLabel");
	let sentry_button_label = $("#SentryWardCountLabel");

    // let ability_id_2 = -1;
    // for (let i = 0; i < 45; i++) {
        // ability_id_2 = Entities.GetAbility( Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), i )
        // if (ability_id_2 > -1) {
            // let ability_name =  Abilities.GetAbilityName( ability_id_2 )
            // if (ability_name == "custom_ability_observer" ) {
				// observer_button_label.text = String(GetStackCountLocal("modifier_item_custom_observer_ward_charges"))

				// let time = 0

				// if (Buffs)
				// {
					// time = Math.ceil(   Buffs.GetRemainingTime( Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), FindModifier(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), "modifier_item_custom_observer_ward_charges") )    )
				// }

				// let min = Math.trunc((time)/60)
				// let sec_n =  (time) - 60*Math.trunc((time)/60)

				// let hour = String( Math.trunc((min)/60) )

				// min = String(min - 60*( Math.trunc(min/60) ))

				// let sec = String(sec_n)
				// if (sec_n < 10)
				// {
					// sec = '0' + sec
				// }

				// ObserverCooldownLabel.text = min + ':' + sec
				// if (time > 120) {
					// ObserverCooldownLabel.visible = false
				// } else {
					// ObserverCooldownLabel.visible = true
				// }
                // break
            // }
        // }
    // }

    // let ability_sentry = -1
    // for (let i = 0; i < 45; i++) {
        // ability_sentry = Entities.GetAbility( Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), i )
        // if (ability_sentry > -1) {
            // let ability_name =  Abilities.GetAbilityName( ability_sentry )
            // if (ability_name == "custom_ability_sentry" ) {
				// sentry_button_label.text = String(GetStackCountLocal("modifier_item_custom_sentry_ward_charges"))

				// let time = 0

				// if (Buffs)
				// {
					// time = Math.ceil(   Buffs.GetRemainingTime( Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), FindModifier(Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()), "modifier_item_custom_sentry_ward_charges") )    )
				// }
				// let min = Math.trunc((time)/60)
				// let sec_n =  (time) - 60*Math.trunc((time)/60)

				// let hour = String( Math.trunc((min)/60) )

				// min = String(min - 60*( Math.trunc(min/60) ))

				// let sec = String(sec_n)
				// if (sec_n < 10)
				// {
					// sec = '0' + sec
				// }

				// SentryCooldownLabel.text = min + ':' + sec
				// if (time > 120) {
					// SentryCooldownLabel.visible = false
				// } else {
					// SentryCooldownLabel.visible = true
				// }
                // break
            // }
        // }
    // }

	$.Schedule(1/144, ButtonsUpdate);
}

(function () {
  CreateAllButtons();
})();

function CastAbilityObserver() {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', {'type': 'observer'});
}

function CastAbilitySentry() {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', {'type': 'sentry'});
}

function SetObserver (panel) {
  panel.SetPanelEvent('onmouseactivate', function() {
    CastAbilityObserver()  });
  panel.SetPanelEvent('oncontextmenu', function() {
    CastAbilityObserver()  });
}

function SetSentry (panel) {
  panel.SetPanelEvent('onmouseactivate', function() {
    CastAbilitySentry()  });
  panel.SetPanelEvent('oncontextmenu', function() {
    CastAbilitySentry()  });
}
