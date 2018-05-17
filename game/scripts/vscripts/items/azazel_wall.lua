LinkLuaModifier("modifier_wall_segment_construction", "items/azazel_wall.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_wall_1 = class(ItemBaseClass)

local SEGMENT_RADIUS = 96 -- the wall segments's collision radius as defined in the script data.

function item_azazel_wall_1:CastFilterResultLocation(location)
  if IsServer() and self:GetCaster():IsPositionInRange(location, SEGMENT_RADIUS + self:GetCaster():GetHullRadius()) then
    return UF_FAIL_CUSTOM
  else
    return UF_SUCCESS
  end
end
function item_azazel_wall_1:GetCustomCastErrorLocation(location)
  return "#dota_hud_error_no_buildings_here"
end

-- Spawns a line of wall segments perpendicular to the line between the cast location and the caster.
function item_azazel_wall_1:OnSpellStart()
  local caster = self:GetCaster()
  local origin = self:GetCursorPosition()
  -- total length of the wall.
  local length = self:GetSpecialValueFor("wall_length") - SEGMENT_RADIUS * 2 -- adjusting in order to make a total of `wall_length`.
  -- number of segments.
  local count = math.floor(length / SEGMENT_RADIUS)
  local origin_caster = caster:GetOrigin()
  -- direction of the wall.
  local direction = RotatePosition(Vector(0, 0, 0), VectorToAngles(Vector(0, -90, 0)), Vector(origin.x - origin_caster.x, origin.y - origin_caster.y, origin.z)):Normalized() --[[rotate the vector between the cast location and the caster
    by 90 deg to the right, thus geting the *opposite* of the direction we will spawn wall segments in.]]
  if #direction == 0 then
    direction = RandomVector(1)
  end
  -- small gaps (spacing) between each segment to spread them evenly along the wall, if `length` isn't divisible by `SEGMENT_RADIUS`.
  local offset = (length % SEGMENT_RADIUS / count + SEGMENT_RADIUS) * direction
  local location = origin - direction * (length / 2) --[[get the leftmost point of the spawn line,
    as visible from the caster's position; advances further to the right with each segment by `offset`.]]
  local spawned = false
  foreach(function()
    if #FindUnitsInRadius(DOTA_TEAM_NEUTRALS, location, nil, SEGMENT_RADIUS, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BUILDING,
      DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false) < 1
    then
      spawned = true
      GridNav:DestroyTreesAroundPoint(location, SEGMENT_RADIUS, true)
      local building = CreateUnitByName("npc_azazel_wall_segment", location, true, caster, caster:GetOwner(), caster:GetTeam())
      building:SetOrigin(location)
      building:RemoveModifierByName("modifier_invulnerable")
      building:AddNewModifier(building, self, "modifier_wall_segment_construction", {duration = -1})
      building:SetOwner(caster)
      location = location + offset
    end
  end, range(count))
  if not spawned then
    return
  end
  local charges = self:GetCurrentCharges() - 1
  if charges < 1 then
    caster:RemoveItem(self)
  else
    self:SetCurrentCharges(charges)
  end
end

-- upgrades
item_azazel_wall_2 = item_azazel_wall_1
item_azazel_wall_3 = item_azazel_wall_1
item_azazel_wall_4 = item_azazel_wall_1

--------------------------------------------------------------------------
-- base modifier

modifier_wall_segment_construction = class(ModifierBaseClass)

local SINK_HEIGHT = 200
local THINK_INTERVAL = 0.1

function modifier_wall_segment_construction:OnCreated()
  if IsServer() then
    local target = self:GetParent()
    local ab = self:GetAbility()
    local maxhealth = target:GetMaxHealth() + ab:GetSpecialValueFor("bonus_health")
    local location = target:GetOrigin()
    local time = ab:GetSpecialValueFor("construction_time")
    target:Attribute_SetIntValue("construction_time", time)
    target:SetOrigin(GetGroundPosition(location, target) - Vector(0, 0, SINK_HEIGHT))
    Timers:CreateTimer(0.1, function()
      ResolveNPCPositions(location, target:GetHullRadius())
      target:SetMaxHealth(maxhealth)
      target:SetHealth(maxhealth * 0.01)
      self:StartIntervalThink(THINK_INTERVAL)
      self:SetStackCount(math.floor(time / THINK_INTERVAL)) -- `construction_time` should be divisible by `THINK_INTERVAL`!
    end)
  end
end
function modifier_wall_segment_construction:OnIntervalThink()
  if IsServer() then
    local target = self:GetParent()
    local time = target:Attribute_GetIntValue("construction_time", 10)
    local count = self:GetStackCount()
    local location = target:GetOrigin()
    target:SetOrigin(target:GetOrigin() + Vector(0, 0, SINK_HEIGHT / (time / THINK_INTERVAL)))
    self:SetStackCount(count - 1)
    if count < 1 then
      self:StartIntervalThink(-1)
    end
  end
end
function modifier_wall_segment_construction:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end
function modifier_wall_segment_construction:IsHidden()
  return true
end
function modifier_wall_segment_construction:IsDebuff()
  return false
end
function modifier_wall_segment_construction:IsPurgable()
  return false
end
function modifier_wall_segment_construction:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end
function modifier_wall_segment_construction:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_statue001_destruction.vmdl") -- doesn't seem to work.
    self:GetParent():SetOriginalModel("models/props_structures/radiant_statue001_destruction.vmdl")
    self:GetParent():ManageModelChanges()
  end
end
function modifier_wall_segment_construction:GetModifierConstantHealthRegen()
  if IsServer() and self:GetStackCount() > 0 then
    return self:GetParent():GetMaxHealth() / self:GetParent():Attribute_GetIntValue("construction_time", 10)
  else
    return 0
  end
end
