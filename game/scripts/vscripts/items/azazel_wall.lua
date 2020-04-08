LinkLuaModifier("modifier_wall_segment", "items/azazel_wall.lua", LUA_MODIFIER_MOTION_NONE)

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
  local target_pos = self:GetCursorPosition()
  local wall_length = self:GetSpecialValueFor("wall_length")
  local segment_count = math.ceil(wall_length / (SEGMENT_RADIUS * 2)) -- Each segment can cover SEGMENT_RADIUS * 2 units
  local origin_caster = caster:GetOrigin()
  -- direction of the wall.
  local direction = RotatePosition(Vector(0, 0, 0), VectorToAngles(Vector(0, -1, 0)), Vector(target_pos.x - origin_caster.x, target_pos.y - origin_caster.y, 0)):Normalized() --[[rotate the vector between the cast location and the caster
    by 90 deg to the right, thus geting the *opposite* of the direction we will spawn wall segments in.]]
  if #direction == 0 then
    direction = RandomVector(1)
  end
  -- Spacing between each segment
  local segment_offset = 0
  if segment_count > 1 then
    segment_offset = (wall_length - SEGMENT_RADIUS * 2) / (segment_count - 1) * direction
  end
  local first_location = target_pos - direction * (wall_length / 2 - SEGMENT_RADIUS) --[[get the leftmost point of the spawn line,
    as visible from the caster's position; advances further to the right with each segment by `offset`.]]
  local spawned = false
  for i = 0,segment_count-1 do
    local location = first_location + segment_offset * i
    if #FindAllBuildingsInRadius(location, SEGMENT_RADIUS) < 1 and #FindCustomBuildingsInRadius(location, SEGMENT_RADIUS) < 1 then
      spawned = true
      GridNav:DestroyTreesAroundPoint(location, SEGMENT_RADIUS, true)
      local building = CreateUnitByName("npc_azazel_wall_segment", location, true, caster, caster:GetOwner(), caster:GetTeam())
      building:RemoveModifierByName("modifier_invulnerable") -- Only real buildings have invulnerability on spawn
      --building:SetHullRadius(SEGMENT_RADIUS)
      building:SetOrigin(location)
      building:SetOwner(caster)
      building:AddNewModifier(building, self, "modifier_building_construction", {})
      building:AddNewModifier(building, self, "modifier_wall_segment", {})
    end
  end
  if not spawned then
    return
  end

  self:SpendCharge()
end

-- upgrades
item_azazel_wall_2 = item_azazel_wall_1
item_azazel_wall_3 = item_azazel_wall_1
item_azazel_wall_4 = item_azazel_wall_1

--------------------------------------------------------------------------
-- base modifier

modifier_wall_segment = class(ModifierBaseClass)

function modifier_wall_segment:IsHidden()
  return true
end

function modifier_wall_segment:IsDebuff()
  return false
end

function modifier_wall_segment:IsPurgable()
  return false
end

function modifier_wall_segment:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_wall_segment:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_statue001_destruction.vmdl") -- doesn't seem to work.
    data.unit:SetOriginalModel("models/props_structures/radiant_statue001_destruction.vmdl")
    data.unit:ManageModelChanges()
  end
end
