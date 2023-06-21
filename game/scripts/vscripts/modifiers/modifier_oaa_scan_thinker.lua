modifier_oaa_scan_thinker = class(ModifierBaseClass)

if IsServer() then
  function modifier_oaa_scan_thinker:OnCreated(keys)
    local parent = self:GetParent()
    EmitSoundOnLocationForAllies(parent:GetAbsOrigin(), "scan_minimap.activate", parent)
    self:StartIntervalThink(1)
    self:OnIntervalThink()
  end

  function modifier_oaa_scan_thinker:OnDestroy()
    local parent = self:GetParent()
    if parent and not parent:IsNull() then
      parent:ForceKillOAA(false)
    end
  end

  function modifier_oaa_scan_thinker:OnIntervalThink()
    local parent = self:GetParent()
    local parentTeam = parent:GetTeamNumber()
    local parentLoc = parent:GetAbsOrigin()
    local units = FindUnitsInRadius(
      parentTeam,
      parentLoc,
      nil,
      SCAN_REVEAL_RADIUS,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO,
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD),
      FIND_ANY_ORDER,
      false
    )

    local function CheckIfValid(unit)
      return unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS and unit:GetUnitName() ~= "npc_dota_core_guy"
    end

    if not self.count then
      self.count = 0
    else
      self.count = self.count + 1
    end

    local sound_ping = self.count >= 2 and (self.count % 2 == 0)

    -- Filter out neutral team and some creep hero units
    units = filter(CheckIfValid, units)

    if nth(1, units) then
      if sound_ping then
        EmitSoundOnLocationForAllies(parentLoc, "minimap_radar.target", parent)
      end
      MinimapEvent(parentTeam, parent, parentLoc.x, parentLoc.y, DOTA_MINIMAP_EVENT_RADAR_TARGET, 1)
    else
      EmitSoundOnLocationForAllies(parentLoc, "minimap_radar.cycle", parent)
      MinimapEvent(parentTeam, parent, parentLoc.x, parentLoc.y, DOTA_MINIMAP_EVENT_RADAR, 1)
    end

    units:each(function(unit)
      if unit then
        unit:AddNewModifier(parent, nil, "modifier_oaa_scan_debuff", {duration = 1.0})
      end
    end)
  end
end

---------------------------------------------------------------------------------------------------

modifier_oaa_scan_debuff = class(ModifierBaseClass)

function modifier_oaa_scan_debuff:IsHidden()
  return false
end

function modifier_oaa_scan_debuff:IsDebuff()
  return true
end

function modifier_oaa_scan_debuff:IsPurgable()
  return false
end

function modifier_oaa_scan_debuff:GetTexture()
  return "custom/icon_scan_on_psd"
end
