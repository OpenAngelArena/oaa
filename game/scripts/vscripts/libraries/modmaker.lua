MODMAKER_VERSION = "0.80"

require('libraries/timers')

--[[
  ModMaker Library by BMD

  Installation
  -"require" this file inside your code in order to make the ModMaker API available in game
  -Ensure that this file is placed in the vscripts/libraries path
  -Ensure that you have the modmaker/modmaker.xml, modmaker/modmaker_api_category.xml, and modmaker/modmaker_api_property.xml in your panorama content layout folder.
  -Ensure that you have the modmaker/modmaker.js, modmaker/modmaker_api_category.js, and modmaker/modmaker_api_property.js in your panorama content scripts folder.
  -Ensure that you have the modmaker/modmaker.css in your panorama content styles folder.
  -Ensure that modmaker/modmaker.xml is included in your custom_ui_manifest.xml with
    <CustomUIElement type="Hud" layoutfile="file://{resources}/layout/custom_game/modmaker/modmaker.xml" />

  Library Usage
  -The library when required in registers the "modmaker_api" console command (if in tools mode)
  -Executing the "modmakers_api" console command will display the modmaker API UI in the game window, which allows for searching and exploring of the lua API.
  -This API is based on the actual server vscript itself, and as such is always up to date and accurate (to the Valve docs).
  -Each function has a "Search GitHub" button which will open the default browser on your system to search github for uses of the function in question.
  
]]

if not ModMaker then
  ModMaker = class({})
end

local mask = 0xBF
local mark = 0x80
local fbm =  { 0x00, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC }
local UTF8extra = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
    2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 
    3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
}
local UTFMagicOffsets = { 0x00000000, 0x00003080, 0x000E2080, 0x03C82080, 0xFA082080, 0x82082080 }

local function utf16to8(str)
  local out = {}
  for i=1,str:len(),2 do
    local b = bit.lshift(str:byte(i+1), 8) + str:byte(i)
    local tow = 1
    if b < 0x80 then tow = 1
    elseif b < 0x800 then tow = 2
    elseif b < 0x10000 then tow = 3
    elseif b < 0x110000 then tow = 4
    end
    --print(b,tow)

    local toww = tow

    local r = {}

    if tow == 4 then
      r[4] = string.char(bit.band(bit.bor(b, mark), mask))
      b = bit.rshift(b,6)
      tow = tow - 1
    end
    if tow == 3 then
      r[3] = string.char(bit.band(bit.bor(b, mark), mask))
      b = bit.rshift(b,6)
      tow = tow - 1
    end
    if tow == 2 then
      r[2] = string.char(bit.band(bit.bor(b, mark), mask))
      b = bit.rshift(b,6)
      tow = tow - 1
    end
    if tow == 1 then
      r[1] = table.insert(out, string.char(bit.bor(b, fbm[toww])))
      b = bit.rshift(b,6)
      tow = tow - 1
    end

    for j=1,#r do
      table.insert(out, r[j])
    end
  end

  return table.concat(out)
end

local function utf8to16(str)
  local out = {}
  local i = 1
  while i<=str:len() do
    local b = str:byte(i)
    local extra = UTF8extra[b+1];
    local ex = extra
    local c = 0

    if ex == 3 then
      c = bit.lshift(c + b, 6)
      i = i+1
      b = str:byte(i)
      ex = ex - 1
    end
    if ex == 2 then
      c = bit.lshift(c + b, 6)
      i = i+1
      b = str:byte(i)
      ex = ex - 1
    end
    if ex == 1 then
      c = bit.lshift(c + b, 6)
      i = i+1
      b = str:byte(i)
      ex = ex - 1
    end
    if ex == 0 then
      c = c + b
      i = i+1
    end

    --print(extra, c, UTFMagicOffsets[extra+1], c - UTFMagicOffsets[extra+1])

    c = c - UTFMagicOffsets[extra+1]
    table.insert(out, string.char(bit.band(c, 0x00FF)))
    table.insert(out, string.char(bit.rshift(c, 8)))
  end

  return table.concat(out)
end


local function GetAPI(t, sub, done)
  --print ( string.format ('PrintTable type %s', type(keys)) )
  if type(t) ~= "table" then return end

  done = done or {}
  done[t] = true
  sub = sub or ModMaker.api

  local l = {}
  for k, v in pairs(t) do
    table.insert(l, k)
  end

  local ret = nil

  table.sort(l)
  for k, v in ipairs(l) do
    -- Ignore FDesc
    if v == 'CDesc' then
      --print('======================')
      --PrintTable(t[v])
      --print('======================')
      GetAPI (t[v], nil, done)
      ret = true
    elseif v ~= 'FDesc' then
      local value = t[v]

      if type(value) == "table" and not done[value] then
        done [value] = true
        if type(v) == "string" and v:sub(1,1):find("[A-Z]") then
          v = v:gsub("CDOTA_", "")
          v = v:gsub("CDOTA", "")
          if v:sub(2,2):find("[A-Z]") then v = v:sub(2) end
          local temp = {}
          local r = GetAPI (value, temp, done)
          if r then
            sub[v] = temp
            ret = true
          end
        end
      elseif type(value) == "userdata" and not done[value] then
        --done [value] = true
        --GetAPI ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), sub, done)
      else
        if t.FDesc and t.FDesc[v] then
          local func, desc = string.match(tostring(t.FDesc[v]), "(.*)\n(.*)")
          if sub == ModMaker.api then
            ModMaker.api.__GLOBAL__[v] = {f=func,d=desc}
          else
            sub[v] = {f=func,d=desc}
          end
          ret = true
        end
      end
    end
  end

  return ret
end


function ModMaker:start()
  if not __ACTIVATE_HOOK then
    __ACTIVATE_HOOK = {funcs={}}
    setmetatable(__ACTIVATE_HOOK, {
      __call = function(t, func)
        table.insert(t.funcs, func)
      end
    })

    debug.sethook(function(...)
      local info = debug.getinfo(2)
      local src = tostring(info.short_src)
      local name = tostring(info.name)
      if name ~= "__index" then
        if string.find(src, "addon_game_mode") then
          if GameRules:GetGameModeEntity() then
            for _, func in ipairs(__ACTIVATE_HOOK.funcs) do
              local status, err = pcall(func)
              if not status then
                print("__ACTIVATE_HOOK callback error: " .. err)
              end
            end

            debug.sethook(nil, "c")
          end
        end
      end
    end, "c")
  end

  --[[__ACTIVATE_HOOK(function()
    print('activate hook called')
    local mode = GameRules:GetGameModeEntity()
    mode:SetExecuteOrderFilter(Dynamic_Wrap(ModMaker, 'OrderFilter'), ModMaker)
    ModMaker.oldFilter = mode.SetExecuteOrderFilter
    mode.SetExecuteOrderFilter = function(mode, fun, context)
      --print('SetExecuteOrderFilter', fun, context)
      ModMaker.nextFilter = fun
      ModMaker.nextContext = context
    end
    ModMaker.initialized = true
  end)]]

  self.api = {__GLOBAL__ = {}}

  local src = debug.getinfo(1).source
  --print(src)

  self.gameDir = ""
  self.contentDir = ""
  self.addonName = ""

  self.gameFiles = {}
  self.contentFiles = {}

  if src:sub(2):find("(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]") then

    self.gameDir, self.addonName = string.match(src:sub(2), "(.*dota 2 beta[\\/]game[\\/]dota_addons[\\/])([^\\/]+)[\\/]")
    self.contentDir = self.gameDir:gsub("\\game\\dota_addons\\", "\\content\\dota_addons\\")

    self.initialized = true

    Convars:RegisterCommand( "modmaker_api", Dynamic_Wrap(ModMaker, 'ModMakerAPI'), "Show the ModMaker lua API for a serachable listing of the server lua vscript.", FCVAR_CHEAT )

    CustomGameEventManager:RegisterListener("ModMaker_OpenGithub", Dynamic_Wrap(ModMaker, "ModMaker_OpenGithub"))
  else
    SendToServerConsole("script_reload_code " .. src:sub(2))
  end

  --print(ModMaker.addonName)
  --print(ModMaker.contentDir )
  --print(ModMaker.gameDir)
end

function ModMaker:ModMaker_OpenGithub(msg)
  local search = msg.search
  local language = msg.language

  print("ModMaker_OpenGithub",search,language)

  local url = "https://github.com/search?utf8=%E2%9C%93&q=" .. search .. "&l=" .. language .. "&type=Code"

  local t = io.popen("start \"Browser\" \"" .. url .. "\"")
  t:lines()
end

function ModMaker:ModMakerAPI()
  if not ModMaker.apiBuilt then
    ModMaker.apiBuilt = true
    ModMaker:BuildAPI()

    CustomGameEventManager:Send_ServerToAllClients("modmaker_lua_api", {api=ModMaker.api})
  else
    CustomGameEventManager:Send_ServerToAllClients("modmaker_lua_api", {})
  end
end

function ModMaker:BuildAPI()
  GetAPI(_G)
end

function ModMaker:LoadFile(fileName, content)
  local dir = self.gameDir
  if content then dir = self.contentDir end

  local src = dir .. self.addonName .. "/" .. fileName
  local file = io.open(src, "rb")
  local str = {}

  local temp = nil
  local total = 0
  while 1 do
    temp = file:read("*all")
    if temp == nil or temp == "" then
      break
    end
    table.insert(str,temp)
  end

  local str = table.concat(str)
  if str:byte(1) == 0xFF and str:byte(2) == 0xFE then
    print("UCS2LE")
    str = utf16to8(str:sub(3))
  end

  if content then 
    self.contentFiles[fileName] = str
  else
    self.gameFiles[fileName] = str
  end
end

function ModMaker:SendFile(fileName, content)
  local str = self.gameFiles[fileName]
  if content then str = self.contentFiles[fileName] end
  if str == nil then
    print("No file to send, " .. fileName)
  end
  local msg = 1
  local max = math.floor((str:len()-1) / 500000) + 1
  for i=1,str:len(),500000 do
    local rest = math.min(str:len() - i+1, 500000)
    print("ASD",i,rest)
    local r = {}
    for j=i,i+rest,32000 do
      local rest2 = math.min(i+rest - j, 32000)
      print(j, rest2, j+rest2-1)
      table.insert(r, str:sub(j,j+rest2-1))
    end
    if msg == 1 then
      CustomGameEventManager:Send_ServerToAllClients("modmaker_send_file", {name=fileName, count=msg, max=max, t=r})
    else
      local c = msg
      Timers(msg*1/30, function() CustomGameEventManager:Send_ServerToAllClients("modmaker_send_file", {name=fileName, count=c, max=max, t=r}) end)
    end
    msg = msg + 1
  end
end

if not ModMaker.initialized and IsInToolsMode() then ModMaker:start() end