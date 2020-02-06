/* global GameEvents, Entities, Abilities, $, Particles, ParticleAttachment_t, Game, CLICK_BEHAVIORS */
var CONSUME_EVENT = true;
var CONTINUE_PROCESSING_EVENT = false;

// Constants
var defaultVectorWidth = 125;
var defaultVectorRange = 800;
var particleInstances = {};
var abilityInstances = {};

// Start the vector targeting
function OnVectorTargetingStart (ability, fStartWidth, fEndWidth, fCastLength) {
  // Get caster
  var caster = Abilities.GetCaster(ability);

  // Get start (cursor) position of the vector cast on the map
  var cursor = GameUI.GetCursorPosition();
  var worldPosition = GameUI.GetScreenWorldPosition(cursor);

  // Particle variables
  var startWidth = fStartWidth || defaultVectorWidth;
  var endWidth = fEndWidth || startWidth;
  var vectorRange = fCastLength || defaultVectorRange;
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
  var newPosition = VectorAdd(worldPosition, VectorMult(direction, vectorRange));
  Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);

  // Store particle instance
  particleInstances[caster] = vectorTargetParticle;

  // Start particle updates (loop)
  $.Schedule(1 / 10000, function () {
    ShowVectorTargetingParticle(vectorTargetParticle, ability, worldPosition, vectorRange);
  });
}

// Updates the particle effect and detects when the ability is actually casted
function ShowVectorTargetingParticle (particle, ability, startPosition, length) {
  if (particle !== undefined) {
    var caster = Abilities.GetCaster(ability);
    var cursor = GameUI.GetCursorPosition();
    var endPosition = GameUI.GetScreenWorldPosition(cursor);
    if (!endPosition) {
      $.Schedule(1 / 10000, function () {
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

    // Vector particle length is fixed
    if (distance !== length) {
      endPosition = VectorAdd(startPosition, VectorMult(newDirection, length));
    }

    Particles.SetParticleControl(particle, 2, endPosition);

    var data = {};
    data.unit = caster;
    data.startPosition = startPosition;
    data.endPosition = endPosition;
    var mouseHold = GameUI.IsMouseDown(0); // 0 is left click button
    if (mouseHold) {
      // Holding Click
      $.Schedule(1 / 10000, function () {
        ShowVectorTargetingParticle(particle, ability, startPosition, length);
      });
      return;
    } else {
      FinishVectorCast(data);
    }
  }
}

function FinishVectorCast (table) {
  var unit = table.unit;
  var notInterrupted = abilityInstances[unit];

  if (notInterrupted) {
    StopVectorCast(unit);
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

// Send the final data to the server; It doesnt send data during quickcast
function SendPosition (table) {
  var ability = table.ability;
  var ePos = table.endPosition;
  var cPos = table.startPosition;
  var unit = table.unit;
  var pID = Entities.GetPlayerOwnerID(unit);
  GameEvents.SendCustomGameEventToServer('send_vector_position', {'playerID': pID, 'unit': unit, 'abilityIndex': ability, 'PosX': cPos[0], 'PosY': cPos[1], 'PosZ': cPos[2], 'Pos2X': ePos[0], 'Pos2Y': ePos[1], 'Pos2Z': ePos[2]});
}

// Mouse Callback to detect custom vector targeting on the client; quickcast doesnt use mouse clicks;
GameUI.SetMouseCallback(function (eventName, arg) {
  var clickBehavior = GameUI.GetClickBehaviors();

  // Check click behavior
  if (clickBehavior === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST) {
    var ability = Abilities.GetLocalPlayerActiveAbility();
    var unit = Abilities.GetCaster(ability);
    var isVectorTargetingAbility = Abilities.GetSpecialValueFor(ability, 'vector_targeting');

  // If there is no vector targeting instance on this unit then ...
    if (abilityInstances[unit] === undefined) {
      // If mouse click is not left click then return false
      if (arg !== 0) return CONTINUE_PROCESSING_EVENT;
      // If ability is not vector targeting then return false
      if (isVectorTargetingAbility !== 1) return CONTINUE_PROCESSING_EVENT;

      if (eventName === 'pressed') {
        // $.Msg('[Vector Targeting] Player started a vector targeting instance.')
        abilityInstances[unit] = ability;
        StartVectorCast(ability);
        return CONSUME_EVENT;
      }
    } else { // there is a vector targeting instance on this unit
      // If ability is not vector targeted or player pressed some other mouse click (not left click) then
      if (isVectorTargetingAbility !== 1 || (arg !== 0 && eventName === 'pressed')) {
        // $.Msg('[Vector Targeting] Player canceled current vector targeting instance.')
        StopVectorCast(unit);
        return CONTINUE_PROCESSING_EVENT;
      }
      if (eventName === 'released' && abilityInstances[unit] === ability) {
        // $.Msg('[Vector Targeting] Player released button click during a vector targeting instance')
        // Fake cast so the client shows errors when spell is on cooldown, when not enough mana etc.
        Abilities.ExecuteAbility(ability, unit, true);
      }
    }
  }

  return CONTINUE_PROCESSING_EVENT;
});

// Start vector targeting ability
function StartVectorCast (ability) {
  if (GameUI.IsMouseDown(0)) {
    var startWidth = Abilities.GetSpecialValueFor(ability, 'vector_start_width');
    var endWidth = Abilities.GetSpecialValueFor(ability, 'vector_end_width');
    var castLength = Abilities.GetSpecialValueFor(ability, 'vector_length');
    OnVectorTargetingStart(ability, startWidth, endWidth, castLength);
  }
}

// Cancel/Interrupt vector targeting ability on the unit; Only 1 instance allowed per unit
function StopVectorCast (unit) {
  RemoveParticle(particleInstances[unit]);
  particleInstances[unit] = undefined;
  abilityInstances[unit] = undefined;
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
  // GameEvents.Subscribe('vector_target_cast_start', StartVectorCast);
  // GameEvents.Subscribe('vector_target_cast_stop', StopVectorCast);
})();
