var console = {
  log: $.Msg.bind($)
};

var itemIdIndex = 0;
function onNGPChange () {
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID)
  var teamName = teamID === 2 ? 'good' : 'bad';
  var data = CustomNetTables.GetTableValue('ngp', teamName);

  console.log(data);

  function OnNeedGreedPass (item) {
    generateNGPPanel(item.id, item.item, item.title, item.description);
  }

  Object.keys(data).forEach(function (i) {
    var item = data[i];
    if (!item.finished == true) {
      OnNeedGreedPass(item);
    }
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
  var needsSchedule = !NGPOption[id];

  NGPOption[id] = option;
    option = NGPOption[id];
    delete NGPOption[id];
    //VOTED!
    panel.FindChildrenWithClassTraverse('NGPRadio').forEach(function (elem) {
      elem.RemoveAndDeleteChildren();
    });
    panel.FindChildrenWithClassTraverse('NGPButtons').forEach(function (elem) {
      var votedlabel = $.CreatePanel('Label', elem, '');
      votedlabel.AddClass("VotedLabel");
      votedlabel.text = $.Localize("#ngp_" + option);
    });
    GameEvents.SendCustomGameEventToServer('ngp_selection', {
      id: id,
      option: option
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
var existingPanels = {};

function generateNGPPanel (id, item, title, description) {
  console.log('Generating panel for item id ', id)
  if (existingPanels[id]) {
    return;
  }

  existingPanels[id] = true;
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

  // setting group doesn't work :/
  var ngpId = ngpGroupIndex++;
  panel.FindChildrenWithClassTraverse('NGPRadio').forEach(function (elem) {
    elem.group = 'NGP' + ngpId;
  });

  $("#NeedGreedPassSlider").SetHasClass('Expanded', true)
  timerByOneDown(panel, 60);
  return panel;
}

function timerByOneDown(panel, time) {
  var newtime = time - 1;
  if (newtime != 0) {
    panel.FindChildrenWithClassTraverse('ItemTimer').forEach(function (elem) {
      elem.text = newtime;
    });
    $.Schedule(1, function() {
      timerByOneDown(panel, newtime)
    });
  } else {
      var id = panel.id.split('ItemPanel_');
      if (id.length !== 2) {
        return;
      }
      id = id[1];
      RemoveNeedGreedPass({
        id: id
      });
  }
}

// down here so that static vars get declared
(function () {
  CustomNetTables.SubscribeNetTableListener('ngp', onNGPChange);
  onNGPChange();
}());

