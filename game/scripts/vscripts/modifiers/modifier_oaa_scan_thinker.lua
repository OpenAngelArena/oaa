modifier_oaa_scan_thinker = class(ModifierBaseClass)

if IsServer() then
  function modifier_oaa_scan_thinker:OnCreated(keys)
    local parent = self:GetParent()
    EmitSoundOnLocationForAllies(parent:GetAbsOrigin(), "scan_minimap.activate", parent)
    self:StartIntervalThink(1)
    self:OnIntervalThink()
  end

  function modifier_oaa_scan_thinker:OnDestroy()
    UTIL_Remove(self:GetParent())
  end

  function modifier_oaa_scan_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local parentTeam = parent:GetTeamNumber()
    local parentLoc = parent:GetAbsOrigin()
    local units = FindUnitsInRadius(
      parentTeam,
      parentLoc,
      nil,
      900,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local function IsNotNeutral(unit)
      return unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS
    end
    -- Filter out neutral team
    units = filter(IsNotNeutral, units)
    if nth(1, units) then
      EmitSoundOnLocationForAllies(parentLoc, "minimap_radar.target", parent)
      MinimapEvent(parentTeam, parent, parentLoc.x, parentLoc.y, DOTA_MINIMAP_EVENT_RADAR_TARGET, 1)
    else
      EmitSoundOnLocationForAllies(parentLoc, "minimap_radar.cycle", parent)
      MinimapEvent(parentTeam, parent, parentLoc.x, parentLoc.y, DOTA_MINIMAP_EVENT_RADAR, 1)
    end
  end
end
