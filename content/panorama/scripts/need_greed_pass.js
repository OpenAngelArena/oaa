/* global Players, $, GameEvents, CustomNetTables, Game */

var console = {
  log: $.Msg.bind($)
};

if (module && module.exports) {
  module.exports = SelectNGP;
}

function onNGPChange () {
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID);
  var teamName = teamID === 2 ? 'good' : 'bad';
  var data = CustomNetTables.GetTableValue('ngp', teamName);

  console.log(data);

  function OnNeedGreedPass (item) {
    generateNGPPanel(item.id, item.item, item.title, item.description, item.buildsInto);
  }

  Object.keys(data).forEach(function (i) {
    var item = data[i];
    item.buildsInto = Object.keys(item.buildsInto).map(function (i) { return item.buildsInto[i]; });
    OnNeedGreedPass(item);
  });
}

var NGPOption = {
};

function SelectNGP (option) {
  var panel = $.GetContextPanel();
  var id = panel.id.split('ItemPanel_');

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
  var activePanel = getPanelForId(data.id);
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
var ngpGroupIndex = 0;
var existingPanels = {};
function generateNGPPanel (id, item, title, description, buildsInto) {
  console.log('Generating panel for item id ', id);
  if (existingPanels[id]) {
    return;
  }

  existingPanels[id] = true;
  var panel = $.CreatePanel('Panel', $('#NGPItemHopper'), idNameForId(id));
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
      var itemImage = $.CreatePanel('DOTAItemImage', elem, '');
      itemImage.itemname = item;
    });
  });

  // setting group doesn't work :/
  var ngpId = ngpGroupIndex++;
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
