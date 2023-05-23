/* global Players, $, GameEvents, CustomNetTables, Game */

const console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectNGP;
}

function onNGPChange () {
  const playerID = Game.GetLocalPlayerID();
  const teamID = Players.GetTeam(playerID);
  const teamName = teamID === 2 ? 'good' : 'bad';
  const data = CustomNetTables.GetTableValue('ngp', teamName);

  console.log(data);

  function OnNeedGreedPass (item) {
    generateNGPPanel(item.id, item.item, item.title, item.description, item.buildsInto);
  }

  Object.keys(data).forEach(function (i) {
    const item = data[i];
    item.buildsInto = Object.keys(item.buildsInto).map(function (i) { return item.buildsInto[i]; });
    OnNeedGreedPass(item);
  });
}

const NGPOption = {
};

function SelectNGP (option) {
  const panel = $.GetContextPanel();
  let id = panel.id.split('ItemPanel_');

  if (id.length !== 2) {
    return;
  }
  id = id[1];
  // var needsSchedule = !NGPOption[id];

  NGPOption[id] = option;
  $.Schedule(0.5, function () {
    RemoveNeedGreedPass({
      id: id
    });
    option = NGPOption[id];
    delete NGPOption[id];

    GameEvents.SendCustomGameEventToServer('ngp_selection', {
      id: id,
      option: option
    });
  });
}

function RemoveNeedGreedPass (data) {
  const activePanel = getPanelForId(data.id);
  activePanel.style['animation-direction'] = 'reverse';

  $.Schedule(0.2, function () {
    activePanel.RemoveAndDeleteChildren();
    activePanel.DeleteAsync(0);
  });
}

function getPanelForId (id) {
  return $('#' + idNameForId(id));
}

function idNameForId (id) {
  return 'ItemPanel_' + id;
}

// group id doesn't work
let ngpGroupIndex = 0;
const existingPanels = {};
function generateNGPPanel (id, item, title, description, buildsInto) {
  console.log('Generating panel for item id ', id);
  if (existingPanels[id]) {
    return;
  }

  existingPanels[id] = true;
  const panel = $.CreatePanel('Panel', $('#NGPItemHopper'), idNameForId(id));
  panel.BLoadLayout('file://{resources}/layout/custom_game/need_greed_pass/panel.xml', false, false);

  panel.FindChildrenWithClassTraverse('DataItemId').forEach(function (elem) {
    elem.itemname = item;
  });
  panel.FindChildrenWithClassTraverse('DataItemTitle').forEach(function (elem) {
    elem.text = title;
  });
  panel.FindChildrenWithClassTraverse('DataItemDescription').forEach(function (elem) {
    elem.text = description;
  });
  panel.FindChildrenWithClassTraverse('DataUpgradesInto').forEach(function (elem) {
    elem.text = description;
    buildsInto.forEach(function (item) {
      const itemImage = $.CreatePanel('DOTAItemImage', elem, '');
      itemImage.itemname = item;
    });
  });

  // setting group doesn't work :/
  const ngpId = ngpGroupIndex++;
  panel.FindChildrenWithClassTraverse('NGPRadio').forEach(function (elem) {
    elem.group = 'NGP' + ngpId;
  });

  $('#NeedGreedPassSlider').SetHasClass('Expanded', true);

  return panel;
}

// down here so that static vars get declared
(function () {
  CustomNetTables.SubscribeNetTableListener('ngp', onNGPChange);
  onNGPChange();
}());
