
if Doors == nil then
  Debug.EnabledModules['doors:doors'] = true
  DebugPrint('Creating new Doors object.')
  Doors = class({})
end

-- Constants
DOOR_STATE_UNKOWN = 0
DOOR_STATE_OPENING = 1
DOOR_STATE_OPEN = 2
DOOR_STATE_CLOSING = 3
DOOR_STATE_CLOSED = 4

function Doors:Init()
end

function Doors:CreateDoors(position, angle, settings)
  local gate = self:CreateEmptyGate(settings)

  gate.props = self:SpawnDoors(position, angle, settings)

  gate.Open = partial(Doors['OpenDoors'], gate, settings)
  gate.Close = partial(Doors['CloseDoors'], gate, settings)

  self:PlaceObstructors(gate, settings)

  return gate
end

function Doors:UseDoors(name, settings)
  local gate = self:CreateEmptyGate(settings)

  gate.props.gate = Entities:FindByName(nil, name)

  if gate.props.gate == nil then
    return nil
  end

  gate.Open = partial(Doors['OpenDoors'], gate, settings)
  gate.Close = partial(Doors['CloseDoors'], gate, settings)

  self:PlaceObstructors(gate, settings)

  return gate
end

--[[
settings = {
  animation = 'gate_entrance002_open',
  idle = 'gate_entrance002_idle',
  openingRate = 1,
  closingRate = 2,
}
]]
--[[function Doors.OpenAnimDoors(gate, settings)
  local animation = settings.animation or 'gate_entrance002_open'
  local idle = settings.idle or 'gate_entrance002_idle'
  local rate = settings.openingRate or 1

end

function Doors.CloseAnimDoors(gate, settings)
  local animation = settings.animation or 'gate_entrance002_open'
  local idle = settings.idle or 'gate_entrance002_idle'
  local rate = settings.closingRate or 2

end]]

--[[
settings = {
  distance = 300,
  openingStepDelay = 1/100,
  openingStepSize = 1,
  closingStepDelay = 1/100,
  closingStepSize = 1,
}
]]
function Doors.OpenDoors(gate, settings)
  if gate.state ~= DOOR_STATE_CLOSED then
    return gate.state
  end

  gate.state = DOOR_STATE_OPENING

  DebugPrint('Opening Door')

  local distance = settings.distance or 300
  local traveled = 0
  local delay = settings.openingStepDelay or 1/100
  local stepSize = settings.openingStepSize or 1
  local targetOrigin = gate.props.gate:GetAbsOrigin() + Vector(0, 0, -distance)

  gate.props.gate:EmitSound("Ambient.Doors.Open")
  --ScreenShake(targetOrigin, 0.8, 2, delay * stepSize * distance, 1000, 0, false)
  Doors:RemoveObstuctors(gate, settings)

  Timers:CreateTimer(0, function()
    gate.props.gate:SetOrigin(gate.props.gate:GetAbsOrigin() + Vector(0, 0, -stepSize))
    traveled = traveled + stepSize
    if traveled < distance then
      return delay
    end
    gate.props.gate:SetOrigin(targetOrigin)
    gate.props.gate:StopSound("Ambient.Doors.Open")
    gate.state = DOOR_STATE_OPEN
  end)
end

function Doors.CloseDoors(gate, settings)
  if gate.state ~= DOOR_STATE_OPEN then
    return gate.state
  end

  gate.state = DOOR_STATE_CLOSING

  DebugPrint('Closing Door')

  local distance = settings.distance or 300
  local traveled = 0
  local delay = settings.closingStepDelay or 1/100
  local stepSize = settings.closingStepSize or 1
  local targetOrigin = gate.props.gate:GetAbsOrigin() + Vector(0, 0, distance)

  gate.props.gate:EmitSound("Ambient.Doors.Close")
  --ScreenShake(targetOrigin, 0.8, 2, delay * stepSize * distance, 1000, 0, false)
  Doors:AddObstructors(gate, settings)

  Timers:CreateTimer(0, function()
    gate.props.gate:SetOrigin(gate.props.gate:GetAbsOrigin() + Vector(0, 0, stepSize))
    traveled = traveled + stepSize
    if traveled < distance then
      return delay
    end
    gate.props.gate:SetOrigin(targetOrigin)
    gate.props.gate:StopSound("Ambient.Doors.Close")
    gate.state = DOOR_STATE_CLOSED
  end)
end

function Doors:CreateEmptyGate(settings)
  return {
    props = {},
    state = settings.state or DOOR_STATE_UNKOWN,
    obstructors = {},
    Open = nil,
    Close = nil,
  }
end

--[[
settings = {
  jambOffset = 128,
  jambScale = Vector(1, 1, 1),
  gateScale = Vector(2, 1, 1,78)
  jambModel = 'models/props_structures/gate_entrance001.vmdl',
  gateModel = 'models/props_structures/gate_entrance002.vmdl',
  snapToGround = true,
  heightOffset = 0,
}
]]
function Doors:SpawnDoors(position, angle, settings)
  if settings == nil then
    -- prevent accessing nil
    settings = {}
  end

  local CreateProp = partial(SpawnEntityFromTableSynchronous, 'prop_dynamic')

  local jambOffset = settings.jambOffset or 172

  if settings.snapToGround == true or settings.snapToGround == nil then
    position = GetGroundPosition(position, nil)
  end

  if settings.heightOffset then
    position = position + Vector(0, 0, settings.heightOffset)
  end

  -- angle
  local jambLAngle = Vector(0, angle, 0)
  local gateAngle = Vector(0, angle, 0)
  local jambRAngle = Vector(0, angle, 0) + Vector(0, 180, 0)

  -- origin
  local jambLOrigin = position + Vector(jambOffset, 0, 0)
  local gateOrigin = position
  local jambROrigin = position - Vector(jambOffset, 0, 0)

  -- translate jamb origin
  if angle ~= 0 then
    jambLOrigin = RotateAround(jambLOrigin, gateOrigin, jambLAngle.y)
    jambROrigin = RotateAround(jambROrigin, gateOrigin, jambRAngle.y)
  end

  -- scale
  local jambScale = settings.jambScale or Vector(1, 1, 1)
  local gateScale = settings.gateScale or Vector(2, 1, 1.78)

  -- model
  local jambModel = settings.jambModel or 'models/props_structures/gate_entrance001.vmdl'
  local gateModel = settings.gateModel or 'models/props_structures/gate_entrance002.vmdl'

  DebugPrint('Spawning new Doors at ' .. VectorToString(position) .. ' angled at ' .. angle .. ' degrees.')

  -- spawn props
  local jambL = CreateProp({
    origin = jambLOrigin,
    angles = jambLAngle,
    scales = jambScale,
    model = jambModel,
  })
  local gate = CreateProp({
    origin = gateOrigin,
    angles = gateAngle,
    scales = gateScale,
    model = gateModel,
  })
  local jambR = CreateProp({
    origin = jambROrigin,
    angles = jambRAngle,
    scales = jambScale,
    model = jambModel,
  })

  return {
    jambL = jambL,
    gate = gate,
    jambR = jambR
  }
end

function Doors:PlaceObstructors(gate, settings)
  local spawnObstructor = partial(SpawnEntityFromTableSynchronous, "point_simple_obstruction")
  local gateOrigin = gate.props.gate:GetAbsOrigin()
  local direction = gate.props.gate:GetForwardVector()
  local obstructorWidth = 128 * 0.9
  local obstructorCount = (gate.gateWidth or 650) / obstructorWidth + 2
  local offset = (obstructorCount + 1) / 2 * obstructorWidth

  --print(VectorToString(gateOrigin))
  --print(VectorToString(direction))

  for i = 1, obstructorCount do
    if not gate.obstructors[i] then
      local obstructorPos = gateOrigin + direction * (i * obstructorWidth - offset)
      obstructorPos.z = gateOrigin.z
      --print(VectorToString(obstructorPos))
      --DebugDrawBox(obstructorPos, Vector(-64, -64, 0), Vector(64, 64, 0), 255, 0, 0, 255, 999)
      gate.obstructors[i] = spawnObstructor({
        origin = obstructorPos
      })
    end
  end
end

function Doors:AddObstructors(gate, settings)
  for _,obstructor in pairs(gate.obstructors) do
    if obstructor then
      if not obstructor:IsNull() then
        obstructor:SetEnabled(true, true)
      end
      obstructor = nil
    end
  end
end

function Doors:RemoveObstuctors(gate, settings)
  for _,obstructor in pairs(gate.obstructors) do
    if obstructor then
      if not obstructor:IsNull() then
        obstructor:SetEnabled(false, false)
      end
      obstructor = nil
    end
  end
end

-- rotate point a around point p by d degrees
-- stolen from here https://stackoverflow.com/questions/2259476/rotating-a-point-about-another-point-2d#2259502
function RotateAround(a, p, d)
  local s = math.sin(d)
  local c = math.cos(d)

  -- translate point back to origin
  p.x = p.x - a.x
  p.y = p.y - a.y

  -- rotate point
  local x = p.x * c - p.y * s
  local y = p.y * s + p.x * c

  -- translate point back
  p.x = x + a.x
  p.y = y + a.y

  return p
end

function VectorToString(v)
  return v.x .. ', ' .. v.y .. ', ' .. v.z
end
