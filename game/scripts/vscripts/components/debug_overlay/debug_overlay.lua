
if DebugOverlay == nil then
  Debug.EnabledModules['debug_overlay:*'] = false
  DebugPrint ('creating new DebugOverlay object')
  DebugOverlay = class({})
end

function DebugOverlay:Init()
  DebugPrint("Make Root Node")
  self.Overlay = self:_MakeRoot()

  DebugPrint("Creating Game Events")
  CustomGameEventManager:RegisterListener("debug_overlay_request", function (playerID)
    --print("<- Update_Request")
    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID - 1), "debug_overlay_update", { value = self.Overlay })
    --print("-> Update")
  end)

  DebugPrint("Starting AutoUpdater")
  self.autoUpdateList = {}
  --self.eventUpdateList = {}
  --self.eventUpdateHandler = {}
  self:_StartAutoUpdater()
end

function DebugOverlay:_MakeRoot()
  local generic = self:_MakeEmptyGeneric({
    Name = "root",
    Color = "#FFFFFF"
  })
  generic.type = "group"
  generic.Children = {}
  generic.ChildCount = 0
  return generic
end

function DebugOverlay:_MakeEmptyGeneric(settings)
  assert(settings.Name, "Name was not specified")
  return {
    Name = settings.Name,
    DisplayName = settings.DisplayName or "",
    Color = settings.Color or "#FFFFFF"
  }
end

function DebugOverlay:TraverseOverlay(name, group)
  assert(name, "Name was not specified")
  group = group or self.Overlay

  if group.Name == name then return group end

  for _,child in pairs(group.Children) do
    if child.Name == name then return child end
    if child.type == "group" then
      local result = self:TraverseOverlay(name, child)
      if result ~= nil then return result end
    end
  end

  return nil
end

function DebugOverlay:_AddGeneric(parentGroupName, settings, fn)
  assert(parentGroupName, "parentGroupName was not specified")
  local parentGroup = self:TraverseOverlay(parentGroupName)
  assert(parentGroup, "parentGroup doesn't exist")
  assert(parentGroup.type == "group", "Cannot add an entry to an entry")

  settings.Color = settings.Color or parentGroup.Color
  parentGroup.ChildCount = parentGroup.ChildCount + 1
  parentGroup.Children[parentGroup.ChildCount] = fn(self:_MakeEmptyGeneric(settings))
end

--[[
parentGroupName: parent group name
settings.Name: name of the new group
settings.DisplayName: diplayed name of the group, nil means blank
settings.Color (optional): fallback color for all entries and groups of the new color
]]
function DebugOverlay:AddGroup(parentGroupName, settings)
  --print("Adding group " .. settings.Name .. " to parent group " .. parentGroupName)
  self:_AddGeneric(parentGroupName, settings, function(generic)
    generic.type = "group"
    generic.Children = {}
    generic.ChildCount = 0
    return generic
  end)
end

--[[
parentGroup: parent group name
settings.yName: internal name of the new entry
settings.DisplayName: displayed name of the entry, nil means blank
settings.Color (optional): color for this entry
settings.Value (optional): initial value for the new entry
]]
function DebugOverlay:AddEntry(parentGroupName, settings)
  --print("Adding entry " .. settings.Name .. " to parent group " .. parentGroupName)
  self:_AddGeneric(parentGroupName, settings, function(generic)
    generic.type = "entry"
    generic.Value = settings.Value or "???"
    generic.autoUpdate = settings.autoUpdate or false
    --generic.eventUpdate = settings.eventUpdate
    generic.updateCallback = settings.updateCallback

    self:_HandleUpdater(generic, settings)

    return generic
  end)
end

function DebugOverlay:Update(genericName, settings)
  assert(genericName, "Name was not specified")
  local generic = self:TraverseOverlay(genericName)
  assert(generic, "The entry or group '" .. genericName .. "' doesn't exist")

  generic.DisplayName = settings.DisplayName or generic.DisplayName
  generic.Color = settings.Color or generic.Color

  if generic.type == "entry" then
    generic.Value = settings.Value or generic.Value
  end

  generic.autoUpdate = settings.autoUpdate or generic.autoUpdate
  --generic.eventUpdate = settings.eventUpdate or generic.eventUpdate

  generic.updateCallback = settings.updateCallback or generic.updateCallback

  self:_HandleUpdater(generic , settings)

  if settings.forceUpdate then
    self:UpdateDisplay()
  end
end

function DebugOverlay:_HandleUpdater(generic, settings)
  if generic.autoUpdate or generic.eventUpdate then
    assert(type(generic.updateCallback) == "function",
      "Expected 'updateCallback' to be a function but got " .. type(generic.updateCallback))
  end

  if generic.autoUpdate then
    self:_AddAutoUpdater(generic)
  else
    self:_RemoveAutoUpdater(genericName)
  end

  if generic.eventUpdate then
    self:_AddEventUpdater(generic)
  else
    self:_RemoveEventUpdater(generic)
  end
end

function DebugOverlay:_StartAutoUpdater()
  Timers:CreateTimer(function()
    for name,generic in pairs(self.autoUpdateList) do
      if generic then
        self:Update(name, {
          value = generic.updateCallback()
        })
      end
    end
    self:UpdateDisplay()
    return 0.1
  end)
end

function DebugOverlay:_AddAutoUpdater(generic)
  if not self.autoUpdateList[generic.Name] then
    self.autoUpdateList[generic.Name] = generic
  end
end

function DebugOverlay:_RemoveAutoUpdater(genericName)
  if self.autoUpdateList[genericName] then
    self.autoUpdateList[genericName] = nil
  end
end

function DebugOverlay:_AddEventUpdater(generic) end

function DebugOverlay:_RemoveEventUpdater(generic) end

function DebugOverlay:UpdateDisplay()
  CustomGameEventManager:Send_ServerToAllClients("debug_overlay_update", {
    value = self.Overlay
  })
end
