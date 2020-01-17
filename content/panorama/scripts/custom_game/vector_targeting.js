/* global GameEvents, Entities, Abilities, $, Players, Particles, ParticleAttachment_t, Game, CLICK_BEHAVIORS */
// var CONSUME_EVENT = true;
var CONTINUE_PROCESSING_EVENT = false;

// Constants
var defaultVectorWidth = 125;
var defaultVectorRange = 800;
var isQuickCast = false;
var particle_instances = {};
var ability_instances = {};

// Start the vector targeting
function OnVectorTargetingStart (ability, fStartWidth, fEndWidth, fCastLength) {
  // Get caster
  var caster = Abilities.GetCaster(ability);
  
  // Get start (cursor) position of the vector cast
  var cursor = GameUI.GetCursorPosition();
  var worldPosition = GameUI.GetScreenWorldPosition(cursor);

  // Particle variables
  var startWidth = fStartWidth || defaultVectorWidth;
  var endWidth = fEndWidth || startWidth;
  var thisVectorRange = fCastLength || defaultVectorRange;
  var casterLoc = Entities.GetAbsOrigin(caster);

  // Initialize the particle (range finder)
  var vectorTargetParticle = Particles.CreateParticle('particles/ui_mouseactions/range_finder_cone.vpcf', ParticleAttachment_t.PATTACH_CUSTOMORIGIN, caster);
  Particles.SetParticleControl(vectorTargetParticle, 0, casterLoc);
  Particles.SetParticleControl(vectorTargetParticle, 1, VectorRaiseZ(worldPosition, 50));
  Particles.SetParticleControl(vectorTargetParticle, 2, [0, 0, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 3, [endWidth, startWidth, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 4, [0, 255, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 6, [1, 0, 0]);

  // Calculate initial particle CPs
  var direction = VectorSub(worldPosition, casterLoc);
  direction = VectorFlatten(direction);
  direction = VectorNormalize(direction);
  var newPosition = VectorAdd(worldPosition, VectorMult(direction, thisVectorRange));
  Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);
  
  particle_instances[caster] = vectorTargetParticle;
  ability_instances[caster] = ability;

  // Start position updates (loop)
  $.Schedule(0.01, function () {
    ShowVectorTargetingParticle(vectorTargetParticle, ability, worldPosition, thisVectorRange);
  });
}

// Updates the particle effect and detects when the ability is actually casted
function ShowVectorTargetingParticle (particle, ability, startPosition, length) {
  // $.Msg("Show vector particle:");
  if (particle !== undefined) {
    var caster = Abilities.GetCaster(ability);
	var cursor = GameUI.GetCursorPosition();
    var endPosition = GameUI.GetScreenWorldPosition(cursor);
    if (!endPosition) {
      $.Schedule(0.01, function () {
        ShowVectorTargetingParticle(particle, ability, startPosition, length);
      });
      return;
    }
    // Calculate direction and distance
    var newDirection = VectorSub(endPosition, startPosition);
    newDirection = VectorFlatten(newDirection);
    newDirection = VectorNormalize(newDirection);
    var distance = Game.Length2D(endPosition, startPosition);

    if (distance < 0.05) {
      newDirection = VectorSub(startPosition, Entities.GetAbsOrigin(caster));
      newDirection = VectorFlatten(newDirection);
      newDirection = VectorNormalize(newDirection);
    }

    if (distance !== length) {
      endPosition = VectorAdd(startPosition, VectorMult(newDirection, length));
    }

    Particles.SetParticleControl(particle, 2, endPosition);

	var data = {};
	data.unit = caster;
    data.startPosition = startPosition;
    data.endPosition = endPosition;
    var mouseHold = GameUI.IsMouseDown(0);

      if (isQuickCast) {
        if (mouseHold) {
          FinishVectorCast(data);
        } else {
          $.Schedule(0.01, function () {
            ShowVectorTargetingParticle(particle, ability, startPosition, length);
          });
          return;
        }
      } else {
        if (mouseHold) {
          // Holding Click
          $.Schedule(0.01, function () {
            ShowVectorTargetingParticle(particle, ability, startPosition, length);
          });
          return;
        } else {
          FinishVectorCast(data);
        }
      }
  }
}

function StopVectorCast (table) {
  var unit = table.caster;
  var stop = table.stop;
  
  // it has to be 1
  if (stop === 1) {
    RemoveParticle(particle_instances[unit]);
	particle_instances[unit] = undefined;
	ability_instances[unit] = undefined;
  }
}

function FinishVectorCast (table) {
  var unit = table.unit;
  var notInterrupted = ability_instances[unit];

  if (notInterrupted) {
    RemoveParticle(particle_instances[unit]);
	table.ability = notInterrupted;
    SendPosition(table);
  }
}

function RemoveParticle (particle) {
  if (particle) {
    // End the particle effect
    Particles.DestroyParticleEffect(particle, true);
    Particles.ReleaseParticleIndex(particle);
  }
}

// Send the final data to the server
function SendPosition (table) {
  var ability = table.ability;
  var ePos = table.endPosition;
  var cPos = table.startPosition;
  var unit = table.unit;
  var pID = Entities.GetPlayerOwnerID(unit);
  GameEvents.SendCustomGameEventToServer('send_vector_position', {'playerID': pID, 'unit': unit, 'abilityIndex': ability, 'PosX': cPos[0], 'PosY': cPos[1], 'PosZ': cPos[2], 'Pos2X': ePos[0], 'Pos2Y': ePos[1], 'Pos2Z': ePos[2]});

  // $.Schedule(1 / 144, function () {GameUI.SelectUnit(unit, false);} );
}

// Mouse Callback to check whever this ability was quick casted or not
GameUI.SetMouseCallback(function (eventName, arg) {
  var clickBehavior = GameUI.GetClickBehaviors();

  // If its not an ability cast ignore
  if (clickBehavior !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST) {
    if (clickBehavior === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE) {
      // Maybe Quick Cast	
      //isQuickCast = true;
	} else {
      //isQuickCast = false
	};
  };

  // If it has arguments ignore
  if (arg !== 0) return CONTINUE_PROCESSING_EVENT;

  return CONTINUE_PROCESSING_EVENT;
});

// Start to cast the vector ability
function StartVectorCast (table) {
  if (GameUI.IsMouseDown(0) || isQuickCast) {
    // $.Msg('Start Vector Cast');
	OnVectorTargetingStart(table.ability, table.startWidth, table.endWidth, table.castLength);
  }
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

// function VectorNegate (vec) {
  // return [-vec[0], -vec[1], -vec[2]];
// }

function VectorFlatten (vec) {
  return [vec[0], vec[1], 0];
}

function VectorRaiseZ (vec, inc) {
  return [vec[0], vec[1], vec[2] + inc];
}

// Register function to cast vector targeting abilities
(function () {
  GameEvents.Subscribe('vector_target_cast_start', StartVectorCast);
  GameEvents.Subscribe('vector_target_cast_stop', StopVectorCast);
})();

// StartTrack();
