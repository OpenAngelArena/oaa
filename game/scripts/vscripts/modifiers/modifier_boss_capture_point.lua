modifier_boss_capture_point = class(ModifierBaseClass)

local particleDirectory = "particles/capture_point_ring/"

function modifier_boss_capture_point:IsPurgable()
  return false
end

function modifier_boss_capture_point:IsHidden()
  return true
end

-- Looks up the name on self and cleans up the particle and index
function modifier_boss_capture_point:DestroyParticleByName(particleName)
  local particleIndex = self[particleName]
  if particleIndex then
    ParticleManager:DestroyParticle(particleIndex, false)
    ParticleManager:ReleaseParticleIndex(particleIndex)
    self[particleName] = nil
  end
end

function modifier_boss_capture_point:StartInProgressParticle()
  if not self.captureInProgressEffect then
    self.captureInProgressEffect = ParticleManager:CreateParticle(particleDirectory .. "capture_point_ring_capturing.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.captureInProgressEffect, 9, Vector(self.radius, 0, 0))
  end
  ParticleManager:SetParticleControl(self.captureInProgressEffect, 3, self:GetColor())
end

function modifier_boss_capture_point:StartClockParticle()
  if not self.captureClockEffect then
    self.captureClockEffect = ParticleManager:CreateParticle(particleDirectory .. "capture_point_ring_clock.vpcf", PATTACH_ABSORIGIN, self:GetParent())
    ParticleManager:SetParticleControl(self.captureClockEffect, 9, Vector(self.radius, 0, 0))
    -- Controls how much of the dial to spawn. 1 is the full circle
    ParticleManager:SetParticleControl(self.captureClockEffect, 11, Vector(0, 0, 1))
  end
  ParticleManager:SetParticleControl(self.captureClockEffect, 3, self:GetColor())
end

function modifier_boss_capture_point:GetColor()
  local neutralColor = Vector(255, 150, 0)
  local radiantColor = Vector(0, 162, 255)
  local direColor = Vector(5, 155, 255)
  local endColor
  if self.capturingTeam == DOTA_TEAM_GOODGUYS then
    endColor = radiantColor
  elseif self.capturingTeam == DOTA_TEAM_BADGUYS then
    endColor = direColor
  else
    endColor = neutralColor
  end
  return SplineVectors(neutralColor, endColor, self.captureProgress / self.captureTime)
end

if IsServer() then
  function modifier_boss_capture_point:OnCreated(keys)
    self.captureFinishCallback = keys.finishFunction
    self.radius = keys.radius or 300
    self.captureTime = keys.captureTime or 10
    self.captureProgress = 0
    self.thinkInterval = 0.025
    local parent = self:GetParent()
    self.captureRingEffect = ParticleManager:CreateParticle(particleDirectory .. "capture_point_ring.vpcf", PATTACH_ABSORIGIN, parent)
    -- Particle colour
    ParticleManager:SetParticleControl(self.captureRingEffect, 3, self:GetColor())
    -- Ring radius
    ParticleManager:SetParticleControl(self.captureRingEffect, 9, Vector(self.radius, 0, 0))

    self:StartIntervalThink(self.thinkInterval)
  end
end

function modifier_boss_capture_point:OnIntervalThink()
  local parent = self:GetParent()
  local radiantUnits = FindUnitsInRadius(
    DOTA_TEAM_GOODGUYS,
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
    FIND_ANY_ORDER,
    false
  )
  local direUnits = FindUnitsInRadius(
    DOTA_TEAM_BADGUYS,
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_HERO,
    DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
    FIND_ANY_ORDER,
    false
  )
  if radiantUnits[1] and direUnits[1] then
    -- Point is being contested, just destroy capture in progress effect
    self:DestroyParticleByName("captureInProgressEffect")
    return
  end

  local function ResetStateToNeutral()
    self:DestroyParticleByName("captureInProgressEffect")
    self:DestroyParticleByName("captureClockEffect")
    self.captureProgress = 0
    self.capturingTeam = nil
    -- Update ring color
    ParticleManager:SetParticleControl(self.captureRingEffect, 3, self:GetColor())
  end
  if not radiantUnits[1] and not direUnits[1] then
    -- Point is empty, reset to neutral state
      ResetStateToNeutral()
    return
  end

  if radiantUnits[1] and self.capturingTeam ~= DOTA_TEAM_GOODGUYS then
    ResetStateToNeutral()
    self.capturingTeam = DOTA_TEAM_GOODGUYS
    return
  elseif direUnits[1] and self.capturingTeam ~= DOTA_TEAM_BADGUYS then
    ResetStateToNeutral()
    self.capturingTeam = DOTA_TEAM_BADGUYS
    return
  end

  self.captureProgress = self.captureProgress + self.thinkInterval
  if self.captureProgress >= self.captureTime then
    -- Point has been captured
    if self.captureFinishCallback then
      self.captureFinishCallback(self.capturingTeam)
    end
    self:Destroy()
    return
  end
  self:StartInProgressParticle()
  self:StartClockParticle()
  -- Set the orientation of the clock hand based on progress
  local theta = self.captureProgress / self.captureTime * 2 * math.pi
  ParticleManager:SetParticleControlForward(self.captureClockEffect, 1, Vector(math.cos(theta), math.sin(theta), 0))
  -- Update ring color
  ParticleManager:SetParticleControl(self.captureRingEffect, 3, self:GetColor())
end

if IsServer() then
  function modifier_boss_capture_point:OnDestroy()
    local particles = {
      "captureRingEffect",
      "captureInProgressEffect",
      "captureClockEffect"
    }
    foreach(partial(self.DestroyParticleByName, self), particles)
  end
end
