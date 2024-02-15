if Glyph == nil then
  -- Debug:EnableDebugging()
  Glyph = class({})
end

function Glyph:Init()
  self.moduleName = "Glyph and Scan"

  local glyph_cooldown = GLYPH_COOLDOWN or 120
  self.glyph_duration = GLYPH_DURATION or 10
  self.glyph_interval = GLYPH_INTERVAL or 1
  local scan_cooldown = SCAN_REVEAL_COOLDOWN

  local game_mode = GameRules:GetGameModeEntity()
  --GameRules:SetGlyphCooldown(DOTA_TEAM_GOODGUYS, glyph_cooldown)
  --GameRules:SetGlyphCooldown(DOTA_TEAM_BADGUYS, glyph_cooldown)
  game_mode:SetCustomGlyphCooldown(glyph_cooldown)
  game_mode:SetCustomScanCooldown(scan_cooldown)

  local fountains = Entities:FindAllByClassname("ent_dota_fountain")
  for _, entity in pairs(fountains) do
    if entity:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
      self.radiant_fountain = entity
    elseif entity:GetTeamNumber() == DOTA_TEAM_BADGUYS then
      self.dire_fountain = entity
    end
  end

  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(Glyph, "Filter"))
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(Glyph, "ModifierFilter"))
end

function Glyph:Filter(keys)
  local order = keys.order_type
  local issuerID = keys.issuer_player_id_const

  if order == DOTA_UNIT_ORDER_GLYPH then
    self:CustomGlyphEffect(issuerID)
  elseif order == DOTA_UNIT_ORDER_RADAR then
    self:CustomScanEffect(keys)
  end

  return true
end

-- Disable vanilla scan
function Glyph:ModifierFilter(keys)
  if keys.name_const == "modifier_radar_thinker" then
    return false
  end

  return true
end

function Glyph:CustomGlyphEffect(playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local team = hero:GetTeamNumber()
  local oposite_team = DOTA_TEAM_BADGUYS
  local fountain = self.radiant_fountain
  if team == DOTA_TEAM_BADGUYS then
    oposite_team = DOTA_TEAM_GOODGUYS
    fountain = self.dire_fountain
  end

  local function KnockbackUnitsFromHighGround()
    local units = FindUnitsInRadius(
      oposite_team,
      Vector(0, 0, 0),
      nil,
      FIND_UNITS_EVERYWHERE,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, unit in pairs(units) do
      local unit_loc = unit:GetAbsOrigin()
      if (team == DOTA_TEAM_GOODGUYS and IsLocationInRadiantOffside(unit_loc)) or (team == DOTA_TEAM_BADGUYS and IsLocationInDireOffside(unit_loc)) then
        local direction = unit_loc - fountain:GetAbsOrigin()
        -- Normalize direction
        direction.z = 0
        direction = direction:Normalized()
        -- Calculate distance
        local distance = math.max(400, 4200 - (3800/4200) * DistanceFromFountainOAA(unit_loc, team))
        -- Push away from the fountain (off highground)
        unit:AddNewModifier(unit, nil, "modifier_custom_glyph_knockback", {
          distance = distance,
          speed = 1200,
          direction_x = direction.x,
          direction_y = direction.y,
        })
      end
    end
  end

  local duration = self.glyph_duration
  local interval = self.glyph_interval
  local loop_count = 0
  local max_loops = duration / interval

  Timers:CreateTimer(function ()
    KnockbackUnitsFromHighGround()
    loop_count = loop_count + 1
    if loop_count < max_loops then
      return interval -- repeat KnockbackUnitsFromHighGround every interval seconds
    end
  end)
end

function Glyph:CustomScanEffect(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.issuer_player_id_const)
  local position = Vector(keys.position_x, keys.position_y, keys.position_z)
  local team = hero:GetTeamNumber()

  -- CreateModifierThinker(hero, nil, "modifier_scan_true_sight_thinker", {duration = SCAN_REVEAL_DURATION}, position, team, false)
  local scan_thinker1 = CreateUnitByName("npc_dota_custom_dummy_unit", position, false, hero, hero, team)
  scan_thinker1:AddNewModifier(hero, nil, "modifier_oaa_thinker", {duration = SCAN_REVEAL_DURATION})
  scan_thinker1:AddNewModifier(hero, nil, "modifier_scan_true_sight_thinker", {duration = SCAN_REVEAL_DURATION})

  --CreateModifierThinker(hero, nil, "modifier_oaa_scan_thinker", {duration = SCAN_DURATION}, position, team, false)
  local scan_thinker2 = CreateUnitByName("npc_dota_custom_dummy_unit", position, false, hero, hero, team)
  scan_thinker2:AddNewModifier(hero, nil, "modifier_oaa_thinker", {duration = SCAN_DURATION})
  scan_thinker2:AddNewModifier(hero, nil, "modifier_oaa_scan_thinker", {duration = SCAN_DURATION})
end

---------------------------------------------------------------------------------------------------

modifier_custom_glyph_knockback = class(ModifierBaseClass)

function modifier_custom_glyph_knockback:IsDebuff()
  return false -- false because of Debuff Immunity
end

function modifier_custom_glyph_knockback:IsHidden()
  return true
end

function modifier_custom_glyph_knockback:IsPurgable()
  return false
end

function modifier_custom_glyph_knockback:IsStunDebuff()
  return true
end

function modifier_custom_glyph_knockback:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_custom_glyph_knockback:GetOverrideAnimation()
  return ACT_DOTA_FLAIL
end

function modifier_custom_glyph_knockback:GetPriority()
  return DOTA_MOTION_CONTROLLER_PRIORITY_HIGHEST
end

function modifier_custom_glyph_knockback:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
end

if IsServer() then
  function modifier_custom_glyph_knockback:OnCreated(event)
    -- Data sent with AddNewModifier (not available on the client)
    self.direction = Vector(event.direction_x, event.direction_y, 0)
    self.distance = event.distance
    self.speed = event.speed

    if self:ApplyHorizontalMotionController() == false then
      self:Destroy()
      return
    end
  end

  function modifier_custom_glyph_knockback:OnDestroy()
    local parent = self:GetParent()
    local parent_origin = parent:GetAbsOrigin()

    parent:RemoveHorizontalMotionController(self)

    -- Unstuck the parent
    FindClearSpaceForUnit(parent, parent_origin, false)
    ResolveNPCPositions(parent_origin, 128)
    GridNav:DestroyTreesAroundPoint(parent_origin, 200, true)
  end

  function modifier_custom_glyph_knockback:UpdateHorizontalMotion(parent, deltaTime)
    if not parent or parent:IsNull() or not parent:IsAlive() then
      return
    end

    local parentOrigin = parent:GetAbsOrigin()
    local tickTraveled = deltaTime * self.speed
    tickTraveled = math.min(tickTraveled, self.distance)
    if tickTraveled <= 0 then
      self:Destroy()
    end
    local tickOrigin = parentOrigin + tickTraveled * self.direction
    tickOrigin = Vector(tickOrigin.x, tickOrigin.y, GetGroundHeight(tickOrigin, parent))

    self.distance = self.distance - tickTraveled

    -- Unstucking (ResolveNPCPositions) is happening OnDestroy;
    parent:SetAbsOrigin(tickOrigin)
  end

  function modifier_custom_glyph_knockback:OnHorizontalMotionInterrupted()
    self:Destroy()
  end
end
