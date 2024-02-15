/* global $, GameEvents */
'use strict';

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    Close: Close
  };
}

function Close () {
  $('#AnnouncementPanel').SetHasClass('Show', false);
}

(function () {
  GameEvents.Subscribe('show_announcement', function (keys) {
    $('#AnnouncementPanel').SetHasClass('Show', true);
  });
})();
