containers_lua_targeting = class({})

--------------------------------------------------------------------------------
function containers_lua_targeting:GetBehavior()
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return self.BaseClass.GetBehavior(self) end 

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem then
    return proxyItem:GetBehavior()
  end
end

function containers_lua_targeting:GetAOERadius()
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return self.BaseClass.GetAOERadius(self) end 

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetAOERadius then
    return proxyItem:GetAOERadius()
  end
    
  return result.aoe
end

function containers_lua_targeting:GetCastRange(vLocation, hTarget)
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return self.BaseClass.GetCastRange(self, vLocation, hTarget) end 

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetCastRange then
    return proxyItem:GetCastRange(vLocation, hTarget)
  end
  
  return result.range
end

function containers_lua_targeting:GetChannelTime()
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return self.BaseClass.GetChannelTime(self) end 

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetChannelTime then
    return proxyItem:GetChannelTime()
  end

  return result.channelTime
end

function containers_lua_targeting:GetChannelledManaCostPerSecond(iLevel)
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return self.BaseClass.GetChannelledManaCostPerSecond(self, iLevel) end 

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetChannelledManaCostPerSecond then
    return proxyItem:GetChannelledManaCostPerSecond(iLevel)
  end
  
  return result.channelCost
end

--------------------------------------------------------------------------------

function containers_lua_targeting:CastFilterResult( )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return UF_SUCCESS end
 
  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.CastFilterResult then
    return proxyItem:CastFilterResult()
  end
 
  return UF_SUCCESS
end
 
function containers_lua_targeting:GetCustomCastError( )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return "" end

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetCustomCastError then
    return proxyItem:GetCustomCastError()
  end

  return ""
end

--------------------------------------------------------------------------------

function containers_lua_targeting:CastFilterResultLocation( vLocation )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return UF_SUCCESS end
 
  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.CastFilterResultLocation then
    return proxyItem:CastFilterResultLocation(vLocation)
  end
 
  return UF_SUCCESS
end
 
function containers_lua_targeting:GetCustomCastErrorLocation( vLocation )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return "" end

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetCustomCastErrorLocation then
    return proxyItem:GetCustomCastErrorLocation(vLocation)
  end

  return ""
end

--------------------------------------------------------------------------------

function containers_lua_targeting:CastFilterResultTarget( hTarget )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return UF_SUCCESS end
 
  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.CastFilterResultTarget then
    return proxyItem:CastFilterResultTarget(hTarget)
  end

  local nResult = UnitFilter( hTarget, result.targetTeam, result.targetType, result.targetFlags, self:GetCaster():GetTeamNumber() )
  if nResult ~= UF_SUCCESS then
    return nResult
  end
 
  return UF_SUCCESS
end
 
function containers_lua_targeting:GetCustomCastErrorTarget( hTarget )
  local result = CustomNetTables:GetTableValue("containers_lua", tostring(self:entindex()))
  if not result then return "" end

  local proxyItem = EntIndexToHScript(result.proxyItem)
  if proxyItem and proxyItem.GetCustomCastErrorTarget then
    return proxyItem:GetCustomCastErrorTarget(hTarget)
  end

  return ""
end

--------------------------------------------------------------------------------

function containers_lua_targeting:OnChannelThink(flInterval)
  local item = self.proxyItem
  self.proxyItem:OnChannelThink(flInterval)
end

function containers_lua_targeting:OnChannelFinish(bInterrupted)
  local item = self.proxyItem
  self.proxyItem:OnChannelFinish(bInterrupted)
end

function containers_lua_targeting:OnAbilityPhaseStart()
  return self.proxyItem:OnAbilityPhaseStart()

end

function containers_lua_targeting:OnAbilityPhaseInterrupted()
  self.proxyItem:OnAbilityPhaseInterrupted()
end

function containers_lua_targeting:OnSpellStart()
  local target = self:GetCursorTarget()
  local pos = self:GetCursorPosition()

  local item = self.proxyItem
  local owner = item:GetOwner()

  local behavior =     item:GetBehavior()
  local channelled =   bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) ~= 0

  item:PayGoldCost()
  item:PayManaCost()
  item:StartCooldown(item:GetCooldown(item:GetLevel()))
  owner:SetCursorPosition(pos)
  owner:SetCursorCastTarget(target)

  item:OnSpellStart()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------