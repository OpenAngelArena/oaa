/* global $, GameEvents */

function TopNotification (msg) {
  AddNotification(msg, $('#TopNotifications'));
}

function BottomNotification (msg) {
  AddNotification(msg, $('#BottomNotifications'));
}

function TopRemoveNotification (msg) {
  RemoveNotification(msg, $('#TopNotifications'));
}

function BottomRemoveNotification (msg) {
  RemoveNotification(msg, $('#BottomNotifications'));
}

function RemoveNotification (msg, panel) {
  var count = msg.count;
  if (count > 0 && panel.GetChildCount() > 0) {
    var start = panel.GetChildCount() - count;
    if (start < 0) {
      start = 0;
    }

    for (var i = start; i < panel.GetChildCount(); i++) {
      var lastPanel = panel.GetChild(i);
      // lastPanel.SetAttributeInt("deleted", 1)
      lastPanel.deleted = true;
      lastPanel.DeleteAsync(0);
    }
  }
}

function AddNotification (msg, panel) {
  var newNotification = true;
  var lastNotification = panel.GetChild(panel.GetChildCount() - 1);
  // $.Msg(msg)

  msg.continue = msg.continue || false;
  // msg.continue = true

  if (lastNotification != null && msg.continue) {
    newNotification = false;
  }

  if (newNotification) {
    lastNotification = $.CreatePanel('Panel', panel, '');
    lastNotification.AddClass('NotificationLine');
    lastNotification.hittest = false;
  }

  var notification = null;

  if (msg.hero != null) {
    notification = $.CreatePanel('DOTAHeroImage', lastNotification, '');
  } else if (msg.image != null) {
    notification = $.CreatePanel('Image', lastNotification, '');
  } else if (msg.ability != null) {
    notification = $.CreatePanel('DOTAAbilityImage', lastNotification, '');
  } else if (msg.item != null) {
    notification = $.CreatePanel('DOTAItemImage', lastNotification, '');
  } else {
    notification = $.CreatePanel('Label', lastNotification, '');
  }

  if (typeof (msg.duration) !== 'number') {
    // $.Msg("[Notifications] Notification Duration is not a number!")
    msg.duration = 3;
  }

  if (newNotification) {
    $.Schedule(msg.duration, function () {
      // $.Msg('callback')
      if (lastNotification.deleted) {
        return;
      }

      lastNotification.DeleteAsync(0);
    });
  }

  if (msg.hero != null) {
    notification.heroimagestyle = msg.imagestyle || 'icon';
    notification.heroname = msg.hero;
    notification.hittest = false;
  } else if (msg.image != null) {
    notification.SetImage(msg.image);
    notification.hittest = false;
  } else if (msg.ability != null) {
    notification.abilityname = msg.ability;
    notification.hittest = false;
  } else if (msg.item != null) {
    notification.itemname = msg.item;
    notification.hittest = false;
  } else {
    notification.html = true;
    var text = msg.text || 'No Text provided';
    notification.text = $.Localize(text);
    notification.hittest = false;
    notification.AddClass('TitleText');
  }

  if (msg.class) {
    notification.AddClass(msg.class);
  } else {
    notification.AddClass('NotificationMessage');
  }

  if (msg.style) {
    for (var key in msg.style) {
      var value = msg.style[key];
      notification.style[key] = value;
    }
  }
}

(function () {
  GameEvents.Subscribe('top_notification', TopNotification);
  GameEvents.Subscribe('bottom_notification', BottomNotification);
  GameEvents.Subscribe('top_remove_notification', TopRemoveNotification);
  GameEvents.Subscribe('bottom_remove_notification', BottomRemoveNotification);
})();
