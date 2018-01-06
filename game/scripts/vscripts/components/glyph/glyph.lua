LinkLuaModifier("modifier_kill", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ward_invisibility", "modifiers/modifier_ward_invisibility.lua", LUA_MODIFIER_MOTION_NONE)

LinkLuaModifier("modifier_scan_true_sight_thinker", "modifiers/modifier_scan_true_sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_scan_true_sight", "modifiers/modifier_scan_true_sight.lua", LUA_MODIFIER_MOTION_NONE)


if Glyph == nil then
  -- Debug:EnableDebugging()
  DebugPrint('Creating new Glyph Filter Object')
  Glyph = class({})
end

function Glyph:Init()
  self.ward = {}
  self.scan = {}


  self.ward.cooldown = POOP_WARD_COOLDOWN
  self.scan.cooldown = SCAN_REVEAL_COOLDOWN

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
    self:CastScan(issuerID, keys)
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
  ward:AddNewModifier(ward, nil, "modifier_kill", { duration = POOP_WARD_DURATION })
  ward:AddNewModifier(ward, nil, "modifier_ward_invisibility", { })
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


--[[
{
  ["entindex_ability"] = 0,
  ["sequence_number_const"] = 34,
  ["queue"] = 0,
  ["units"] = {
    ["0"] = 364,
   } ,
  ["entindex_target"] = 0,
  ["position_z"] = 228.81585693359,
  ["position_x"] = -3273.6315917969,
  ["order_type"] = 31,
  ["position_y"] = -197.20104980469,
  ["issuer_player_id_const"] = 0,
}
]]--

function Glyph:CastScan(playerID, keys)

  if self:GetScanCooldown(playerID) > 0 then
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "custom_dota_hud_error_message", {reason=61, message=""})
    return
  end

  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local position = Vector(keys.position_x, keys.position_y, keys.position_z)

  CreateModifierThinker( hero, nil, "modifier_scan_true_sight_thinker", {duration = SCAN_REVEAL_DURATION}, position, hero:GetTeamNumber(), false )
  CreateModifierThinker( hero, nil, "modifier_radar_thinker", {duration = SCAN_DURATION}, position, hero:GetTeamNumber(), false )

  self:ResetScanCooldown(playerID)

end

function Glyph:ResetScanCooldown(playerID)
  self:SetScanCooldown(playerID, self:GetScanCooldown())
end

function Glyph:SetScanCooldown(playerID, time)
  local player = PlayerResource:GetPlayer(playerID)
  local team = player:GetTeam()
  time = time or 0

  self.scan.cooldowns[team] = time
  CustomGameEventManager:Send_ServerToPlayer(player, "glyph_scan_cooldown", { cooldown = time, maxCooldown = self:GetScanCooldown() })
  Timers:CreateTimer(time, function ()
    self.scan.cooldowns[team] = 0
  end)
end

function Glyph:GetScanCooldown(playerID)
  if playerID then
    local player = PlayerResource:GetPlayer(playerID)
    local team = player:GetTeam()
    return self.scan.cooldowns[team]
  else
    return self.scan.cooldown
  end
end
