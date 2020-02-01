--[[
  Custom Vector Targeting library
  Original Vector Targeting created by Nibuja05 (https://github.com/Nibuja05/dota_vector_targeting)
  Modified by DarkoniusXNG

  For now works only if ability has a keyvalue 'vector_targeting' set to 1.
  Following keyvalues can be customized: vector_start_width, vector_end_width, vector_length
  If the ability doesnt have those keyvalues, vector targeting ability will use default values mentioned below.

  Extends CDOTABaseAbility:

  * float GetVectorTargetRange(); returns vector targeting length of this ability (default value: 800)

  * Vector GetVectorPosition(); returns the current/last start point of the vector cast

  * Vector GetVectorDirection(); returns the current/last direction of the vector cast

  * float GetVectorTargetStartRadius(); returns vector targeting start width of this ability (default value: 125)

  * float GetVectorTargetEndRadius(); returns vector targeting end width of this ability (default value: start_radius)
]]

if not VectorTarget then
  VectorTarget = class({})
end

function VectorTarget:Init()
  DebugPrint("Initializing Vector Targeting library...")
  CustomGameEventManager:RegisterListener("send_vector_position", Dynamic_Wrap(VectorTarget, "StartVectorCast"))
  --FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(VectorTarget, "OrderFilter"))
end

function VectorTarget:StartVectorCast(event)
  local unit = EntIndexToHScript(event.unit)
  local position = Vector(event.PosX, event.PosY, event.PosZ)
  local position2 = Vector(event.Pos2X, event.Pos2Y, event.Pos2Z)

  local ability = EntIndexToHScript(event.abilityIndex)
  local direction = (position2 - position):Normalized()

  if position == position2 then
    direction = -(unit:GetAbsOrigin() - position):Normalized()
  end

  direction = Vector(direction.x, direction.y, 0)

  if ability then
    unit:CastAbilityOnPosition(position, ability, event.playerID)
    ability.vectorTargetPosition = position
    ability.vectorTargetDirection = direction
  end
end

-- Orders that can cancel vector targeting
--[[
CANCEL_EVENT = {
  [DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
  [DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
  [DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
  [DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
  [DOTA_UNIT_ORDER_CAST_TARGET] = true,
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
  [DOTA_UNIT_ORDER_CAST_RUNE] = true,
}
]]

function VectorTarget:OrderFilter(event)
  local order = event.order_type
  local units = event.units
  local playerID = event.issuer_player_id_const
  local player = PlayerResource:GetPlayer(playerID)
  local unit
  if units["0"] then
    unit = EntIndexToHScript(units["0"])
  end
  --[[
  if unit and player then

  end
  ]]
  return true
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
