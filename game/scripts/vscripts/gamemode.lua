-- This is the primary barebones gamemode script and should be used to assist in initializing your game mode
BAREBONES_VERSION = "1.00"

-- Set this to true if you want to see a complete debug output of all events/processes done by barebones
-- You can also change the cvar 'barebones_spew' at any time to 1 or 0 for output/no output
-- this overrides per-module logging rules and just opens the floodgates
BAREBONES_DEBUG_SPEW = false

if GameMode == nil then
  DebugPrint( '[BAREBONES] creating barebones game mode' )
  print("Lua Version: " .. _VERSION)
  GameMode = class({})
end

-- functional library, sugar for excellent code. this should be usable in any library, so we include it first
require('libraries/functional')
-- Lua Fun(ctional) library
require('libraries/fun')()
-- functional event implementation
require('libraries/event')

-- This library allow for easily delayed/timed actions
require('libraries/timers')
-- This library can be used for sending panorama notifications to the UIs of players/teams/everyone
require('libraries/notifications')
-- This library can be used for starting customized animations on units from lua
require('libraries/animations')
-- This library can be used to synchronize client-server data via player/client-specific nettables
require('libraries/playertables')
-- Helpful math functions from the internet
require('libraries/math')
-- chat command registry made easy
require('libraries/chatcommand')
-- extension functions to PlayerResource
require('libraries/playerresource')
-- Extensions to CDOTA_BaseNPC_Hero
require('libraries/basehero')
-- Pseudo-random distribution C constant calculator
require('libraries/cfinder')
-- Library for handling buildings (OAA custom or DOTA original)
require('libraries/buildings')
-- Vector Targeting library (requires VectorTarget module and vector_targeting.js)
--require('libraries/vector_targeting')

-- These internal libraries set up barebones's events and processes.  Feel free to inspect them/change them if you need to.
require('internal/gamemode')
require('internal/events')

-- settings.lua is where you can specify many different properties for your game mode and is one of the core barebones files.
require('settings')
-- events.lua is where you can specify the actions to be taken when any event occurs and is one of the core barebones files.
require('events')

--[[ all library code has been loaded ]]

-- load components
require('components/index')

--[[
  This function should be used to set up Async precache calls at the beginning of the gameplay.

  In this function, place all of your PrecacheItemByNameAsync and PrecacheUnitByNameAsync.  These calls will be made
  after all players have loaded in, but before they have selected their heroes. PrecacheItemByNameAsync can also
  be used to precache dynamically-added datadriven abilities instead of items.  PrecacheUnitByNameAsync will
  precache the precache{} block statement of the unit and all precache{} block statements for every Ability#
  defined on the unit.

  This function should only be called once.  If you want to/need to precache more items/abilities/units at a later
  time, you can call the functions individually (for example if you want to precache units in a new wave of
  holdout).

  This function should generally only be used if the Precache() function in addon_game_mode.lua is not working.
]]
function GameMode:PostLoadPrecache()
  DebugPrint("[BAREBONES] Performing Post-Load precache")
  --PrecacheItemByNameAsync("item_example_item", function(...) end)
  --PrecacheItemByNameAsync("example_ability", function(...) end)

  --PrecacheUnitByNameAsync("npc_dota_hero_viper", function(...) end)
  --PrecacheUnitByNameAsync("npc_dota_hero_enigma", function(...) end)
end

--[[
  This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
  It can be used to initialize state that isn't initializeable in InitGameMode() but needs to be done before everyone loads in.
]]
function GameMode:OnFirstPlayerLoaded()
  DebugPrint("[BAREBONES] First Player has loaded")

  CheckCheatMode()
end

--[[
  This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
  It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
  DebugPrint("[BAREBONES] All Players have loaded into the game")
end

--[[
  This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
  if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
  levels, changing the starting gold, removing/adding abilities, adding physics, etc.

  The hero parameter is the hero entity that just spawned in
]]
function GameMode:OnHeroInGame(hero)
  --DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())

  -- These lines will create an item and add it to the player, effectively ensuring they start with the item
  -- local item = CreateItem("item_example_item", hero, hero)
  -- hero:AddItem(item)

  --[[ --These lines if uncommented will replace the W ability of any hero that loads into the game
    --with the "example_ability" ability

  local abil = hero:GetAbilityByIndex(1)
  hero:RemoveAbility(abil:GetAbilityName())
  hero:AddAbility("example_ability")]]
end

function GameMode:OnPreGame()
  -- initialize modules
  InitModule(PointsManager)
  InitModule(Music)
  InitModule(Gold)
  InitModule(BlinkBlock)
  InitModule(ZoneControl)
  InitModule(AbilityLevels)
  InitModule(HeroProgression)
  InitModule(Glyph)
  InitModule(BubbleOrbFilter)
  InitModule(BossProtectionFilter)
  --InitModule(ReactiveFilter)
  --InitModule(NGP)
  --InitModule(Doors)
  InitModule(HeroKillGold)
  InitModule(HeroKillXP)
  InitModule(EntityStatProvider)
  InitModule(RespawnManager)
  InitModule(BountyRunePick)
  InitModule(ModifyAbilitiesFilter)
  InitModule(HudTimer)
  InitModule(Duels)
  InitModule(DuelRunes)
  InitModule(PlayerConnection)
  InitModule(ProtectionAura)
  InitModule(CustomRuneSystem)

  CheckCheatMode()
end

--[[
  This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
  gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
  is useful for starting any game logic timers/thinkers, beginning the first round, etc.
]]
function GameMode:OnGameInProgress()
  DebugPrint("[BAREBONES] The game has officially begun")
  -- initialize modules
  InitModule(SurrenderManager)
  InitModule(CreepPower)
  InitModule(CreepCamps)
  InitModule(CreepItemDrop)
  --InitModule(CaveHandler)
  InitModule(CapturePoints)
  InitModule(BossSpawner)
  InitModule(BottleCounter)
  InitModule(FinalDuel)
  --InitModule(StatusResistance)
  InitModule(SaveLoadState)
  InitModule(PassiveExperience)

  -- valve is a really great company that totally cares about custom game mode creators and it's a breath of fresh air
  GameRules:SetTimeOfDay( 0.251 )
end

function InitModule(myModule)
  if myModule ~= nil then
    if myModule.initialized == true then
      print("Module "..tostring(myModule.moduleName).." is already initialized and there was an attempt to initialize it again -> preventing")
      return
    end
    local status, err = pcall(function () --luacheck: ignore status
      myModule:Init()
      myModule.initialized = true
    end)
    if err then
      local info = debug.getinfo(2, "Sl")
      print("Script Runtime Error: " .. info.source:sub(2) .. ":" .. info.currentline .. ": " .. err)
      print(debug.traceback())
      print('Failed to init module!!!')
    end
  end
end

function CheckCheatMode()
  if GameRules:IsCheatMode() then
    print("\nThis Match is in Cheat Mode!\n")
    GameRules:SendCustomMessage("This Match is in <font color='#FF0000'>Cheat Mode</font>!", 0, 0)
    CustomGameEventManager:Send_ServerToAllClients("onGameInCheatMode", {})
  end
end

local OnInitGameModeEvent = CreateGameEvent('OnInitGameMode')
-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:InitGameMode()
  DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

  InitModule(Components)

  InitModule(FilterManager)
  InitModule(Bottlepass)
  InitModule(Courier)
  --InitModule(StartingItems)
  InitModule(OAAOptions)
  InitModule(HeroSelection)
  InitModule(ChatCommand)
  InitModule(DevCheats)
  --InitModule(VectorTarget)
  InitModule(CorePointsManager)
  InitModule(TeamVision)
  InitModule(CustomTalentSystem)
  InitModule(CustomWardButtons)
  InitModule(HeroCosmetics)

  -- Increase maximum owned item limit
  Convars:SetInt('dota_max_physical_items_purchase_limit', 64)

  -- Change spectating delay
  if GetMapName() ~= "captains_mode" then
    Convars:SetInt('tv_delay', 60)
  end

  -- Reduce taunt secondary cooldown
  Convars:SetFloat('dota_taunt_second_cooldown', 13)

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')

  OnInitGameModeEvent()
end
