/* global FindDotaHudElement Game GameEvents Players Entities HasModifier */

if (typeof module !== 'undefined' && module.exports) {
  module.exports = ToggleInfo;
}

let isopen = false;

function ToggleInfo () {
  const infoPanel = FindDotaHudElement('InfoButton').GetParent();
  if (isopen) {
    isopen = false;
    if (Game.IsHUDFlipped()) {
      infoPanel.style.transform = 'translateX(-450px) scaleX(-1)';
    } else {
      infoPanel.style.transform = 'translateX(-450px)';
    }
  } else {
    isopen = true;
    infoPanel.style.transform = 'translateX(0)';

    const player = Players.GetLocalPlayer();
    let currentlySelectedUnit = Players.GetQueryUnit(player);
    if (currentlySelectedUnit === -1) {
      currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
    }
    if (Entities.IsValidEntity(currentlySelectedUnit)) {
      GameEvents.SendCustomGameEventToServer('oaa_modifier_info_request', { unit: currentlySelectedUnit });
    }
  }
}

function ModifierInfo (data) {
  const player = Players.GetLocalPlayer();
  let currentlySelectedUnit = Players.GetQueryUnit(player);
  if (currentlySelectedUnit === -1) {
    currentlySelectedUnit = Players.GetLocalPlayerPortraitUnit();
  }
  const infoPanel = FindDotaHudElement('InfoButton').GetParent();
  const hamPanel = infoPanel.FindChildTraverse('HAMTitle');
  const hamPanel2 = infoPanel.FindChildTraverse('HAMPenaltyList');
  const magusPanel = infoPanel.FindChildTraverse('MagusTitle');
  const magusPanel2 = infoPanel.FindChildTraverse('MagusBlackList');
  const magusPanel3 = infoPanel.FindChildTraverse('MagusGrayList');
  const multicastPanel = infoPanel.FindChildTraverse('MulticastTitle');
  const multicastPanel2 = infoPanel.FindChildTraverse('MulticastBlackList');
  const octarinesoulPanel = infoPanel.FindChildTraverse('OctarineSoulTitle');
  const octarinesoulPanel2 = infoPanel.FindChildTraverse('OctarineSoulPenaltyList');
  const proactivePanel = infoPanel.FindChildTraverse('ProActiveTitle');
  const proactivePanel2 = infoPanel.FindChildTraverse('ProActivePenaltyList');

  hamPanel.style.opacity = 0;
  hamPanel.style.visibility = 'collapse';
  hamPanel2.style.opacity = 0;
  hamPanel2.style.visibility = 'collapse';
  magusPanel.style.opacity = 0;
  magusPanel.style.visibility = 'collapse';
  magusPanel2.style.opacity = 0;
  magusPanel2.style.visibility = 'collapse';
  magusPanel3.style.opacity = 0;
  magusPanel3.style.visibility = 'collapse';
  multicastPanel.style.opacity = 0;
  multicastPanel.style.visibility = 'collapse';
  multicastPanel2.style.opacity = 0;
  multicastPanel2.style.visibility = 'collapse';
  octarinesoulPanel.style.opacity = 0;
  octarinesoulPanel.style.visibility = 'collapse';
  octarinesoulPanel2.style.opacity = 0;
  octarinesoulPanel2.style.visibility = 'collapse';
  proactivePanel.style.opacity = 0;
  proactivePanel.style.visibility = 'collapse';
  proactivePanel2.style.opacity = 0;
  proactivePanel2.style.visibility = 'collapse';

  if (HasModifier(currentlySelectedUnit, 'modifier_magus_oaa')) {
    magusPanel.style.opacity = 1;
    magusPanel.style.visibility = 'visible';
    magusPanel.style.color = '#aaccff';
    magusPanel.style.fontWeight = 'bold';
    magusPanel2.style.opacity = 1;
    magusPanel2.style.visibility = 'visible';
    magusPanel3.style.opacity = 1;
    magusPanel3.style.visibility = 'visible';
    if (Object.keys(data.magus_black_list).length !== 0) {
      let labelText = 'The following spells are blacklisted: ';

      for (const i in data.magus_black_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.magus_black_list[i]) + '; ';
      }
      magusPanel2.text = labelText;
      magusPanel3.text = '';
    }
    if (Object.keys(data.magus_gray_list).length !== 0) {
      let labelText = 'The following spells have reduced chance to proc: ';

      for (const i in data.magus_gray_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.magus_gray_list[i]) + '; ';
      }
      magusPanel3.text = labelText;
    }
  }
  if (HasModifier(currentlySelectedUnit, 'modifier_multicast_oaa')) {
    multicastPanel.style.opacity = 1;
    multicastPanel.style.visibility = 'visible';
    multicastPanel.style.fontWeight = 'bold';
    multicastPanel.style.color = '#aaccff';
    multicastPanel2.style.opacity = 1;
    multicastPanel2.style.visibility = 'visible';

    if (Object.keys(data.multicast_black_list).length !== 0) {
      let labelText = 'The following spells are blacklisted: ';
      for (const i in data.multicast_black_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.multicast_black_list[i]) + '; ';
      }
      multicastPanel2.text = labelText;
    }
  }
  if (HasModifier(currentlySelectedUnit, 'modifier_ham_oaa')) {
    hamPanel.style.opacity = 1;
    hamPanel.style.visibility = 'visible';
    hamPanel.style.fontWeight = 'bold';
    hamPanel.style.color = '#aaccff';
    hamPanel2.style.opacity = 1;
    hamPanel2.style.visibility = 'visible';

    if (Object.keys(data.ham_penalty_list).length !== 0) {
      let labelText = 'The following spells have a penalty: ';
      for (const i in data.ham_penalty_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.ham_penalty_list[i]) + '; ';
      }
      hamPanel2.text = labelText;
    }
  }
  if (HasModifier(currentlySelectedUnit, 'modifier_pro_active_oaa')) {
    proactivePanel.style.opacity = 1;
    proactivePanel.style.visibility = 'visible';
    proactivePanel.style.fontWeight = 'bold';
    proactivePanel.style.color = '#aaccff';
    proactivePanel2.style.opacity = 1;
    proactivePanel2.style.visibility = 'visible';

    if (Object.keys(data.pro_active_penalty_list).length !== 0) {
      let labelText = 'The following spells have a penalty: ';
      for (const i in data.pro_active_penalty_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.pro_active_penalty_list[i]) + '; ';
      }
      proactivePanel2.text = labelText;
    }
  }
  if (HasModifier(currentlySelectedUnit, 'modifier_octarine_soul_oaa')) {
    octarinesoulPanel.style.opacity = 1;
    octarinesoulPanel.style.visibility = 'visible';
    octarinesoulPanel.style.fontWeight = 'bold';
    octarinesoulPanel.style.color = '#aaccff';
    octarinesoulPanel2.style.opacity = 1;
    octarinesoulPanel2.style.visibility = 'visible';

    if (Object.keys(data.octarine_soul_penalty_list).length !== 0) {
      let labelText = 'The following spells have a penalty: ';
      for (const i in data.octarine_soul_penalty_list) {
        labelText = labelText + $.Localize('#' + 'DOTA_Tooltip_ability_' + data.octarine_soul_penalty_list[i]) + '; ';
      }
      octarinesoulPanel2.text = labelText;
    }
  }
}

function HideOrShowInfoButton () {
  const infoButton = FindDotaHudElement('InfoButton');
  const hidden = infoButton.style.opacity === '0.0';
  if (isopen) {
    ToggleInfo(); // close it first before hiding
  }
  if (hidden) {
    infoButton.style.opacity = 1;
    infoButton.style.visibility = 'visible';
  } else {
    infoButton.style.opacity = 0;
    infoButton.style.visibility = 'collapse';
  }
}

(function () {
  const infoButton = FindDotaHudElement('InfoButton');
  const infoPanel = infoButton.GetParent();
  if (Game.IsHUDFlipped()) {
    infoPanel.style.horizontalAlign = 'right';
    infoPanel.style.transform = 'translateX(-450px) scaleX(-1)';
    infoButton.style.transform = 'scaleX(-1)';
    infoButton.style.marginTop = '10%';
  } else {
    // Killcam (death summary) creation and removal event
    GameEvents.Subscribe('dota_player_update_killcam_unit', HideOrShowInfoButton);
  }
  GameEvents.Subscribe('oaa_modifier_info_update', ModifierInfo);
})();
