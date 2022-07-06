/* global Game, GameEvents, GameUI, Players, Entities, Buffs */

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

function CreateAllButtons () {
  let ObserverWardMain = $('#ObserverWardPanel');
  let SentryWardMain = $('#SentryWardPanel');

  SetObserver(ObserverWardMain);
  SetSentry(SentryWardMain);

  let ObserverWard = $('#ObserverWardIcon');
  let SentryWard = $('#SentryWardIcon');

  $.CreatePanelWithProperties('DOTAItemImage', ObserverWard, 'observer_image', { style: 'width:100%;height:100%;', src: 'file://{images}/items/ward_observer.png' });
  $.CreatePanelWithProperties('DOTAItemImage', SentryWard, 'sentry_image', { style: 'width:100%;height:100%;', src: 'file://{images}/items/ward_sentry.png' });

  $.Schedule(1 / 144, ButtonsUpdate);
}

function ButtonsUpdate () {
  let ObserverWardPanel = $('#ObserverWardPanel');
  let SentryWardPanel = $('#SentryWardPanel');
  let ObserverCooldownLabel = $('#ObserverCooldownLabel');
  let SentryCooldownLabel = $('#SentryCooldownLabel');

  if (Players.GetLocalPlayerPortraitUnit() !== Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) {
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

  let ObserverCountLabel = $('#ObserverWardCountLabel');
  let SentryCountLabel = $('#SentryWardCountLabel');
  let hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

  if (HasModifier(hero, 'modifier_ui_custom_observer_ward_charges')) {
    ObserverCountLabel.text = String(GetStackCount('modifier_ui_custom_observer_ward_charges'));

    let time = Math.ceil(Buffs.GetRemainingTime(hero, FindModifier(hero, 'modifier_ui_custom_observer_ward_charges')));
    let min = Math.trunc(time / 60);
    let seconds = time - 60 * min;

    min = String(min - 60 * Math.trunc(min / 60));
    seconds = String(seconds);
    if (seconds < 10) {
      seconds = '0' + seconds;
    }

    ObserverCooldownLabel.text = min + ':' + seconds;
    // if (time > 120) {
      // ObserverCooldownLabel.visible = false;
    // } else {
      // ObserverCooldownLabel.visible = true;
    // }
  }

  if (HasModifier(hero, 'modifier_ui_custom_sentry_ward_charges')) {
    SentryCountLabel.text = String(GetStackCount('modifier_ui_custom_sentry_ward_charges'));

    let time = Math.ceil(Buffs.GetRemainingTime(hero, FindModifier(hero, 'modifier_ui_custom_sentry_ward_charges')));
    let min = Math.trunc(time / 60);
    let seconds = time - 60 * min;

    min = String(min - 60 * Math.trunc(min / 60));
    seconds = String(seconds);
    if (seconds < 10) {
      seconds = '0' + seconds;
    }

    SentryCooldownLabel.text = min + ':' + seconds;
    // if (time > 120) {
      // SentryCooldownLabel.visible = false;
    // } else {
      // SentryCooldownLabel.visible = true;
    // }
  }

  $.Schedule(1 / 144, ButtonsUpdate);
}

(function () {
  CreateAllButtons();
})();

function CastAbilityObserver () {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', {'type': 'observer'});
}

function CastAbilitySentry () {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', {'type': 'sentry'});
}

function SetObserver (panel) {
  panel.SetPanelEvent(
    'onmouseactivate',
    function () {
      CastAbilityObserver();
    }
  );
  panel.SetPanelEvent(
    'oncontextmenu',
    function () {
      CastAbilityObserver();
    }
  );
}

function SetSentry (panel) {
  panel.SetPanelEvent(
    'onmouseactivate',
    function () {
      CastAbilitySentry();
    }
  );
  panel.SetPanelEvent(
    'oncontextmenu',
    function () {
      CastAbilitySentry();
    }
  );
}
