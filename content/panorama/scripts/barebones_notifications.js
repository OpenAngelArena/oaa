/* global $, GameEvents */
'use strict';
function TopNotification(msg) {
    AddNotification(msg, $('#TopNotifications'));
}
function BottomNotification(msg) {
    AddNotification(msg, $('#BottomNotifications'));
}
function TopRemoveNotification(msg) {
    RemoveNotification(msg, $('#TopNotifications'));
}
function BottomRemoveNotification(msg) {
    RemoveNotification(msg, $('#BottomNotifications'));
}
function RemoveNotification(msg, panel) {
    var count = msg.count;
    if (count > 0 && panel.GetChildCount() > 0) {
        var start = panel.GetChildCount() - count;
        if (start < 0) {
            start = 0;
        }
        for (var i = start; i < panel.GetChildCount(); i++) {
            var lastPanel = panel.GetChild(i);
            // lastPanel.SetAttributeInt("deleted", 1)
            // lastPanel.deleted = true;
            lastPanel.DeleteAsync(0);
        }
    }
}
function AddNotification(msg, panel) {
    var lastNotification = panel.GetChild(panel.GetChildCount() - 1);
    // $.Msg(msg)
    var continueLast = msg["continue"] === 1;
    if (typeof (msg.duration) !== 'number') {
        // $.Msg("[Notifications] Notification Duration is not a number!")
        msg.duration = 3;
    }
    var newNotification = !(lastNotification != null && continueLast);
    if (newNotification) {
        lastNotification = $.CreatePanel('Panel', panel, '');
        lastNotification.AddClass('NotificationLine');
        lastNotification.hittest = false;
        lastNotification.DeleteAsync(msg.duration);
    }
    // Type guard functions
    function isHeroImage(msg) {
        return msg.hero !== undefined;
    }
    function isImage(msg) {
        return msg.image !== undefined;
    }
    function isAbilityImage(msg) {
        return msg.ability !== undefined;
    }
    function isItemImage(msg) {
        return msg.item !== undefined;
    }
    // End of type guard functions
    var notification;
    if (isHeroImage(msg)) {
        notification = $.CreatePanel('DOTAHeroImage', lastNotification, '');
        notification.heroimagestyle = msg.imagestyle || 'icon';
        notification.heroname = msg.hero;
        notification.hittest = false;
    }
    else if (isImage(msg)) {
        notification = $.CreatePanel('Image', lastNotification, '');
        notification.SetImage(msg.image);
        notification.hittest = false;
    }
    else if (isAbilityImage(msg)) {
        notification = $.CreatePanel('DOTAAbilityImage', lastNotification, '');
        notification.abilityname = msg.ability;
        notification.hittest = false;
    }
    else if (isItemImage(msg)) {
        notification = $.CreatePanel('DOTAItemImage', lastNotification, '');
        notification.itemname = msg.item;
        notification.hittest = false;
    }
    else {
        notification = $.CreatePanel('Label', lastNotification, '');
        notification.html = true;
        if (msg.replacement_map) {
            for (var key in msg.replacement_map) {
                var val = msg.replacement_map[key];
                if (typeof val === 'number') {
                    notification.SetDialogVariableInt(key, val);
                }
                else {
                    notification.SetDialogVariable(key, val);
                }
            }
        }
        var text = msg.text || 'No Text provided';
        text = $.Localize(text, notification);
        //text = ReplaceSpecialTokens($.Localize(text), msg.replacement_map);
        notification.text = text;
        notification.hittest = false;
        notification.AddClass('TitleText');
    }
    if (msg["class"]) {
        notification.AddClass(msg["class"]);
    }
    else {
        notification.AddClass('NotificationMessage');
    }
    if (msg.style) {
        for (var styleKey in msg.style) {
            var value = msg.style[styleKey];
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
