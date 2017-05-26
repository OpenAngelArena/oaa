LinkLuaModifier("modifier_kill", LUA_MODIFIER_MOTION_NONE)

if Glyph == nil then
  Debug.EnabledModules['filters:glyph'] = false
  DebugPrint('Creating new Glyph Filter Object')
  Glyph = class({})
end

function Glyph:Init()
  self.ward = {}
  self.scan = {}


  self.ward.cooldown = 360
  self.ward.cooldowns = tomap(zip(PlayerResource:GetAllTeamPlayerIDs(), duplicate(0)))
  self.scan.cooldowns = {
    [DOTA_TEAM_GOODGUYS] = 0,
    [DOTA_TEAM_BADGUYS] = 0,
  }

  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(Glyph, "Filter"))
end


function Glyph:Filter(keys)
  local order = keys.order_type
  local abilityEID = keys.entindex_ability
  local ability = EntIndexToHScript(abilityEID)
  local issuerID = keys.issuer_player_id_const
  local target = EntIndexToHScript(keys.entindex_target)

  if order == DOTA_UNIT_ORDER_GLYPH then
    -- Handle Glyph aka Ward Button
    DebugPrintTable(keys)
    self:CastWard(issuerID)
    return false
  elseif order == DOTA_UNIT_ORDER_RADAR then
    -- Handle Scan
    DebugPrintTable(keys)
    self:CastScan(issuerID)
    return false
  end

  return true
end

function Glyph:CastWard(playerID)
  if self:GetWardCooldown(playerID) > 0 then
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason=61, message=""})
    return
  end
  self:ResetWardCooldown(playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local position = hero:GetAbsOrigin()
  --[[for i=0,256 do
    Timers:CreateTimer(i * 2, function ()
      print('Message ' .. i)
      DebugDrawText(position, 'Message ' .. i, true, 2)
      CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason=i, message="message"})
    end)
  end]]

  local ward = CreateUnitByName("npc_dota_observer_wards", position, true, nil, hero, hero:GetTeam())
  ward:AddNewModifier(ward, nil, "modifier_kill", { duration = 360 })
end

function Glyph:ResetWardCooldown(playerID)
  self:SetWardCooldown(playerID, self:GetWardCooldown())
end

function Glyph:SetWardCooldown(playerID, time)
  local player = PlayerResource:GetPlayer(playerID)
  time = time or 0

  self.ward.cooldowns[playerID] = time
  CustomGameEventManager:Send_ServerToPlayer(player, "glyph_ward_cooldown", { cooldown = time, maxCooldown = self:GetWardCooldown() })
  Timers:CreateTimer(time, function ()
    self.ward.cooldowns[playerID] = 0
  end)
end

function Glyph:GetWardCooldown(playerID)
  if playerID then
    return self.ward.cooldowns[playerID]
  else
    return self.ward.cooldown
  end
end

function Glyph:CastScan(playerID)
  return nil
end
