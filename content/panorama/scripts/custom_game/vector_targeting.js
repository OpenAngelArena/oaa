/* global GameEvents, Entities, $, Players, Particles, ParticleAttachment_t */
// var CONSUME_EVENT = true;
var CONTINUE_PROCESSING_EVENT = false;

// main variables
var activeAbility;
var vectorTargetParticle;
var vectorStartPosition;
var vectorRange = 800;
var clickStart = false;
var resetSchedule;
var isQuickCast = false;

// Start the vector targeting
function OnVectorTargetingStart (fStartWidth, fEndWidth, fCastLength) {
  // var iPlayerID = Players.GetLocalPlayer();
  // var selectedEntities = Players.GetSelectedEntities(iPlayerID);
  var mainSelected = Players.GetLocalPlayerPortraitUnit();
  // var mainSelectedName = Entities.GetUnitName(mainSelected);
  var cursor = GameUI.GetCursorPosition();
  var worldPosition = GameUI.GetScreenWorldPosition(cursor);
  // particle variables
  var startWidth = fStartWidth || 125;
  var endWidth = fEndWidth || startWidth;
  vectorRange = fCastLength || 800;
  // Initialize the particle
  var casterLoc = Entities.GetAbsOrigin(mainSelected);
  var testPos = [casterLoc[0] + Math.min(1500, vectorRange), casterLoc[1], casterLoc[2]];
  vectorTargetParticle = Particles.CreateParticle('particles/ui_mouseactions/range_finder_cone.vpcf', ParticleAttachment_t.PATTACH_CUSTOMORIGIN, mainSelected);
  Particles.SetParticleControl(vectorTargetParticle, 1, VectorRaiseZ(worldPosition, 100));
  Particles.SetParticleControl(vectorTargetParticle, 2, VectorRaiseZ(testPos, 100));
  Particles.SetParticleControl(vectorTargetParticle, 3, [endWidth, startWidth, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 4, [0, 255, 0]);

  // Calculate initial particle CPs
  vectorStartPosition = worldPosition;
  var unitPosition = Entities.GetAbsOrigin(mainSelected);
  var direction = VectorNormalize(VectorSub(vectorStartPosition, unitPosition));
  var newPosition = VectorAdd(vectorStartPosition, VectorMult(direction, vectorRange));
  Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);

  // Start position updates
  ShowVectorTargetingParticle();

  return CONTINUE_PROCESSING_EVENT;
}

// End the particle effect
function OnVectorTargetingEnd (bSend) {
  if (vectorTargetParticle) {
    Particles.DestroyParticleEffect(vectorTargetParticle, true);
    vectorTargetParticle = undefined;
  }

  if (bSend) {
    SendPosition();
  }
}

// Send the final data to the server
function SendPosition () {
  var cursor = GameUI.GetCursorPosition();
  var ePos = GameUI.GetScreenWorldPosition(cursor);
  var cPos = vectorStartPosition;
  var pID = Players.GetLocalPlayer();
  var unit = Players.GetLocalPlayerPortraitUnit();
  GameEvents.SendCustomGameEventToServer('send_vector_position', {'playerID': pID, 'unit': unit, 'abilityIndex': activeAbility, 'PosX': cPos[0], 'PosY': cPos[1], 'PosZ': cPos[2], 'Pos2X': ePos[0], 'Pos2Y': ePos[1], 'Pos2Z': ePos[2]});
}

// Updates the particle effect and detects when the ability is actually casted
function ShowVectorTargetingParticle () {
  if (vectorTargetParticle !== undefined) {
    // var mainSelected = Players.GetLocalPlayerPortraitUnit();
    var cursor = GameUI.GetCursorPosition();
    var worldPosition = GameUI.GetScreenWorldPosition(cursor);

    if (worldPosition == null) {
      $.Schedule(1 / 144, ShowVectorTargetingParticle);
      return;
    }
    var val = VectorSub(worldPosition, vectorStartPosition);
    if (!(val[0] === 0 && val[1] === 0 && val[2] === 0)) {
      var direction = VectorNormalize(VectorSub(vectorStartPosition, worldPosition));
      direction = VectorFlatten(VectorNegate(direction));
      var newPosition = VectorAdd(vectorStartPosition, VectorMult(direction, vectorRange));

      Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);
    }
    var mouseHold = GameUI.IsMouseDown(0);
    if (isQuickCast) {
      if (mouseHold) {
        CastStop({cast: 1});
      } else {
        $.Schedule(1 / 144, ShowVectorTargetingParticle);
      }
    } else {
      if (mouseHold) {
        $.Schedule(1 / 144, ShowVectorTargetingParticle);
      } else {
        CastStop({cast: 1});
      }
    }
  }
}

// Mouse Callback to check whever this ability was quick casted or not
GameUI.SetMouseCallback(function (eventName, arg) {
  clickStart = true;
  if (resetSchedule) {
    $.CancelScheduled(resetSchedule, {});
  }
  resetSchedule = $.Schedule(1 / 20, function () {
    resetSchedule = undefined;
    clickStart = false;
  });

  return CONTINUE_PROCESSING_EVENT;
});

// Start to cast the vector ability
function CastStart (table) {
  activeAbility = table.ability;
  isQuickCast = !clickStart;
  if (GameUI.IsMouseDown(0) || isQuickCast) {
    OnVectorTargetingStart(table.startWidth, table.endWidth, table.castLength);
  }
}

// Stop to cast the vector ability
function CastStop (table) {
  OnVectorTargetingEnd(table.cast === 1);
}

// Some Vector Functions here:
function VectorNormalize (vec) {
  var val = 1 / Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2) + Math.pow(vec[2], 2));
  return [vec[0] * val, vec[1] * val, vec[2] * val];
}

function VectorMult (vec, mult) {
  return [vec[0] * mult, vec[1] * mult, vec[2] * mult];
}

function VectorAdd (vec1, vec2) {
  return [vec1[0] + vec2[0], vec1[1] + vec2[1], vec1[2] + vec2[2]];
}

function VectorSub (vec1, vec2) {
  return [vec1[0] - vec2[0], vec1[1] - vec2[1], vec1[2] - vec2[2]];
}

function VectorNegate (vec) {
  return [-vec[0], -vec[1], -vec[2]];
}

function VectorFlatten (vec) {
  return [vec[0], vec[1], 0];
}

function VectorRaiseZ (vec, inc) {
  return [vec[0], vec[1], vec[2] + inc];
}

// Register function to cast vector targeting abilities
(function () {
  GameEvents.Subscribe('vector_target_cast_start', CastStart);
  GameEvents.Subscribe('vector_target_cast_stop', CastStop);
})();

// StartTrack();
