/* global $, Game, GameEvents, Players, Buffs, FindDotaHudElement, FindModifier, HasModifier, GetStackCount */

'use strict';

const HUDElements = FindDotaHudElement('HUDElements');
const centerBlock = HUDElements.FindChildTraverse('center_block');
let ObserverWardPanel;
let SentryWardPanel;
let ObserverCooldownLabel;
let SentryCooldownLabel;
let ObserverWardCount;
let SentryWardCount;

function CreateAllButtons () {
  // Delete previous instances of 'CustomWardsPanel' for testing purposes in tools,
  // because of constant recompiling after every change
  for (let i = 0; i < centerBlock.GetChildCount(); i++) {
    if (centerBlock.GetChild(i).id === 'CustomWardsPanel') {
      centerBlock.GetChild(i).DeleteAsync(0);
    }
  }

  // Move buffs and debuffs a little bit up
  const buffs = HUDElements.FindChildTraverse('buffs');
  const debuffs = HUDElements.FindChildTraverse('debuffs');
  buffs.style.marginBottom = '176px';
  debuffs.style.marginBottom = '176px';

  const customButtons = $.CreatePanel('Panel', centerBlock, 'CustomWardsPanel');
  customButtons.style.align = 'right top';
  customButtons.style.flowChildren = 'right';
  customButtons.style.marginTop = '52px';
  customButtons.style.marginRight = '125px';

  ObserverWardPanel = $.CreatePanel('Panel', customButtons, 'ObserverWardPanel');
  ObserverWardPanel.style.width = '60px';
  ObserverWardPanel.style.height = '35px';
  ObserverWardPanel.style.margin = '5px';
  ObserverWardPanel.style.tooltipPosition = 'left';
  ObserverWardPanel.style.horizontalAlign = 'right';
  ObserverWardPanel.style.verticalAlign = 'center';

  SentryWardPanel = $.CreatePanel('Panel', customButtons, 'SentryWardPanel');
  SentryWardPanel.style.width = '60px';
  SentryWardPanel.style.height = '35px';
  SentryWardPanel.style.margin = '5px';
  SentryWardPanel.style.tooltipPosition = 'left';
  SentryWardPanel.style.horizontalAlign = 'right';
  SentryWardPanel.style.verticalAlign = 'center';

  // const ObserverWardButtonHotkey = $.CreatePanel("Panel", ObserverWardPanel, "ObserverWardButtonHotkey");
  // ObserverWardButtonHotkey.style.backgroundColor = "#2127268a"
  // ObserverWardButtonHotkey.style.boxShadow = "fill #000000bb 1px 0px 1px 1px"
  // ObserverWardButtonHotkey.style.border = "1px solid black"
  // ObserverWardButtonHotkey.style.borderRadius = "2px"
  // ObserverWardButtonHotkey.style.zIndex = "1"
  // ObserverWardButtonHotkey.style.height = "13px"

  // const ObserverWardHotkeyLabel = $.CreatePanel("Label", ObserverWardButtonHotkey, "ObserverWardHotkeyLabel");
  // ObserverWardHotkeyLabel.text = "Z"
  // ObserverWardHotkeyLabel.style.fontSize = "10px"
  // ObserverWardHotkeyLabel.style.color = "white"
  // ObserverWardHotkeyLabel.style.textShadow = "1px 1px 0px 2 #000000"
  // ObserverWardHotkeyLabel.style.textAlign = "center"

  // const SentryWardButtonHotkey = $.CreatePanel("Panel", SentryWardPanel, "SentryWardButtonHotkey");
  // SentryWardButtonHotkey.style.backgroundColor = "#2127268a"
  // SentryWardButtonHotkey.style.boxShadow = "fill #000000bb 1px 0px 1px 1px"
  // SentryWardButtonHotkey.style.border = "1px solid black"
  // SentryWardButtonHotkey.style.borderRadius = "2px"
  // SentryWardButtonHotkey.style.zIndex = "1"
  // SentryWardButtonHotkey.style.height = "13px"

  // const SentryWardHotkeyLabel = $.CreatePanel("Label", SentryWardButtonHotkey, "SentryWardHotkeyLabel");
  // SentryWardHotkeyLabel.text = "Y"
  // SentryWardHotkeyLabel.style.fontSize = "10px"
  // SentryWardHotkeyLabel.style.color = "white"
  // SentryWardHotkeyLabel.style.textShadow = "1px 1px 0px 2 #000000"
  // SentryWardHotkeyLabel.style.textAlign = "center"

  ObserverCooldownLabel = $.CreatePanel('Label', ObserverWardPanel, 'ObserverCooldownLabel');
  ObserverCooldownLabel.text = '00:00';
  ObserverCooldownLabel.style.fontSize = '14px';
  ObserverCooldownLabel.style.color = 'white';
  ObserverCooldownLabel.style.zIndex = '1';
  ObserverCooldownLabel.style.verticalAlign = 'bottom';
  ObserverCooldownLabel.style.marginLeft = '1px';
  ObserverCooldownLabel.style.textShadow = '1px 1px 0px 2 #000000';

  SentryCooldownLabel = $.CreatePanel('Label', SentryWardPanel, 'SentryCooldownLabel');
  SentryCooldownLabel.text = '00:00';
  SentryCooldownLabel.style.fontSize = '14px';
  SentryCooldownLabel.style.color = 'white';
  SentryCooldownLabel.style.zIndex = '1';
  SentryCooldownLabel.style.verticalAlign = 'bottom';
  SentryCooldownLabel.style.marginLeft = '1px';
  SentryCooldownLabel.style.textShadow = '1px 1px 0px 2 #000000';

  const ObserverWardIcon = $.CreatePanel('Panel', ObserverWardPanel, 'ObserverWardIcon');
  ObserverWardIcon.style.width = '60px';
  ObserverWardIcon.style.height = '40px';
  ObserverWardIcon.style.backgroundImage = "url('s2r://panorama/images/conduct/ovw-bar-bg_png.vtex')";
  ObserverWardIcon.style.verticalAlign = 'top';
  ObserverWardIcon.style.horizontalAlign = 'center';

  const SentryWardIcon = $.CreatePanel('Panel', SentryWardPanel, 'SentryWardIcon');
  SentryWardIcon.style.width = '60px';
  SentryWardIcon.style.height = '40px';
  SentryWardIcon.style.backgroundImage = "url('s2r://panorama/images/conduct/ovw-bar-bg_png.vtex')";
  SentryWardIcon.style.verticalAlign = 'top';
  SentryWardIcon.style.horizontalAlign = 'center';

  ObserverWardCount = $.CreatePanel('Label', ObserverWardIcon, 'ObserverWardCountLabel');
  ObserverWardCount.text = '0';
  ObserverWardCount.style.color = 'white';
  ObserverWardCount.style.align = 'right bottom';
  ObserverWardCount.style.textShadow = '0px 0px 3px 1 red';
  ObserverWardCount.style.zIndex = '1';

  SentryWardCount = $.CreatePanel('Label', SentryWardIcon, 'SentryWardCountLabel');
  SentryWardCount.text = '0';
  SentryWardCount.style.color = 'white';
  SentryWardCount.style.align = 'right bottom';
  SentryWardCount.style.textShadow = '0px 0px 3px 1 red';
  SentryWardCount.style.zIndex = '1';

  $.CreatePanel('DOTAItemImage', ObserverWardIcon, 'observer_image', { style: 'width:100%;height:100%;', src: 'file://{images}/items/ward_observer.png' });
  $.CreatePanel('DOTAItemImage', SentryWardIcon, 'sentry_image', { style: 'width:100%;height:100%;', src: 'file://{images}/items/ward_sentry.png' });

  SetObserver(ObserverWardPanel);
  SetSentry(SentryWardPanel);

  $.Schedule(1 / 144, ButtonsUpdate);
}

function ButtonsUpdate () {
  if (Players.GetLocalPlayerPortraitUnit() !== Players.GetPlayerHeroEntityIndex(Game.GetLocalPlayerID())) {
    ObserverWardPanel.style.opacity = 0;
    ObserverWardPanel.style.visibility = 'collapse';
    SentryWardPanel.style.opacity = 0;
    SentryWardPanel.style.visibility = 'collapse';
    $.Schedule(0.1, ButtonsUpdate);
    return;
  } else {
    ObserverWardPanel.style.opacity = 1;
    ObserverWardPanel.style.visibility = 'visible';
    SentryWardPanel.style.opacity = 1;
    SentryWardPanel.style.visibility = 'visible';
  }

  const hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());

  if (HasModifier(hero, 'modifier_ui_custom_observer_ward_charges')) {
    ObserverWardCount.text = String(GetStackCount(hero, 'modifier_ui_custom_observer_ward_charges'));

    if (ObserverWardCount.text === '0') {
      ObserverWardPanel.style.opacity = 0.7;
    } else {
      ObserverWardPanel.style.opacity = 1;
    }

    const time = Math.max(0, Math.ceil(Buffs.GetRemainingTime(hero, FindModifier(hero, 'modifier_ui_custom_observer_ward_charges'))));
    let min = Math.trunc(time / 60);
    let seconds = time - 60 * min;

    min = String(min - 60 * Math.trunc(min / 60));
    seconds = String(seconds);
    if (seconds < 10) {
      seconds = '0' + seconds;
    }

    ObserverCooldownLabel.text = min + ':' + seconds;
  }

  if (HasModifier(hero, 'modifier_ui_custom_sentry_ward_charges')) {
    SentryWardCount.text = String(GetStackCount(hero, 'modifier_ui_custom_sentry_ward_charges'));

    if (SentryWardCount.text === '0') {
      SentryWardPanel.style.opacity = 0.7;
    } else {
      SentryWardPanel.style.opacity = 1;
    }

    const time = Math.max(0, Math.ceil(Buffs.GetRemainingTime(hero, FindModifier(hero, 'modifier_ui_custom_sentry_ward_charges'))));
    let min = Math.trunc(time / 60);
    let seconds = time - 60 * min;

    min = String(min - 60 * Math.trunc(min / 60));
    seconds = String(seconds);
    if (seconds < 10) {
      seconds = '0' + seconds;
    }

    SentryCooldownLabel.text = min + ':' + seconds;
  }

  $.Schedule(0.1, ButtonsUpdate);
}

(function () {
  CreateAllButtons();
})();

function CastAbilityObserver () {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', { type: 'observer' });
}

function CastAbilitySentry () {
  GameEvents.SendCustomGameEventToServer('custom_ward_button_pressed', { type: 'sentry' });
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
