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
  let hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer())
  return GetStackCount(hero, modifier)
}

const parentHUDElements = $.GetContextPanel().GetParent().GetParent().GetParent().FindChild("HUDElements");
const center_block = parentHUDElements.FindChildTraverse("center_block");
const buffs =  parentHUDElements.FindChildTraverse("buffs");
const debuffs = parentHUDElements.FindChildTraverse("debuffs");
let default_button_for_observer
let default_button_for_sentry

function CreateAllButtons () {

	// buffs.style.marginBottom = "176px"
	// debuffs.style.marginBottom = "176px"

	// for (let i = 0; i < center_block.GetChildCount(); i++) {
		// if (center_block.GetChild(i).id == "AllCustomButtons") {
			// center_block.GetChild(i).DeleteAsync(0)
		// }
	// }

	// let AllCustomButtons = $.CreatePanel("Panel", center_block, "AllCustomButtons");
	// AllCustomButtons.style.align = "right top"
	// AllCustomButtons.style.flowChildren = "right"
	// AllCustomButtons.style.marginTop = "52px"
	// AllCustomButtons.style.marginRight = "49px"

	// let ObserverWardMain = $.CreatePanel("Panel", AllCustomButtons, "ObserverWard");
	// ObserverWardMain.style.width = "60px"
	// ObserverWardMain.style.height = "35px"
	// ObserverWardMain.style.margin = "5px"

	// let SentryWardMain = $.CreatePanel("Panel", AllCustomButtons, "SentryWard");
	// SentryWardMain.style.width = "60px"
	// SentryWardMain.style.height = "35px"
	// SentryWardMain.style.margin = "5px"

	let ObserverWardMain = $("#ObserverWardPanel");
	let SentryWardMain = $("#SentryWardPanel");

	SetObserver(ObserverWardMain);
	SetSentry(SentryWardMain);

	// let ObserverWardButtonHotkey = $.CreatePanel("Panel", ObserverWardMain, "ObserverWardButtonHotkey");
	// ObserverWardButtonHotkey.style.backgroundColor = "#2127268a"
	// ObserverWardButtonHotkey.style.boxShadow = "fill #000000bb 1px 0px 1px 1px"
	// ObserverWardButtonHotkey.style.border = "1px solid black"
	// ObserverWardButtonHotkey.style.borderRadius = "2px"
	// ObserverWardButtonHotkey.style.zIndex = "1"
	// ObserverWardButtonHotkey.style.height = "13px"

	// let ObserverWardHotkeyLabel = $.CreatePanel("Label", ObserverWardButtonHotkey, "ObserverWardHotkeyLabel");
	// ObserverWardHotkeyLabel.text = String(GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_LEARN_STATS))
	// ObserverWardHotkeyLabel.style.fontSize = "10px"
	// ObserverWardHotkeyLabel.style.color = "white"

	// let SentryWardButtonHotkey = $.CreatePanel("Panel", SentryWardMain, "SentryWardButtonHotkey");
	// SentryWardButtonHotkey.style.backgroundColor = "#2127268a"
	// SentryWardButtonHotkey.style.boxShadow = "fill #000000bb 1px 0px 1px 1px"
	// SentryWardButtonHotkey.style.border = "1px solid black"
	// SentryWardButtonHotkey.style.borderRadius = "2px"
	// SentryWardButtonHotkey.style.zIndex = "1"
	// SentryWardButtonHotkey.style.height = "13px"

	// let SentryWardHotkeyLabel = $.CreatePanel("Label", SentryWardButtonHotkey, "SentryWardHotkeyLabel");
	// SentryWardHotkeyLabel.text = String(GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_PAUSE))
	// SentryWardHotkeyLabel.style.fontSize = "10px"
	// SentryWardHotkeyLabel.style.color = "white"

	// let ObserverCooldownLabel = $.CreatePanel("Label", ObserverWardMain, "ObserverCooldownLabel");
	// ObserverCooldownLabel.text = ""
	// ObserverCooldownLabel.style.fontSize = "14px"
	// ObserverCooldownLabel.style.color = "white"
	// ObserverCooldownLabel.style.zIndex = "1"
	// ObserverCooldownLabel.style.verticalAlign = "bottom"
	// ObserverCooldownLabel.style.marginLeft = "1px"
	// ObserverCooldownLabel.style.textShadow = "1px 1px 0px 2 #000000"

	// let SentryCooldownLabel = $.CreatePanel("Label", SentryWardMain, "SentryCooldownLabel");
	// SentryCooldownLabel.text = ""
	// SentryCooldownLabel.style.fontSize = "14px"
	// SentryCooldownLabel.style.color = "white"
	// SentryCooldownLabel.style.zIndex = "1"
	// SentryCooldownLabel.style.verticalAlign = "bottom"
	// SentryCooldownLabel.style.marginLeft = "1px"
	// SentryCooldownLabel.style.textShadow = "1px 1px 0px 2 #000000"

	// ObserverWardHotkeyLabel.style.textShadow = "1px 1px 0px 2 #000000"
	// SentryWardHotkeyLabel.style.textShadow = "1px 1px 0px 2 #000000"
	// ObserverWardHotkeyLabel.style.textAlign = "center"
	// SentryWardHotkeyLabel.style.textAlign = "center"

	// let ObserverWard = $.CreatePanel("Panel", ObserverWardMain, "ObserverWardIcon");
	// ObserverWard.style.width = "60px"
	// ObserverWard.style.height = "30px"
	// ObserverWard.style.backgroundImage = "url('s2r://panorama/images/conduct/ovw-bar-bg_png.vtex')"
	// ObserverWard.style.verticalAlign = "bottom"

	// let SentryWard = $.CreatePanel("Panel", SentryWardMain, "SentryWardIcon");
	// SentryWard.style.width = "60px"
	// SentryWard.style.height = "30px"
	// SentryWard.style.backgroundImage = "url('s2r://panorama/images/conduct/ovw-bar-bg_png.vtex')"
	// SentryWard.style.verticalAlign = "bottom"

	let ObserverWard = $("#ObserverWardIcon");
	let SentryWard = $("#SentryWardIcon");

	$.CreatePanelWithProperties("DOTAItemImage", ObserverWard, "observer_image", { style: "width:100%;height:100%;", src: "file://{images}/items/ward_observer.png",});
	$.CreatePanelWithProperties("DOTAItemImage", SentryWard, "sentry_image", { style: "width:100%;height:100%;", src: "file://{images}/items/ward_sentry.png" });

	// let SentryWardCount = $.CreatePanel("Label", SentryWard, "SentryWardCount");
	// let ObserverWardCount = $.CreatePanel("Label", ObserverWard, "ObserverWardCount");
	// SentryWardCount.style.color = "white"
	// ObserverWardCount.style.color = "white"
	// SentryWardCount.style.align = "right bottom"
	// ObserverWardCount.style.align = "right bottom"
	// SentryWardCount.style.textShadow = "0px 0px 3px 1 red"
	// ObserverWardCount.style.textShadow = "0px 0px 3px 1 red"

	$.Schedule( 1/144, ButtonsUpdate );
	$.Schedule( 1/144, WardParticlesUpdate );
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

	let ObserverWardHotkeyLabel = $("#ObserverWardHotkeyLabel");
	let SentryWardHotkeyLabel = $("#SentryWardHotkeyLabel");

	// ObserverWardHotkeyLabel.text = String(GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_ACTIVATE_GLYPH));
	// SentryWardHotkeyLabel.text = String(GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_SPRAY_WHEEL));

	// if (default_button_for_observer != GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_LEARN_STATS) ) {
		// RegisterKeybindObserver();
	// }

	// if (default_button_for_sentry != GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_PAUSE) ) {
		// RegisterKeybindSentry();
	// }

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

	$.Schedule( 1/144, ButtonsUpdate );
}

let ParticleWard;
let lastAbilityWard = -1;

function WardParticlesUpdate () {
	//$.Msg( Abilities.GetLocalPlayerActiveAbility())

	if (Abilities.GetLocalPlayerActiveAbility() != lastAbilityWard) {
		lastAbilityWard = Abilities.GetLocalPlayerActiveAbility()
		if (ParticleWard) {
			Particles.DestroyParticleEffect(ParticleWard, true)
			ParticleWard = undefined;
		}
		if ( (Abilities.GetLocalPlayerActiveAbility() != 1) && (Abilities.GetAbilityName(Abilities.GetLocalPlayerActiveAbility()) == "custom_ability_observer") ) {
			ParticleWard = Particles.CreateParticle("particles/ui_mouseactions/range_finder_ward_aoe.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()) );
		}
		if ( (Abilities.GetLocalPlayerActiveAbility() != 1) && (Abilities.GetAbilityName(Abilities.GetLocalPlayerActiveAbility()) == "custom_ability_sentry") ) {
			ParticleWard = Particles.CreateParticle("particles/ui_mouseactions/range_finder_ward_aoe.vpcf", ParticleAttachment_t.PATTACH_ABSORIGIN_FOLLOW, Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID()) );
		}

	}

	if (ParticleWard) {
		const cursor = GameUI.GetCursorPosition();
		const worldPosition = GameUI.GetScreenWorldPosition(cursor);
		Particles.SetParticleControl(ParticleWard, 0, Entities.GetAbsOrigin( Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) );
		Particles.SetParticleControl(ParticleWard, 1, [ 255, 255, 255 ]);
		Particles.SetParticleControl(ParticleWard, 6, [ 255, 255, 255 ]);
	    Particles.SetParticleControl(ParticleWard, 2, worldPosition);

		if ( (Abilities.GetLocalPlayerActiveAbility() != 1) && (Abilities.GetAbilityName(Abilities.GetLocalPlayerActiveAbility()) == "custom_ability_observer") ) {
			Particles.SetParticleControl(ParticleWard, 11, [ 0, 0, 0 ]);
			Particles.SetParticleControl(ParticleWard, 3, [ 1600, 1600, 1600 ]);

		} else if ( (Abilities.GetLocalPlayerActiveAbility() != 1) && (Abilities.GetAbilityName(Abilities.GetLocalPlayerActiveAbility()) == "custom_ability_sentry") ) {
			Particles.SetParticleControl(ParticleWard, 11, [ 1, 0, 0 ]);
			Particles.SetParticleControl(ParticleWard, 3, [ 700, 700, 700 ]);
		}
	}

    $.Schedule(1/144, WardParticlesUpdate)
}

(function () {
  //RegisterKeybindObserver()
  //RegisterKeybindSentry()
  CreateAllButtons()
})();

function RegisterKeybindObserver () {
  default_button_for_observer = GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_ACTIVATE_GLYPH);
  Game.CreateCustomKeyBind(default_button_for_observer, "use_observer");
  Game.AddCommand("use_observer", CastAbilityObserver, "", 0);
}

function RegisterKeybindSentry () {
  default_button_for_sentry = GetGameKeybind(DOTAKeybindCommand_t.DOTA_KEYBIND_SPRAY_WHEEL);
  Game.CreateCustomKeyBind(default_button_for_sentry, "use_sentry");
  Game.AddCommand("use_sentry", CastAbilitySentry, "", 0);
}

function GetGameKeybind (command) {
  return Game.GetKeybindForCommand(command);
}

function CastAbilityObserver() {

}

function CastAbilitySentry() {

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
