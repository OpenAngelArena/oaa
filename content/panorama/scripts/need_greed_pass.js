var console = {
  log: $.Msg.bind($)
};

var NGPOption = {
};
function SelectNGP (option) {
  var panel = $.GetContextPanel();
  var id = panel.id.split('ItemPanel_');

  if (id.length !== 2) {
    return;
  }
  id = id[1];
  var needsSchedule = !NGPOption[id];

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

  $.Schedule(0.2, function() {
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
function generateNGPPanel (id, item, title, description, buildsInto) {
  var panel = $.CreatePanel('Panel', $('#NGPItemHopper'), idNameForId(id));
  panel.BLoadLayout( "file://{resources}/layout/custom_game/need_greed_pass/panel.xml", false, false );

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

  return panel;
}
