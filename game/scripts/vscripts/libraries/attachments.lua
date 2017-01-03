ATTACHMENTS_VERSION = "1.00"

--[[
  Lua-controlled Frankenstein Attachments Library by BMD

  Installation
  -"require" this file inside your code in order to gain access to the Attachments global table.
  -Optionally require "libraries/notifications" before this file so that the Attachment Configuration GUI can display messages via the Notifications library.
  -Ensure that this file is placed in the vscripts/libraries path
  -Ensure that you have the barebones_attachments.xml, barebones_attachments.js, and barebones_attachments.css files in your panorama content folder to use the GUI.
  -Ensure that barebones_attachments.xml is included in your custom_ui_manifest.xml with
    <CustomUIElement type="Hud" layoutfile="file://{resources}/layout/custom_game/barebones_attachments.xml" />
  -Finally, include the "attachments.txt" in your scripts directory if you have a pre-build database of attachment settings.

  Library Usage
  -The library when required in loads in the "scripts/attachments.txt" file containing the attachment properties database for use during your game mode.
  -Attachment properties are specified as a 3-tuple of unit model name, attachment point string, and attachment prop model name.
    -Ex: ("models/heroes/antimage/antimage.vmdl" // "attach_hitloc" // "models/items/axe/weapon_heavy_cutter.vmdl")
  -Optional particles can be specified in the "Particles" block of attachmets.txt.
  -To attach a prop to a unit, use the Attachments:AttachProp(unit, attachPoint, model[, scale[, properties] ]) function
    -Ex: Attachments:AttachProp(unit, "attach_hitloc", "models/items/axe/weapon_heavy_cutter.vmdl", 1.0)
    -This will create the prop and retrieve the properties from the database to attach it to the provided unit
    -If you pass in an already created prop or unit as the 'model' parameter, the attachment system will scale, position, and attach that prop/unit without creating a new one
    -Scale is the prop scale to be used, and defaults to 1.0.  The scale of the prop will also be scaled based on the unit model scale.
    -It is possible not to use the attachment database, but to instead provide the properties directly in the 'properties' parameter.
    -This properties table will look like:
      {
        pitch = 45.0,
        yaw = 55.0,
        roll = 65.0,
        XPos = 10.0,
        YPos = -10.0,
        ZPos = -33.0,
        Animation = "idle_hurt"
      }
  -To retrieve the currently attached prop entity, you can call Attachments:GetCurrentAttachment(unit, attachPoint)
    -Ex: local prop = Attachments:AttachProp(unit, "attach_hitloc")
    -Calling prop:RemoveSelf() will automatically detach the prop from the unit
  -To access the loaded Attachment database directly (for reading properties directly), you can call Attachments:GetAttachmentDatabase()

  Attachment Configuration Usage
  -In tools-mode, execute "attachment_configure <ADDON_NAME>" to activate the attachment configuration GUI for setting up the attachment database.
  -See https://www.youtube.com/watch?v=PS1XmHGP3sw for an example of how to generally use the GUI
  -The Load button will reload the database from disk and update the current attach point/prop model if values are stored therein.
  -The Hide button will hide/remove the current atatach point/prop model being displayed
  -The Save button will save the current properties as well as any other adjusted properties in the attachment database to disk.  
  -Databases will be saved to the scripts/attachments.txt file of the addon you set when calling the attachment_configure <ADDON_NAME> command.
  -More detail to come...

  Notes
  -"attach_origin" can be used as the attachment string for attaching a prop do the origin of the unit, even if that unit has no attachment point named "attach_origin"
  -Attached props will automatically scale when the parent unit/models are scaled, so rescaling individual props after attachment is not necessary.
  -This library requires that the "libraries/timers.lua" be present in your vscripts directory.

  Examples:
  --Attach an Axe axe model to the "attach_hitloc" to a given unit at a 1.0 Scale.
    Attachments:AttachProp(unit, "attach_hitloc", "models/items/axe/weapon_heavy_cutter.vmdl", 1.0)

  --For GUI use, see https://www.youtube.com/watch?v=PS1XmHGP3sw

]]

--LinkLuaModifier( "modifier_animation_freeze", "libraries/modifiers/modifier_animation_freeze.lua", LUA_MODIFIER_MOTION_NONE )

LinkLuaModifier( "modifier_animation_freeze_stun", "libraries/attachments.lua", LUA_MODIFIER_MOTION_NONE )

modifier_animation_freeze_stun = class({})

function modifier_animation_freeze_stun:OnCreated(keys) 

end

function modifier_animation_freeze_stun:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_animation_freeze_stun:IsHidden()
  return true
end

function modifier_animation_freeze_stun:IsDebuff() 
  return false
end

function modifier_animation_freeze_stun:IsPurgable() 
  return false
end

function modifier_animation_freeze_stun:CheckState() 
  local state = {
    [MODIFIER_STATE_FROZEN] = true,
    [MODIFIER_STATE_STUNNED] = true,
  }

  return state
end

-- Drop out of self-include to prevent execution of timers library and other code in modifier lua VM environment
if not Entities or not Entities.CreateByClassname then
  return
end

require('libraries/timers')


local Notify = function(player, msg, duration)
  duration = duration or 2
  if Notifications then
    local table = {text=msg, duration=duration, style={color="red"}}
    Notifications:Bottom(player, table)
  else
    print('[Attachments.lua] ' .. msg)
  end
end

function WriteKV(file, firstLine, t, indent, done)
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  indent = indent or 1

  file:write(string.rep ("\t", indent-1) .. "\"" .. firstLine .. "\"\n")
  file:write(string.rep ("\t", indent-1) .. "{\n")
  for k,value in pairs(t) do
    if type(value) == "table" and not done[value] then
        done [value] = true
        WriteKV (file, k, value, indent + 1, done)
      elseif type(value) == "userdata" and not done[value] then
        --skip userdata
      else
        file:write(string.rep ("\t", indent) .. "\"" .. tostring(k) .. "\"\t\t\"" .. tostring(value) .. "\"\n")
      end
  end
  file:write(string.rep ("\t", indent-1) .. "}\n")
end

if not Attachments then
  Attachments = class({})
end

function Attachments:start()

  local src = debug.getinfo(1).source
  --print(src)

  self.gameDir = ""
  self.addonName = ""

  if IsInToolsMode() then

    if src:sub(2):find("(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]") then

      self.gameDir, self.addonName = string.match(src:sub(2), "(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]")
      --print('[attachments] ', self.gameDir)
      --print('[attachments] ', self.addonName)

      self.initialized = true

      self.activated = false
      self.dbFilePath = nil
      self.currentAttach = {}
      self.hiddenCosmetics = {}
      self.doAttach = true
      self.doSphere = false
      self.attachDB = LoadKeyValues("scripts/attachments.txt")


      if IsInToolsMode() then
        print('[attachments] Tools Mode')
        SendToServerConsole("dota_combine_models 0")
        Convars:RegisterCommand( "attachment_configure", Dynamic_Wrap(Attachments, 'ActivateAttachmentSetup'), "Activate Attachment Setup", FCVAR_CHEAT )
      end
    else
      print("[attachments] RELOADING")
      SendToServerConsole("script_reload_code " .. src:sub(2))
    end
  else
    self.initialized = true

    self.activated = false
    self.dbFilePath = nil
    self.currentAttach = {}
    self.hiddenCosmetics = {}
    self.doAttach = true
    self.doSphere = false
    self.attachDB = LoadKeyValues("scripts/attachments.txt")
  end
end

function Attachments:ActivateAttachmentSetup()
  addon = Attachments.addonName
  --[[if addon == nil or addon == "" then
    print("[Attachments.lua] Addon name must be specified.")
    return
  end]]

  if not io then
    print("[Attachments.lua] Attachments Setup is only available in tools mode.")
    return
  end
  if not Attachments.activated then
    local file = io.open("../../dota_addons/" .. addon ..  "/scripts/attachments.txt", 'r')
    if not file and Attachments.dbFilePath == nil then
      print("[Attachments.lua] Cannot find file 'dota_addons/" .. addon .. "/scripts/attachments.txt'.  Re-execute the console command to force create the file.")
      Attachments.dbFilePath = ""
      return
    end

    Attachments.dbFilePath = "../../dota_addons/" .. addon .. "/scripts/attachments.txt"

    if not file then
      file = io.open(Attachments.dbFilePath, 'w')
      WriteKV(file, "Attachments", {})
      print("[Attachments.lua] Created file: 'dota_addons/" .. addon .. "/scripts/attachments.txt'.")
    end
    file:close()

    CustomGameEventManager:RegisterListener("Attachment_DoSphere", Dynamic_Wrap(Attachments, "Attachment_DoSphere"))
    CustomGameEventManager:RegisterListener("Attachment_DoAttach", Dynamic_Wrap(Attachments, "Attachment_DoAttach"))
    CustomGameEventManager:RegisterListener("Attachment_Freeze", Dynamic_Wrap(Attachments, "Attachment_Freeze"))
    CustomGameEventManager:RegisterListener("Attachment_UpdateAttach", Dynamic_Wrap(Attachments, "Attachment_UpdateAttach"))
    CustomGameEventManager:RegisterListener("Attachment_SaveAttach", Dynamic_Wrap(Attachments, "Attachment_SaveAttach"))
    CustomGameEventManager:RegisterListener("Attachment_LoadAttach", Dynamic_Wrap(Attachments, "Attachment_LoadAttach"))
    CustomGameEventManager:RegisterListener("Attachment_HideAttach", Dynamic_Wrap(Attachments, "Attachment_HideAttach"))
    CustomGameEventManager:RegisterListener("Attachment_UpdateUnit", Dynamic_Wrap(Attachments, "Attachment_UpdateUnit"))
    CustomGameEventManager:RegisterListener("Attachment_HideCosmetic", Dynamic_Wrap(Attachments, "Attachment_HideCosmetic"))

    Attachments.activated = true
    Attachments.doSphere = true
  end

  local ply = Convars:GetCommandClient()
  CustomGameEventManager:Send_ServerToPlayer(ply, "activate_attachment_configuration", {})
end

function Attachments:Attachment_DoSphere(args)
  --DebugPrint('Attachment_DoSphere')
  --DebugPrintTable(args)

  Attachments.doSphere = args.doSphere == 1

  Attachments:Attachment_UpdateAttach(args)
end

function Attachments:Attachment_DoAttach(args)
  --DebugPrint('Attachment_DoAttach')
  --DebugPrintTable(args)

  Attachments.doAttach = args.doAttach == 1

  Attachments:Attachment_UpdateAttach(args)
end

function Attachments:Attachment_Freeze(args)
  --DebugPrint('Attachment_Freeze')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end

  if args.freeze == 1 then
    unit:AddNewModifier(unit, nil, "modifier_animation_freeze_stun", {})
    unit:SetForwardVector(Vector(0,-1,0))
    --unit:AddNewModifier(unit, nil, "modifier_stunned", {})
  else
    unit:RemoveModifierByName("modifier_animation_freeze_stun")
    --unit:RemoveModifierByName("modifier_stunned")
  end
end

function Attachments:Attachment_UpdateAttach(args)
  DebugPrint('Attachment_UpdateAttach')
  DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end
  
  local properties = args.properties
  local unitModel = unit:GetModelName()
  local attach = properties.attach
  local model = properties.model
  properties.attach = nil
  properties.model = nil

  if not string.find(model, "%.vmdl$") then
    Notify(args.PlayerID, "Prop model must end in '.vmdl'.")
    return
  end

  local point = unit:ScriptLookupAttachment(attach)
  if attach ~= "attach_origin" and point == 0 then
    Notify(args.PlayerID, "Attach point '" .. attach .. "' not found.")
    return
  end

  local db = Attachments.attachDB
  if not db[unitModel] then db[unitModel] = {} end
  if not db[unitModel][attach] then db[unitModel][attach] = {} end
  local oldProperties = db[unitModel][attach][model] or {}

  -- update old properties
  for k,v in pairs(properties) do
    oldProperties[k] = v
  end

  properties = oldProperties
  db[unitModel][attach][model] = properties
  

  if not Attachments.currentAttach[args.index] then Attachments.currentAttach[args.index] = {} end
  local prop = Attachments.currentAttach[args.index][attach]
  if prop and IsValidEntity(prop) then
    prop:RemoveSelf()
  end

  --Attachments.currentAttach[args.index][attach] = Attachments:AttachProp(unit, attach, model, properties.scale)
  Attachments:AttachProp(unit, attach, model, properties.scale)
end

function Attachments:Attachment_SaveAttach(args)
  --DebugPrint('Attachment_SaveAttach')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end
  
  local properties = args.properties
  local unitModel = unit:GetModelName()
  local attach = properties.attach
  local model = properties.model

  Attachments:Attachment_UpdateAttach(args)

  if not io then
    print("[Attachments.lua] Attachments Setup is only available in tools mode.")
    return
  end

  if Attachments.dbFilePath == nil or Attachments.dbFilePath == "" then
    print("[Attachments.lua] Attachments database file must be set.")
    return
  end

  local file = io.open(Attachments.dbFilePath, 'w')
  WriteKV(file, "Attachments", Attachments.attachDB)
  file:close();
end

function Attachments:Attachment_LoadAttach(args)
  --DebugPrint('Attachment_LoadAttach')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end

  local properties = args.properties
  local unitModel = unit:GetModelName()
  local attach = properties.attach
  local model = properties.model

  if not io then
    print("[Attachments.lua] Attachments Setup is only available in tools mode.")
    return
  end

  Attachments.attachDB = LoadKeyValues("scripts/attachments.txt")

  local db = Attachments.attachDB
  if not db[unitModel] or not db[unitModel][attach] or not db[unitModel][attach][model] then
    Notify(args.PlayerID, "No saved attach found for '" .. attach .. "'' / '" .. model .. "' on this unit.")
    return
  end

  local ply = PlayerResource:GetPlayer(args.PlayerID)
  local properties = {}
  for k,v in pairs(db[unitModel][attach][model]) do
    properties[k] = v
  end
  properties.attach = attach
  properties.model = model
  CustomGameEventManager:Send_ServerToPlayer(ply, "attachment_update_fields", properties)
end

function Attachments:Attachment_HideAttach(args)
  --DebugPrint('Attachment_HideAttach')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end
  
  local properties = args.properties
  local attach = properties.attach

  local currentAttach = Attachments.currentAttach
  if not currentAttach[args.index] or not currentAttach[args.index][attach] then
    Notify(args.PlayerID, "No Current Attach to Hide for '" .. attach .. "'.")
    return
  end

  local prop = currentAttach[args.index][attach]
  if prop and IsValidEntity(prop) then
    prop:RemoveSelf()
  end
  currentAttach[args.index][attach] = nil
end

function Attachments:Attachment_UpdateUnit(args)
  --DebugPrint('Attachment_UpdateUnit')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end

  local cosmetics = {}
  for i,child in ipairs(unit:GetChildren()) do
    if child:GetClassname() == "dota_item_wearable" and child:GetModelName() ~= "" then
      table.insert(cosmetics, child:GetModelName())
    end
  end

  --DebugPrintTable(cosmetics)
  CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(args.PlayerID), "attachment_cosmetic_list", cosmetics )
end

function Attachments:Attachment_HideCosmetic(args)
  --DebugPrint('Attachment_HideCosmetic')
  --DebugPrintTable(args)

  local unit = EntIndexToHScript(args.index)
  if not unit then
    Notify(args.PlayerID, "Invalid Unit.")
    return
  end

  local model = args.model;
  
  local cosmetics = {}
  for i,child in ipairs(unit:GetChildren()) do
    if child:GetClassname() == "dota_item_wearable" and child:GetModelName() == model then
      local hiddenCosmetics = Attachments.hiddenCosmetics[args.index]
      if not hiddenCosmetics then
        hiddenCosmetics = {}
        Attachments.hiddenCosmetics[args.index] = hiddenCosmetics
      end

      if hiddenCosmetics[model] then
        child:RemoveEffects(EF_NODRAW)
        hiddenCosmetics[model] = nil
      else
        --print("HIDING")
        child:AddEffects(EF_NODRAW)
        hiddenCosmetics[model] = true
      end
    end
  end
end



function Attachments:GetAttachmentDatabase()
  return Attachments.attachDB
end

function Attachments:GetCurrentAttachment(unit, attachPoint)
  if not Attachments.currentAttach[unit:entindex()] then return nil end
  local prop = Attachments.currentAttach[unit:entindex()][attachPoint]
  return prop
end

function Attachments:AttachProp(unit, attachPoint, model, scale, properties)

    local unitModel = unit:GetModelName()
    local propModel = model

    local db = Attachments.attachDB
    if propModel.GetModelName then propModel = propModel:GetModelName() end
    if not properties then
      if not db[unitModel] or not db[unitModel][attachPoint] or not db[unitModel][attachPoint][propModel] then
        print("[Attachments.lua] No attach found in attachment database for '" .. unitModel .. "', '" .. attachPoint .. "', '" .. propModel .. "'")
        return
      end
    end

    local attach = unit:ScriptLookupAttachment(attachPoint)
    local scale = scale or db[unitModel][attachPoint][propModel]['scale'] or 1.0

    properties = properties or db[unitModel][attachPoint][propModel]
    local pitch = tonumber(properties.pitch)
    local yaw = tonumber(properties.yaw)
    local roll = tonumber(properties.roll)
    --local angleSpace = QAngle(properties.QX, properties.QY, properties.QZ)
    local offset = Vector(tonumber(properties.XPos), tonumber(properties.YPos), tonumber(properties.ZPos)) * scale * unit:GetModelScale()
    local animation = properties.Animation
    
    --offset = RotatePosition(Vector(0,0,0), RotationDelta(angleSpace, QAngle(0,0,0)), offset)

    --local new_prop = Entities:CreateByClassname("prop_dynamic")
    local prop = nil
    if model.GetName and IsValidEntity(model) then
      prop = model
    else
      prop = SpawnEntityFromTableSynchronous("prop_dynamic", {model = propModel, DefaultAnim=animation, targetname=DoUniqueString("prop_dynamic")})
      prop:SetModelScale(scale * unit:GetModelScale())
    end

    local angles = unit:GetAttachmentAngles(attach)

    
    angles = QAngle(angles.x, angles.y, angles.z)
    --angles = RotationDelta(angles,QAngle(pitch, yaw, roll))
    --print(prop:GetAngles())
    --print(angles)
    --print(RotationDelta(RotationDelta(angles,QAngle(pitch, yaw, roll)),QAngle(0,0,0)))
    --angles = QAngle(pitch, yaw, roll)

    if not Attachments.doAttach then angles = QAngle(pitch, yaw, roll) end
    angles = RotateOrientation(angles,RotationDelta(QAngle(pitch, yaw, roll), QAngle(0,0,0)))

    --print('angleSpace = QAngle(' .. angles.x .. ', ' .. angles.y .. ', ' .. angles.z .. ')')

    local attach_pos = unit:GetAttachmentOrigin(attach)
    --attach_pos = attach_pos + RotatePosition(Vector(0,0,0), QAngle(angles.x,angles.y,angles.z), offset)
    attach_pos = attach_pos + RotatePosition(Vector(0,0,0), angles, offset)

    prop:SetAbsOrigin(attach_pos)
    prop:SetAngles(angles.x,angles.y,angles.z)

    -- Attach and store it
    if Attachments.doAttach then
      if attachPoint == "attach_origin" then
        prop:SetParent(unit, "")
      else        
        prop:SetParent(unit, attachPoint)
      end
    end


    -- From Noya
    local particle_data = nil
    if db['Particles']  then particle_data = db['Particles'][propModel] end
    if particle_data then
      for particleName,control_points in pairs(particle_data) do
        prop.fx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, prop)

        -- Loop through the Control Point Entities
        for k,ent_point in pairs(control_points) do
          ParticleManager:SetParticleControlEnt(prop.fx, tonumber(k), prop, PATTACH_POINT_FOLLOW, ent_point, prop:GetAbsOrigin(), true)
        end
      end    
    end


    if Attachments.timer then
      Timers:RemoveTimer(Attachments.timer)
    end
    Attachments.timer = Timers:CreateTimer(function()
      if Attachments.doSphere then
        if unit and IsValidEntity(unit) then
          DebugDrawSphere(unit:GetAttachmentOrigin(attach), Vector(255,255,255), 100, 15, true, .03)
        end
        if prop and IsValidEntity(prop) then
          DebugDrawSphere(prop:GetAbsOrigin(), Vector(0,0,0), 100, 15, true, .03)
        end
      end
      return .03
    end)


    if not Attachments.currentAttach[unit:GetEntityIndex()] then Attachments.currentAttach[unit:GetEntityIndex()] = {} end
    Attachments.currentAttach[unit:GetEntityIndex()][attachPoint] = prop

    return prop
end

if not Attachments.initialized then Attachments:start() end