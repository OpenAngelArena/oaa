/* global Players, $, GameEvents, CustomNetTables, Game */

var console = {
  log: $.Msg.bind($)
};

if (typeof module !== 'undefined' && module.exports) {
  module.exports = SelectNGP;
}

var idToRemove = [];


function onNGPChange (table_name, key, data) {
  var playerID = Game.GetLocalPlayerID();
  var teamID = Players.GetTeam(playerID)
  var teamName = teamID === 2 ? 'good' : 'bad';

  console.log(data);
  console.log(key);

  if (data.team == teamName) {
    if (!data.finished) {
      generateNGPPanel(data.id, data.item, data.title, data.description, data.votes, data.heroname);
    } else if (idToRemove.indexOf(data.id) == -1) {
      idToRemove.push(data.id);
    }
  }

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
  panel.FindChildrenWithClassTraverse('NGPButtons').forEach(function (elem) {
    elem.RemoveClass("bold");
  });
  panel.FindChildrenWithClassTraverse(option).forEach(function (elem) {
    console.log(option);
    elem.AddClass("bold");
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

function generateNGPPanel (id, item, title, description, votes, heronames) {
  if (existingPanels[id]) {
    var activePanel = getPanelForId(id);
    if (activePanel!=null) {
      activePanel.FindChildrenWithClassTraverse('TopLine').forEach(function (elem) {
        Object.keys(votes).forEach(function(vote) {
          if (elem.FindChildTraverse(vote) == null) {
            var addicon = $.CreatePanel('DOTAHeroImage', elem, vote);
            addicon.AddClass("HeroImage");
            addicon.heroname = heronames[vote];
            addicon.heroimagestyle="portrait" 
          }        
        });
      });
    }
    return;
  }

  console.log('Generating panel for item id ', id)
  existingPanels[id] = true;
  var holder = $('#NGPItemHopper');
  var panel = $.CreatePanel('Panel', holder, idNameForId(id));
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
  timerByOneDown(panel, 60, id);
  return panel;
}

function timerByOneDown(panel, time, id) {
  var newtime = time - 1;
  if (idToRemove.indexOf(id) > -1) {
    RemoveNeedGreedPass({
        id: id
      });
  } else if (newtime != 0) {
    panel.FindChildrenWithClassTraverse('ItemTimer').forEach(function (elem) {
      elem.text = newtime;
    });
    $.Schedule(1, function() {
      timerByOneDown(panel, newtime, id)
    });
  } else {
      RemoveNeedGreedPass({
        id: id
      });
  }
}

// down here so that static vars get declared
(function () {
  CustomNetTables.SubscribeNetTableListener('ngp', onNGPChange);
}());

