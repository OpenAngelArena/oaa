var CONSUME_EVENT = true;
var CONTINUE_PROCESSING_EVENT = false;

//main variables
var active_ability = undefined;
var vector_target_particle = undefined;
var vector_start_position = undefined;
var vector_range = 800;
var click_start = false;
var resetSchedule;
var is_quick = false;


// Start the vector targeting
function OnVectorTargetingStart(fStartWidth, fEndWidth, fCastLength)
{
	var iPlayerID = Players.GetLocalPlayer();
	var selectedEntities = Players.GetSelectedEntities( iPlayerID );
	var mainSelected = Players.GetLocalPlayerPortraitUnit();
	var mainSelectedName = Entities.GetUnitName(mainSelected);
	var cursor = GameUI.GetCursorPosition();
	var worldPosition = GameUI.GetScreenWorldPosition(cursor);
	// particle variables
	var startWidth = fStartWidth || 125
	var endWidth = fEndWidth || startWidth
	vector_range = fCastLength || 800
	//Initialize the particle
	var casterLoc = Entities.GetAbsOrigin(mainSelected);
	var testPos = [casterLoc[0] + Math.min( 1500, vector_range), casterLoc[1], casterLoc[2]];
	vector_target_particle = Particles.CreateParticle("particles/ui_mouseactions/range_finder_cone.vpcf", ParticleAttachment_t.PATTACH_CUSTOMORIGIN, mainSelected);
	Particles.SetParticleControl(vector_target_particle, 1, Vector_raiseZ(worldPosition, 100));
	Particles.SetParticleControl(vector_target_particle, 2, Vector_raiseZ(testPos, 100));
	Particles.SetParticleControl(vector_target_particle, 3, [endWidth, startWidth, 0]);
	Particles.SetParticleControl(vector_target_particle, 4, [0, 255, 0]);

	//Calculate initial particle CPs
	vector_start_position = worldPosition;
	var unitPosition = Entities.GetAbsOrigin(mainSelected);
	var direction = Vector_normalize(Vector_sub(vector_start_position, unitPosition));
	var newPosition = Vector_add(vector_start_position, Vector_mult(direction, vector_range));
	Particles.SetParticleControl(vector_target_particle, 2, newPosition);

	//Start position updates
	ShowVectorTargetingParticle();

	return CONTINUE_PROCESSING_EVENT;
}

//End the particle effect
function OnVectorTargetingEnd(bSend)
{
	if (vector_target_particle) {
		Particles.DestroyParticleEffect(vector_target_particle, true)
		vector_target_particle = undefined;
	}

	if( bSend ){
		SendPosition();
	}
}

//Send the final data to the server
function SendPosition() {
	var cursor = GameUI.GetCursorPosition();
	var ePos = GameUI.GetScreenWorldPosition(cursor);
	var cPos = vector_start_position;
	var pID = Players.GetLocalPlayer();
	var unit = Players.GetLocalPlayerPortraitUnit()
	GameEvents.SendCustomGameEventToServer("send_vector_position", {"playerID" : pID, "unit" : unit, "abilityIndex":active_ability, "PosX" : cPos[0], "PosY" : cPos[1], "PosZ" : cPos[2], "Pos2X" : ePos[0], "Pos2Y" : ePos[1], "Pos2Z" : ePos[2]});
}

//Updates the particle effect and detects when the ability is actually casted
function ShowVectorTargetingParticle()
{
	if (vector_target_particle !== undefined)
	{
		var mainSelected = Players.GetLocalPlayerPortraitUnit();
		var cursor = GameUI.GetCursorPosition();
		var worldPosition = GameUI.GetScreenWorldPosition(cursor);

		if (worldPosition == null)
		{
			$.Schedule(1 / 144, ShowVectorTargetingParticle);
			return;
		}
		var val = Vector_sub(worldPosition, vector_start_position);
		if (!(val[0] == 0 && val[1] == 0 && val[2] == 0))
		{
			var direction = Vector_normalize(Vector_sub(vector_start_position, worldPosition));
			direction = Vector_flatten(Vector_negate(direction));
			var newPosition = Vector_add(vector_start_position, Vector_mult(direction, vector_range));

			Particles.SetParticleControl(vector_target_particle, 2, newPosition);
		}
		var mouseHold = GameUI.IsMouseDown(0);
		if (is_quick) 
		{
			if (mouseHold) 
			{
				CastStop( {cast:1} );
			} else {
				$.Schedule(1 / 144, ShowVectorTargetingParticle);
			}
		} else {
			if (mouseHold)
			{
				$.Schedule(1 / 144, ShowVectorTargetingParticle);
			} else {
				CastStop( {cast:1} );
			}
		}
	}
}

//Mouse Callback to check whever this ability was quick casted or not
GameUI.SetMouseCallback(function(eventName, arg)
{
	click_start = true;
	if (resetSchedule) {
		$.CancelScheduled(resetSchedule, {});
	}
	resetSchedule = $.Schedule(1 / 20, function() {
		resetSchedule = undefined;
		click_start = false;
	});

	return CONTINUE_PROCESSING_EVENT;
});

//Start to cast the vector ability
function CastStart(table) {
	active_ability = table.ability
	is_quick = !click_start
	if (GameUI.IsMouseDown(0) || is_quick) {
		OnVectorTargetingStart(table.startWidth, table.endWidth, table.castLength);
	}
}

//Stop to cast the vector ability
function CastStop(table) {
	OnVectorTargetingEnd( table.cast == 1 );
}

//Some Vector Functions here:
function Vector_normalize(vec)
{
	var val = 1 / Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2) + Math.pow(vec[2], 2));
	return [vec[0] * val, vec[1] * val, vec[2] * val];
}

function Vector_mult(vec, mult)
{
	return [vec[0] * mult, vec[1] * mult, vec[2] * mult];
}

function Vector_add(vec1, vec2)
{
	return [vec1[0] + vec2[0], vec1[1] + vec2[1], vec1[2] + vec2[2]];
}

function Vector_sub(vec1, vec2)
{
	return [vec1[0] - vec2[0], vec1[1] - vec2[1], vec1[2] - vec2[2]];
}

function Vector_negate(vec)
{
	return [-vec[0], -vec[1], -vec[2]];
}

function Vector_flatten(vec)
{
	return [vec[0], vec[1], 0];
}

function Vector_raiseZ(vec, inc)
{
	return [vec[0], vec[1], vec[2] + inc];
}

//Register function to cast vector targeting abilities
(function () {
  GameEvents.Subscribe("vector_target_cast_start", CastStart );
  GameEvents.Subscribe("vector_target_cast_stop", CastStop );
})();

//StartTrack();
