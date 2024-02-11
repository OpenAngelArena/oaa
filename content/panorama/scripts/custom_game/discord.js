/* global $, CustomNetTables */
'use strict';

function onPlayerStatChange (table, key, data) {
  if (key === 'time' && data != null && data.time === -1) {
    $.GetContextPanel().SetHasClass('InGame', true);
  }
}

(function () {
  CustomNetTables.SubscribeNetTableListener('hero_selection', onPlayerStatChange);
})();
