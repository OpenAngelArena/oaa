if not VectorTarget then 
	VectorTarget = class({})
end

ListenToGameEvent("game_rules_state_change", function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		print("[VT] Initializing VectorTarget...")
		CustomGameEventManager:RegisterListener("send_vector_position", Dynamic_Wrap(VectorTarget, "StartVectorCast"))
		local mode = GameRules:GetGameModeEntity()
		mode:SetExecuteOrderFilter(Dynamic_Wrap(VectorTarget, 'OrderFilter'), VectorTarget)
	end
end, nil)

function VectorTarget:StartVectorCast( event )
	local caster = PlayerResource:GetSelectedHeroEntity(event.playerID)
	local unit = EntIndexToHScript(event.unit)
	local position = Vector(event.PosX, event.PosY, event.PosZ)
	local position2 = Vector(event.Pos2X, event.Pos2Y, event.Pos2Z)
	local abilityName = event.abilityName

	local ability = EntIndexToHScript(event.abilityIndex)
	local direction = -(position - position2):Normalized()

	if position == position2 then
		direction = -(unit:GetAbsOrigin() - position):Normalized()
	end

	direction = Vector(direction.x, direction.y, 0)

	if ability then
		unit.inVectorCast = nil
		unit:CastAbilityOnPosition(position, ability, event.playerID)
		local function OverrideSpellStart(self, position, direction)
			self:OnVectorCastStart(position, direction)
		end
		ability.vectorTargetPosition = position
		ability.vectorTargetDirection = direction
		ability.OnSpellStart = function(self) return OverrideSpellStart(self, position, direction) end
	end
end

CANCEL_EVENT = {[DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
				[DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
				[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
				[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
				[DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
				[DOTA_UNIT_ORDER_CAST_TARGET_TREE] = true,
				[DOTA_UNIT_ORDER_CAST_NO_TARGET] = true,
				[DOTA_UNIT_ORDER_HOLD_POSITION] = true,
				[DOTA_UNIT_ORDER_DROP_ITEM] = true,
				[DOTA_UNIT_ORDER_GIVE_ITEM] = true,
				[DOTA_UNIT_ORDER_PICKUP_ITEM] = true,
				[DOTA_UNIT_ORDER_PICKUP_RUNE] = true,
				[DOTA_UNIT_ORDER_STOP] = true,
				[DOTA_UNIT_ORDER_MOVE_TO_DIRECTION] = true,
				[DOTA_UNIT_ORDER_PATROL] = true,
				}

function VectorTarget:OrderFilter(event)
	if not event.units["0"] then return true end
	local unit = EntIndexToHScript(event.units["0"])
	if event.entindex_ability > 0 then
		local ability = EntIndexToHScript(event.entindex_ability)
		if not ability then return true end
		local playerID = unit:GetPlayerID()
		local player = PlayerResource:GetPlayer(playerID)
		-- check if valid vector cast

		if unit.inVectorCast == nil and ability:IsVectorTargeting() and event.order_type == DOTA_UNIT_ORDER_CAST_POSITION then
			CustomGameEventManager:Send_ServerToPlayer(player, "vector_target_cast_start", {ability = event.entindex_ability, 
																							startWidth = ability:GetVectorTargetStartRadius(), 
																							endWidth = ability:GetVectorTargetEndRadius(), 
																							castLength = ability:GetVectorTargetRange(), })
			unit.inVectorCast = event.entindex_ability
			return false
		else -- fire the spell or cancel the order depending on what ability is being cast
			CustomGameEventManager:Send_ServerToPlayer(player, "vector_target_cast_stop", {cast = unit.inVectorCast == event.entindex_ability})
			unit.inVectorCast = nil
			-- filter out 'regular' cast attempt
			return unit.inVectorCast ~= event.entindex_ability
		end
	elseif unit.inVectorCast and CANCEL_EVENT[event.order_type] then
		local playerID = unit:GetPlayerID()
		local player = PlayerResource:GetPlayer(playerID)
		CustomGameEventManager:Send_ServerToPlayer(player, "vector_target_cast_stop", {cast = false})
		unit.inVectorCast = nil
	end
	return true
end

function CDOTABaseAbility:IsVectorTargeting()
	return false
end

function CDOTABaseAbility:GetVectorTargetRange()
	return 800
end 

function CDOTABaseAbility:GetVectorTargetStartRadius()
	return 125
end 

function CDOTABaseAbility:GetVectorTargetEndRadius()
	return self:GetVectorTargetStartRadius()
end 

function CDOTABaseAbility:GetVectorPosition()
	return self.vectorTargetPosition
end 

function CDOTABaseAbility:GetVectorDirection()
	return self.vectorTargetDirection
end 

function CDOTABaseAbility:OnVectorCastStart(vStartLocation, vDirection)
	print("Vector Cast")
end
