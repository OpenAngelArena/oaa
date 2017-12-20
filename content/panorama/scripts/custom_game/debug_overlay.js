/* global GameEvents, $ */
'use strict';

(function () {
  GameEvents.Subscribe('debug_overlay_update', function (x) {
    // $.Msg('<- Update');
    UpdateDebugOverlay(x);
  });
  // $.Msg('Forcing Debug Overlay Update');
  RequestDebugOverlayUpdate();
}());

function RequestDebugOverlayUpdate () {
  // $.Msg('-> Update_Request');
  GameEvents.SendCustomGameEventToServer('debug_overlay_request', {});
}

function UpdateDebugOverlay (keys) {
  // $.Msg('Updating Overlay');
  UpdateGroup(null, keys.value);
  TraverseOverlayAndUpdate(keys.value);
}

function TraverseOverlayAndUpdate (group) {
  // $.Msg(group.Children['1'])
  // $.Msg(group)
  for (var i = 1; i <= group.ChildCount; i++) {
    var item = group.Children[String(i)];
    // $.Msg(item);
    if (item.type === 'group') {
      UpdateGroup(group, item);
      TraverseOverlayAndUpdate(item);
    } else if (item.type === 'entry') {
      UpdateEntry(group, item);
    }
  }
}

function UpdateGroup (parent, group) {
  if (parent === null) {
    // $.Msg('Updating root group');
  } else {
    // $.Msg('Updating group ' + group.Name + ' of group ' + parent.Name);
    var groupID = 'DebugOverlay:' + group.Name;
    var parentID = 'DebugOverlay:' + parent.Name;
    var parentPanel = $.GetContextPanel().FindChildTraverse(parentID);
    var child = parentPanel.FindChildTraverse(groupID);

    // $.Msg(child);
    // $.Msg(parentPanel);

    if (child === null) { // NOTE: for some reason this is always true
      // $.Msg('Creating new group ' + group.Name + ' in Overlay');
      var button = $.CreatePanel('Button', parentPanel, groupID + ':InfoButton');
      button.SetHasClass('DebugOverlayButton', true);
      button.onactivate = 'ToggleGroup("' + groupID + '")'; // NOTE: onactivate does not work so no collapsing of groups for now
      var label = $.CreatePanel('Label', button, groupID + ':InfoLabel');
      label.SetHasClass('DebugOverlayEntry', true);
      child = $.CreatePanel('Panel', parentPanel, groupID);
      child.SetHasClass('DebugOverlayGroup', true);
    }
    // $.Msg('Updating group ' + group.Name + ' in Overlay');
    var grouplabel = parentPanel.FindChildTraverse(groupID + ':InfoLabel');
    grouplabel.text = group.DisplayName;
    grouplabel.style.color = group.Color;
  }
}

function UpdateEntry (parent, entry) {
  // $.Msg('Updating entry ' + entry.Name + ' of group ' + parent.Name)
  var entryID = 'DebugOverlay:' + entry.Name;
  var parentID = 'DebugOverlay:' + parent.Name;
  var parentPanel = $.GetContextPanel().FindChildTraverse(parentID);
  var child = parentPanel.FindChild(entryID);

  // $.Msg(child);
  // $.Msg(parentPanel);

  if (child === null) { // NOTE: for some reason this is always true
    // $.Msg('Creating new entry in Overlay');
    child = $.CreatePanel('Label', parentPanel, entryID);
    child.SetHasClass('DebugOverlayEntry', true);
  }
  // $.Msg('Updating entry in Overlay');
  child.text = entry.DisplayName + ': ' + entry.Value;
  child.style.color = entry.Color;
}
