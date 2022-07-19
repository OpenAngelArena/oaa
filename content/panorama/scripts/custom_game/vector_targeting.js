/* global GameEvents, GameUI, Entities, Abilities, $, Particles, ParticleAttachment_t, Game, CLICK_BEHAVIORS */
const CONSUME_EVENT = true;
const CONTINUE_PROCESSING_EVENT = false;

// Constants
const defaultVectorWidth = 125;
const defaultVectorRange = 800;
const particleInstances = {};
const abilityInstances = {};

// Start the vector targeting
function OnVectorTargetingStart (ability, fStartWidth, fEndWidth, fCastLength) {
  // Get caster
  const caster = Abilities.GetCaster(ability);

  // Get start (cursor) position of the vector cast on the map
  const cursor = GameUI.GetCursorPosition();
  const worldPosition = GameUI.GetScreenWorldPosition(cursor);

  // Particle variables
  const startWidth = fStartWidth || defaultVectorWidth;
  const endWidth = fEndWidth || startWidth;
  const vectorRange = fCastLength || defaultVectorRange;
  const casterLoc = Entities.GetAbsOrigin(caster);

  // Initialize the particle (range finder)
  const vectorTargetParticle = Particles.CreateParticle('particles/ui_mouseactions/range_finder_cone.vpcf', ParticleAttachment_t.PATTACH_CUSTOMORIGIN, caster);
  Particles.SetParticleControl(vectorTargetParticle, 0, casterLoc);
  Particles.SetParticleControl(vectorTargetParticle, 1, VectorRaiseZ(worldPosition, 50));
  Particles.SetParticleControl(vectorTargetParticle, 2, [0, 0, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 3, [endWidth, startWidth, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 4, [0, 255, 0]);
  Particles.SetParticleControl(vectorTargetParticle, 6, [1, 0, 0]);

  // Calculate initial particle CPs
  let direction = VectorSub(worldPosition, casterLoc);
  direction = VectorFlatten(direction);
  direction = VectorNormalize(direction);
  const newPosition = VectorAdd(worldPosition, VectorMult(direction, vectorRange));
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
    const caster = Abilities.GetCaster(ability);
    const cursor = GameUI.GetCursorPosition();
    let endPosition = GameUI.GetScreenWorldPosition(cursor);
    if (!endPosition) {
      $.Schedule(1 / 10000, function () {
        ShowVectorTargetingParticle(particle, ability, startPosition, length);
      });
      return;
    }
    // Calculate direction and distance
    let newDirection = VectorSub(endPosition, startPosition);
    newDirection = VectorFlatten(newDirection);
    newDirection = VectorNormalize(newDirection);
    const distance = Game.Length2D(endPosition, startPosition);

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

    const data = {};
    data.unit = caster;
    data.startPosition = startPosition;
    data.endPosition = endPosition;
    const mouseHold = GameUI.IsMouseDown(0); // 0 is left click button
    if (mouseHold) {
      // Holding Click
      $.Schedule(1 / 10000, function () {
        ShowVectorTargetingParticle(particle, ability, startPosition, length);
      });
    } else {
      FinishVectorCast(data);
    }
  }
}

function FinishVectorCast (table) {
  const unit = table.unit;
  const notInterrupted = abilityInstances[unit];

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
  const ability = table.ability;
  const ePos = table.endPosition;
  const cPos = table.startPosition;
  const unit = table.unit;
  const pID = Entities.GetPlayerOwnerID(unit);
  GameEvents.SendCustomGameEventToServer('send_vector_position', { playerID: pID, unit: unit, abilityIndex: ability, PosX: cPos[0], PosY: cPos[1], PosZ: cPos[2], Pos2X: ePos[0], Pos2Y: ePos[1], Pos2Z: ePos[2] });
}

// Mouse Callback to detect custom vector targeting on the client; quickcast doesnt use mouse clicks;
GameUI.SetMouseCallback(function (eventName, arg) {
  const clickBehavior = GameUI.GetClickBehaviors();

  // Check click behavior
  if (clickBehavior === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST) {
    const ability = Abilities.GetLocalPlayerActiveAbility();
    const unit = Abilities.GetCaster(ability);
    const isVectorTargetingAbility = Abilities.GetSpecialValueFor(ability, 'vector_targeting');

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
    const startWidth = Abilities.GetSpecialValueFor(ability, 'vector_start_width');
    const endWidth = Abilities.GetSpecialValueFor(ability, 'vector_end_width');
    const castLength = Abilities.GetSpecialValueFor(ability, 'vector_length');
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
  const val = 1 / Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2) + Math.pow(vec[2], 2));
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
