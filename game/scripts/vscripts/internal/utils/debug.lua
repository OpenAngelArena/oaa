local PhysicsUnitFDesc = {
	StopPhysicsSimulation = true,
	StartPhysicsSimulation = true,
	SetPhysicsVelocity = true,
	AddPhysicsVelocity = true,
	SetPhysicsVelocityMax = true,
	GetPhysicsVelocityMax = true,
	SetPhysicsAcceleration = true,
	AddPhysicsAcceleration = true,
	SetPhysicsFriction = true,
	GetPhysicsVelocity = true,
	GetPhysicsAcceleration = true,
	GetPhysicsFriction = true,
	FollowNavMesh = true,
	IsFollowNavMesh = true,
	SetGroundBehavior = true,
	GetGroundBehavior = true,
	SetSlideMultiplier = true,
	GetSlideMultiplier = true,
	Slide = true,
	IsSlide = true,
	PreventDI = true,
	IsPreventDI = true,
	SetNavCollisionType = true,
	GetNavCollisionType = true,
	OnPhysicsFrame = true,
	SetVelocityClamp = true,
	GetVelocityClamp = true,
	Hibernate = true,
	IsHibernate = true,
	DoHibernate = true,
	OnHibernate = true,
	OnPreBounce = true,
	OnBounce = true,
	OnPreSlide = true,
	OnSlide = true,
	AdaptiveNavGridLookahead = true,
	IsAdaptiveNavGridLookahead = true,
	SetNavGridLookahead = true,
	GetNavGridLookahead = true,
	SkipSlide = true,
	SetRebounceFrames = true,
	GetRebounceFrames = true,
	GetLastGoodPosition = true,
	SetStuckTimeout = true,
	GetStuckTimeout = true,
	SetAutoUnstuck = true,
	GetAutoUnstuck = true,
	SetBounceMultiplier = true,
	GetBounceMultiplier = true,
	GetTotalVelocity = true,
	GetColliders = true,
	RemoveCollider = true,
	AddCollider = true,
	AddColliderFromProfile = true,
	GetMass = true,
	SetMass = true,
	GetNavGroundAngle = true,
	SetNavGroundAngle = true,
	CutTrees = true,
	IsCutTrees = true,
	IsInSimulation = true,
	SetBoundOverride = true,
	GetBoundOverride = true,
	ClearStaticVelocity = true,
	SetStaticVelocity = true,
	GetStaticVelocity = true,
	AddStaticVelocity = true,
	SetPhysicsFlatFriction = true,
	GetPhysicsFlatFriction = true,
	PhysicsLastPosition = true,
	PhysicsLastTime = true,
	PhysicsTimer = true,
	PhysicsTimerName = true,
	bAdaptiveNavGridLookahead = true,
	bAutoUnstuck = true,
	bCutTrees = true,
	bFollowNavMesh = true,
	bHibernate = true,
	bHibernating = true,
	bPreventDI = true,
	bSlide = true,
	bStarted = true,
	fBounceMultiplier = true,
	fFlatFriction = true,
	fFriction = true,
	fMass = true,
	fNavGroundAngle = true,
	fSlideMultiplier = true,
	fVelocityClamp = true,
	lastGoodGround = true,
	nLockToGround = true,
	nMaxRebounce = true,
	nNavCollision = true,
	nNavGridLookahead = true,
	nRebounceFrames = true,
	nSkipSlide = true,
	nStuckFrames = true,
	nStuckTimeout = true,
	nVelocityMax = true,
	oColliders = true,
	staticForces = true,
	staticSum = true,
	vAcceleration = true,
	vLastGoodPosition = true,
	vLastVelocity = true,
	vSlideVelocity = true,
	vTotalVelocity = true,
	vVelocity = true,
}

Debug = Debug or {
  EnabledModules = {
    ['internal:*'] = true,
    ['gamemode:*'] = true
  },
  EnableAll = false
}

function DebugAllCalls()
	if not GameRules.DebugCalls then
		print("Starting DebugCalls")
		GameRules.DebugCalls = true

		debug.sethook(function(...)
			local info = debug.getinfo(2)
			local src = tostring(info.short_src)
			local name = tostring(info.name)
			if name ~= "__index" then
				print("Call: ".. src .. " -- " .. name .. " -- " .. info.currentline)
			end
		end, "c")
	else
		print("Stopped DebugCalls")
		GameRules.DebugCalls = false
		debug.sethook(nil, "c")
	end
end

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function Debug.regexsplit(s, delimiter)
    result = {};
    for match in s:gmatch("([^"..delimiter.."]+)") do
        table.insert(result, match);
    end
    return result;
end

function TracesFromFilename (filename)
  local traces = {}
  local i = 1

  local parts = Debug.regexsplit(filename, '%s/\\')
  local partialTrade = nil
  for i, part in ipairs(parts) do
    if partialTrade == nil and part ~= "components" then
      partialTrade = part
      table.insert(traces, partialTrade .. ":*")
    elseif partialTrade ~= nil then
      partialTrade = partialTrade .. ":" .. part
      table.insert(traces, partialTrade .. ":*")
    end
  end

  table.insert(traces, partialTrade)

  return traces
end

function IsAnyTraceEnabled (traces)
  if Debug.EnableAll then
    return true
  end

  for i, trace in ipairs(traces) do
    if Debug.EnabledModules[trace] then
      return true
    end
  end

  return false
end

-- written by yeahbuddy, taken from https://github.com/OpenAngelArena/oaa/pull/80
-- modified for clarity
function GetCallingFile (offset)
  offset = offset or 4

  local functionInfo = debug.getinfo(offset - 1, "Sl")
  local filePath = string.match(functionInfo.source, "scripts[/\\]vscripts[/\\](.+).lua")
  if functionInfo.currentline then
    return TracesFromFilename(filePath), filePath .. ":" .. functionInfo.currentline
  else
    return TracesFromFilename(filePath), filePath
  end
end

function DebugPrint(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  local output = {...}

  local prefix, msg = string.match(output[1], "%[([^%]]*)%]%s*(.*)")

  if prefix ~= nil then
    output[1] = msg
  end

  if spew == 1 then
    print("[" .. dir .. "]", unpack(output))
  end
end

function DebugPrintTable(...)
  local spew = Convars:GetInt('barebones_spew') or -1
  if spew == -1 and BAREBONES_DEBUG_SPEW then
    spew = 1
  end

  local trace, dir = GetCallingFile()

  if IsAnyTraceEnabled(trace) then
    spew = 1
  end

  if spew == 1 then
    PrintTable("[" .. dir .. "]", ...)
  end
end

function PrintTable(prefix, t, indent, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(prefix) == "table" then
    -- shift
    done = indent
    indent = t
    t = prefix

    local trace = nil
    -- set prefix
    trace, prefix = GetCallingFile()

    prefix = "[" .. prefix .. "] "
  end
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 1

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..":")
        PrintTable (prefix, value, indent + 2, done)
      elseif type(value) == "userdata" and not done[value] then
        done [value] = true
        print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        PrintTable (prefix, (getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
      else
        if t.FDesc and t.FDesc[v] then
          print(prefix .. string.rep ("\t", indent)..tostring(t.FDesc[v]))
        else
          print(prefix .. string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
        end
      end
    end
  end
end
