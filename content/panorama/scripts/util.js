/* global $, GameUI, Entities, Players, Abilities, Items, CustomNetTables */

'use strict';

/*
  Author:
    Angel Arena Blackstar
  Credits:
    Angel Arena Blackstar
*/

if (typeof module !== 'undefined' && module.exports) {
  module.exports = FindDotaHudElement;
  module.exports = dynamicSort;
  module.exports = GetItemCountInInventory;
  module.exports = GetItemCountInCourier;
  module.exports = FindCourier;
  module.exports = GetPlayerGold;
  module.exports = SafeGetPlayerHeroEntityIndex;
  module.exports = GetPlayerHeroName;
  module.exports = GetHeroName;
  module.exports = DynamicSubscribePTListener;
  module.exports = DynamicSubscribeNTListener;
}

var PlayerTables = GameUI.CustomUIConfig().PlayerTables;
var hud = GetDotaHud();

function FindDotaHudElement (id) {
  return hud.FindChildTraverse(id);
}

function GetDotaHud () {
  var p = $.GetContextPanel();
  try {
    while (true) {
      if (p.id === 'Hud') {
        return p;
      } else {
        p = p.GetParent();
      }
    }
  } catch (e) {}
}

Entities.GetHeroPlayerOwner = function (unit) {
  for (var i = 0; i < 24; i++) {
    var ServersideData = PlayerTables.GetTableValue('player_hero_entities', i);

    if ((ServersideData && Number(ServersideData) === unit) || Players.GetPlayerHeroEntityIndex(i) === unit) {
      return i;
    }
  }
  return -1;
};

function dynamicSort (property) {
  var sortOrder = 1;
  if (property[0] === '-') {
    sortOrder = -1;
    property = property.substr(1);
  }
  return function (a, b) {
    var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
    return result * sortOrder;
  };
}

function GetItemCountInInventory (nEntityIndex, itemName, bStash) {
  var counter = 0;
  var endPoint = 8;
  if (bStash) {
    endPoint = 14;
  }
  for (var i = endPoint; i >= 0; i--) {
    var item = Entities.GetItemInSlot(nEntityIndex, i);
    if (Abilities.GetAbilityName(item) === itemName) {
      counter = counter + 1;
    }
  }
  return counter;
}

function GetItemCountInCourier (nEntityIndex, itemName, bStash) {
  var courier = FindCourier(nEntityIndex);
  if (courier == null) {
    return 0;
  }
  var counter = 0;
  var endPoint = 8;
  if (bStash) {
    endPoint = 14;
  }
  for (var i = endPoint; i >= 0; i--) {
    var item = Entities.GetItemInSlot(courier, i);
    if (Abilities.GetAbilityName(item) === itemName && Items.GetPurchaser(item) === nEntityIndex) {
      counter = counter + 1;
    }
  }
  return counter;
}

function FindCourier (unit) {
  return $.Each(Entities.GetAllEntitiesByClassname('npc_dota_courier'), function (ent) {
    if (Entities.GetTeamNumber(ent) === Entities.GetTeamNumber(unit)) {
      return ent;
    }
  })[0];
}

function GetPlayerGold (PlayerID) {
  var goldTable = PlayerTables.GetTableValue('gold', 'gold');
  return goldTable == null ? 0 : Number(goldTable[PlayerID] || 0);
}

function GetHeroName (unit) {
  var data = GameUI.CustomUIConfig().custom_entity_values[unit || -1];
  return data != null && data.unit_name != null ? data.unit_name : Entities.GetUnitName(unit);
}

function SafeGetPlayerHeroEntityIndex (playerId) {
  var clientEnt = Players.GetPlayerHeroEntityIndex(playerId);
  return clientEnt === -1 ? (Number(PlayerTables.GetTableValue('player_hero_indexes', playerId)) || -1) : clientEnt;
}

function GetPlayerHeroName (playerId) {
  if (Players.IsValidPlayerID(playerId)) {
    return GetHeroName(SafeGetPlayerHeroEntityIndex(playerId));
  }
  return '';
}

function DynamicSubscribePTListener (table, callback, OnConnectedCallback) {
  if (PlayerTables.IsConnected()) {
    // $.Msg('Update ' + table + ' / PT connected');
    var tableData = PlayerTables.GetAllTableValues(table);
    if (tableData != null) {
      callback(table, tableData, {});
    }
    var ptid = PlayerTables.SubscribeNetTableListener(table, callback);
    if (OnConnectedCallback != null) {
      OnConnectedCallback(ptid);
    }
  } else {
    // $.Msg('Update ' + table + ' / PT not connected, repeat')
    $.Schedule(0.1, function () {
      DynamicSubscribePTListener(table, callback, OnConnectedCallback);
    });
  }
}

function DynamicSubscribeNTListener (table, callback, OnConnectedCallback) {
  var tableData = CustomNetTables.GetAllTableValues(table);
  if (tableData != null) {
    $.Each(tableData, function (ent) {
      callback(table, ent.key, ent.value);
    });
  }
  var ptid = CustomNetTables.SubscribeNetTableListener(table, callback);
  if (OnConnectedCallback != null) {
    OnConnectedCallback(ptid);
  }
}

// SNIPPET END
