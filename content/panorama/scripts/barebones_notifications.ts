/* global $, GameEvents */
'use strict';

interface BaseNotificationData {
  duration: number;
  class?: string;
  style?: VCSSStyleDeclaration;
  continue?: 0 | 1;
}

interface LabelNotificationData extends BaseNotificationData {
  text: string;
  replacement_map?: {[key: string]: number | string}
}

interface HeroImageNotificationData extends BaseNotificationData {
  hero: string;
  imagestyle?: 'icon' | 'portrait' | 'landscape';
}

interface AbilityImageNotificationData extends BaseNotificationData {
  ability: string;
}

interface ImageNotificationData extends BaseNotificationData {
  image: string;
}

interface ItemImageNotificationData extends BaseNotificationData {
  item: string;
}

type NotificationData = LabelNotificationData | HeroImageNotificationData | AbilityImageNotificationData | ImageNotificationData | ItemImageNotificationData

function TopNotification(msg: NotificationData) {
  AddNotification(msg, $('#TopNotifications'));
}

function BottomNotification(msg: NotificationData) {
  AddNotification(msg, $('#BottomNotifications'));
}

function TopRemoveNotification(msg: {count: number}) {
  RemoveNotification(msg, $('#TopNotifications'));
}

function BottomRemoveNotification(msg: {count: number}) {
  RemoveNotification(msg, $('#BottomNotifications'));
}

function RemoveNotification(msg: {count: number}, panel: Panel) {
  let count = msg.count;
  if (count > 0 && panel.GetChildCount() > 0) {
    let start = panel.GetChildCount() - count;
    if (start < 0) {
      start = 0;
    }

    for (let i = start; i < panel.GetChildCount(); i++) {
      let lastPanel = panel.GetChild(i);
      // lastPanel.SetAttributeInt("deleted", 1)
      // lastPanel.deleted = true;
      lastPanel.DeleteAsync(0);
    }
  }
}

function AddNotification(msg: NotificationData, panel: Panel) {
  let lastNotification = panel.GetChild(panel.GetChildCount() - 1);
  // $.Msg(msg)
  let continueLast = msg.continue === 1;

  if (typeof (msg.duration) !== 'number') {
    // $.Msg("[Notifications] Notification Duration is not a number!")
    msg.duration = 3;
  }

  let newNotification = !(lastNotification != null && continueLast);

  if (newNotification) {
    lastNotification = $.CreatePanel('Panel', panel, '');
    lastNotification.AddClass('NotificationLine');
    lastNotification.hittest = false;
    lastNotification.DeleteAsync(msg.duration);
  }

  // Type guard functions
  function isHeroImage(msg: NotificationData): msg is HeroImageNotificationData {
    return (<HeroImageNotificationData>msg).hero !== undefined;
  }

  function isImage(msg: NotificationData): msg is ImageNotificationData {
    return (<ImageNotificationData>msg).image !== undefined;
  }

  function isAbilityImage(msg: NotificationData): msg is AbilityImageNotificationData {
    return (<AbilityImageNotificationData>msg).ability !== undefined;
  }

  function isItemImage(msg: NotificationData): msg is ItemImageNotificationData {
    return (<ItemImageNotificationData>msg).item !== undefined;
  }
  // End of type guard functions

  let notification;

  if (isHeroImage(msg)) {
    notification = $.CreatePanel('DOTAHeroImage', lastNotification, '');
    notification.heroimagestyle = msg.imagestyle || 'icon';
    notification.heroname = msg.hero;
    notification.hittest = false;
  } else if (isImage(msg)) {
    notification = $.CreatePanel('Image', lastNotification, '');
    notification.SetImage(msg.image);
    notification.hittest = false;
  } else if (isAbilityImage(msg)) {
    notification = $.CreatePanel('DOTAAbilityImage', lastNotification, '');
    notification.abilityname = msg.ability;
    notification.hittest = false;
  } else if (isItemImage(msg)) {
    notification = $.CreatePanel('DOTAItemImage', lastNotification, '');
    notification.itemname = msg.item;
    notification.hittest = false;
  } else {
    notification = $.CreatePanel('Label', lastNotification, '');
    notification.html = true;
    if (msg.replacement_map) {
      for (const key in msg.replacement_map) {
        let val = msg.replacement_map[key]
        if (typeof val === 'number') {
          notification.SetDialogVariableInt(key, val);
        } else {
          notification.SetDialogVariable(key, val);
        }
      }
    }
    let text = msg.text || 'No Text provided';
    text = $.Localize(text, notification);
    //text = ReplaceSpecialTokens($.Localize(text), msg.replacement_map);
    notification.text = text;
    notification.hittest = false;
    notification.AddClass('TitleText');
  }

  if (msg.class) {
    notification.AddClass(msg.class);
  } else {
    notification.AddClass('NotificationMessage');
  }

  if (msg.style) {
    for (const styleKey in msg.style) {
      let value = msg.style[styleKey];
      notification.style[styleKey] = value;
    }
  }
}

(function () {
  GameEvents.Subscribe('top_notification', TopNotification);
  GameEvents.Subscribe('bottom_notification', BottomNotification);
  GameEvents.Subscribe('top_remove_notification', TopRemoveNotification);
  GameEvents.Subscribe('bottom_remove_notification', BottomRemoveNotification);
})();
