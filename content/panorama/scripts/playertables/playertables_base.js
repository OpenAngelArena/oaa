/* global $, GameUI, GameEvents, Players */

const PT = {
  listeners: {},
  tableListeners: {},
  nextListener: 0,
  tables: {},
  subs: []
};

$.Msg('[playertables_base.js] Loaded');

const PlayerTables = {};

PlayerTables.GetAllTableValues = function (tableName) {
  const table = PT.tables[tableName];
  if (table) {
    return JSON.parse(JSON.stringify(table));
  }

  return null;
};

PlayerTables.GetTableValue = function (tableName, keyName) {
  const table = PT.tables[tableName];
  if (!table) {
    return null;
  }

  const val = table[keyName];

  if (typeof val === 'object') {
    return JSON.parse(JSON.stringify(val));
  }

  return val;
};

PlayerTables.SubscribeNetTableListener = function (tableName, callback) {
  let listeners = PT.tableListeners[tableName];
  if (!listeners) {
    listeners = {};
    PT.tableListeners[tableName] = listeners;
  }

  const ID = PT.nextListener;
  PT.nextListener++;

  listeners[ID] = callback;
  PT.listeners[ID] = tableName;

  return ID;
};

PlayerTables.UnsubscribeNetTableListener = function (callbackID) {
  const tableName = PT.listeners[callbackID];
  if (tableName) {
    if (PT.tableListeners[tableName]) {
      const listener = PT.tableListeners[tableName][callbackID];
      if (listener) {
        delete PT.tableListeners[tableName][callbackID];
      }
    }

    delete PT.listeners[callbackID];
  }
};

function isEquivalent (a, b) {
  const aProps = Object.getOwnPropertyNames(a);
  const bProps = Object.getOwnPropertyNames(b);

  if (aProps.length !== bProps.length) {
    return false;
  }

  for (let i = 0; i < aProps.length; i++) {
    const propName = aProps[i];

    if (a[propName] !== b[propName]) {
      return false;
    }
  }

  return true;
}

function ProcessTable (newTable, oldTable, changes, dels) {
  for (const k in newTable) {
    const n = newTable[k];
    const old = oldTable[k];

    if (typeof (n) === typeof (old) && typeof (n) === 'object') {
      if (!isEquivalent(n, old)) {
        changes[k] = n;
      }

      delete oldTable[k];
    } else if (n !== old) {
      changes[k] = n;
      delete oldTable[k];
    } else if (n === old) {
      delete oldTable[k];
    }
  }

  for (const k in oldTable) {
    dels[k] = true;
  }
}

function SendPID () {
  const pid = Players.GetLocalPlayer();
  const spec = Players.IsSpectator(pid);
  // $.Msg(pid, ' -- ', spec)
  if (pid === -1 && !spec) {
    $.Schedule(1 / 30, SendPID);
    return;
  }

  GameEvents.SendCustomGameEventToServer('PlayerTables_Connected', {});
}

function TableFullUpdate (msg) {
  // $.Msg('TableFullUpdate -- ', msg)
  // msg.table = UnprocessTable(msg.table)
  const newTable = msg.table;
  const oldTable = PT.tables[msg.name];

  if (!newTable) {
    delete PT.tables[msg.name];
  } else {
    PT.tables[msg.name] = newTable;
  }

  const listeners = PT.tableListeners[msg.name] || {};
  const len = Object.keys(listeners).length;
  let changes = null;
  let dels = null;

  if (len > -1 && newTable) {
    if (!oldTable) {
      changes = newTable;
      dels = {};
    } else {
      changes = {};
      dels = {};
      ProcessTable(newTable, oldTable, changes, dels);
    }
  }

  for (const k in listeners) {
    try {
      listeners[k](msg.name, changes, dels);
    } catch (err) {
      $.Msg("PlayerTables.TableFullUpdate callback error for '", msg.name, ' -- ', newTable, "': ", err.stack);
    }
  }
}

function UpdateTable (msg) {
  // $.Msg('UpdateTable -- ', msg)
  // msg.changes = UnprocessTable(msg.changes)

  const table = PT.tables[msg.name];
  if (!table) {
    $.Msg('PlayerTables.UpdateTable invoked on nonexistent playertable.');
    return;
  }

  const t = {};

  for (const k in msg.changes) {
    const value = msg.changes[k];

    table[k] = value;
    if (typeof value === 'object') {
      t[k] = JSON.parse(JSON.stringify(value));
    } else {
      t[k] = value;
    }
  }

  const listeners = PT.tableListeners[msg.name] || {};
  for (const k in listeners) {
    if (listeners[k]) {
      try {
        listeners[k](msg.name, t, {});
      } catch (err) {
        $.Msg("PlayerTables.UpdateTable callback error for '", msg.name, ' -- ', t, "': ", err.stack);
      }
    }
  }
}

function DeleteTableKeys (msg) {
  // $.Msg('DeleteTableKeys -- ', msg)
  const table = PT.tables[msg.name];
  if (!table) {
    $.Msg('PlayerTables.DeleteTableKey invoked on nonexistent playertable.');
    return;
  }

  for (const k in msg.keys) {
    delete table[k];
  }

  const listeners = PT.tableListeners[msg.name] || {};
  for (const k in listeners) {
    if (listeners[k]) {
      try {
        listeners[k](msg.name, {}, msg.keys);
      } catch (err) {
        $.Msg("PlayerTables.DeleteTableKeys callback error for '", msg.name, ' -- ', msg.keys, "': ", err.stack);
      }
    }
  }
}

(function () {
  GameUI.CustomUIConfig().PlayerTables = PlayerTables;

  SendPID();

  GameEvents.Subscribe('pt_fu', TableFullUpdate);
  GameEvents.Subscribe('pt_uk', UpdateTable);
  GameEvents.Subscribe('pt_kd', DeleteTableKeys);
})();
