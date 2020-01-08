LinkLuaModifier("modifier_shrine", "items/azazel_shrine.lua", LUA_MODIFIER_MOTION_NONE)

item_azazel_summon_shrine = class(ItemBaseClass)

function item_azazel_summon_shrine:CastFilterResultLocation(location)
  local SEGMENT_RADIUS = 96
  if IsServer() and self:GetCaster():IsPositionInRange(location, SEGMENT_RADIUS + self:GetCaster():GetHullRadius()) then
    return UF_FAIL_CUSTOM
  else
    return UF_SUCCESS
  end
end
function item_azazel_summon_shrine:GetCustomCastErrorLocation(location)
  return "#dota_hud_error_no_buildings_here"
end

-- Spawns a line of wall segments perpendicular to the line between the cast location and the caster.
function item_azazel_summon_shrine:OnSpellStart()
  local caster = self:GetCaster()
  local location = self:GetCursorPosition()
  local SEGMENT_RADIUS = 96 -- the wall segments's collision radius as defined in the script data.

  if #FindAllBuildingsInRadius(location, SEGMENT_RADIUS) < 1 and #FindCustomBuildingsInRadius(location, SEGMENT_RADIUS) < 1 then
    GridNav:DestroyTreesAroundPoint(location, SEGMENT_RADIUS, true)
    local building = CreateUnitByName("npc_azazel_wall_segment", location, true, caster, caster:GetOwner(), caster:GetTeam())
    building:RemoveModifierByName("modifier_invulnerable") -- Only real buildings have invulnerability on spawn
    --building:SetHullRadius(SEGMENT_RADIUS)
    building:SetOrigin(location)
    building:SetOwner(caster)
    building:AddNewModifier(building, self, "modifier_building_construction", {})
    building:AddNewModifier(building, self, "modifier_shrine", {})
  else
    return
  end

  self:SpendCharge()
end

--------------------------------------------------------------------------

modifier_shrine = class(ModifierBaseClass)

function modifier_shrine:IsHidden()
  return true
end

function modifier_shrine:IsDebuff()
  return false
end

function modifier_shrine:IsPurgable()
  return false
end

function modifier_shrine:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_shrine:OnDeath(data)
  if data.unit == self:GetParent() then
    --self:GetParent():SetModel("models/props_structures/radiant_statue001_destruction.vmdl") -- doesn't seem to work.
    data.unit:SetOriginalModel("models/props_structures/radiant_statue001_destruction.vmdl")
    data.unit:ManageModelChanges()
  end
end
