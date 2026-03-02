-- This is the entry-point to your game mode and should be used primarily to precache models/particles/sounds/etc

GAME_VERSION = "7.40.0"

-- Setup the main logger
require('internal/logging')

CustomNetTables:SetTableValue("info", "version", { value = GAME_VERSION })
-- lets do this here too
local mode = ""
if IsInToolsMode() then
  mode = "Tools Mode"
elseif GameRules:IsCheatMode() then
  mode = "Cheat Mode"
end
CustomNetTables:SetTableValue("info", "mode", { value = mode })
CustomNetTables:SetTableValue("info", "datetime", { value = GetSystemDate() .. " " .. GetSystemTime() })

require('libraries/gamerules')
require('internal/vconsole')
require('internal/eventwrapper')
require('internal/util')
-- component self registry system
require("components")

require('gamemode')
require('precache')

function Precache( context )
--[[
  This function is used to precache resources/units/items/abilities that will be needed
  for sure in your game and that will not be precached by hero selection.  When a hero
  is selected from the hero selection screen, the game will precache that hero's assets,
  any equipped cosmetics, and perform the data-driven precaching defined in that hero's
  precache{} block, as well as the precache{} block for any equipped abilities.

  See GameMode:PostLoadPrecache() in gamemode.lua for more information
  ]]

  print("Performing pre-load precache")

  for _,Item in pairs( g_ItemPrecache ) do
    PrecacheItemByNameAsync( Item, function( item ) end )
  end

   for _,Unit in pairs( g_UnitPrecache ) do
    PrecacheUnitByNameAsync( Unit, function( unit ) end )
  end

   for _,Model in pairs( g_ModelPrecache ) do
    PrecacheResource( "model", Model, context  )
  end

  for _,Particle in pairs( g_ParticlePrecache ) do
    PrecacheResource( "particle", Particle, context  )
  end

  for _,ParticleFolder in pairs( g_ParticleFolderPrecache ) do
    PrecacheResource( "particle_folder", ParticleFolder, context )
  end

  for _,Sound in pairs( g_SoundPrecache ) do
    PrecacheResource( "soundfile", Sound, context )
  end

  -- Precache bots
  if IsInToolsMode() then
    PrecacheUnitByNameSync("npc_dota_hero_axe", context)
    PrecacheUnitByNameSync("npc_dota_hero_bane", context)
    PrecacheUnitByNameSync("npc_dota_hero_bloodseeker", context)
    PrecacheUnitByNameSync("npc_dota_hero_bounty_hunter", context)
    PrecacheUnitByNameSync("npc_dota_hero_bristleback", context)
    PrecacheUnitByNameSync("npc_dota_hero_chaos_knight", context)
    PrecacheUnitByNameSync("npc_dota_hero_crystal_maiden", context)
    PrecacheUnitByNameSync("npc_dota_hero_dazzle", context)
    PrecacheUnitByNameSync("npc_dota_hero_death_prophet", context)
    PrecacheUnitByNameSync("npc_dota_hero_dragon_knight", context)
    PrecacheUnitByNameSync("npc_dota_hero_drow_ranger", context)
    PrecacheUnitByNameSync("npc_dota_hero_earthshaker", context)
    PrecacheUnitByNameSync("npc_dota_hero_jakiro", context)
    PrecacheUnitByNameSync("npc_dota_hero_juggernaut", context)
    PrecacheUnitByNameSync("npc_dota_hero_kunkka", context)
    PrecacheUnitByNameSync("npc_dota_hero_lich", context)
    PrecacheUnitByNameSync("npc_dota_hero_lina", context)
    PrecacheUnitByNameSync("npc_dota_hero_lion", context)
    PrecacheUnitByNameSync("npc_dota_hero_luna", context)
    PrecacheUnitByNameSync("npc_dota_hero_necrolyte", context)
    PrecacheUnitByNameSync("npc_dota_hero_nevermore", context)
    PrecacheUnitByNameSync("npc_dota_hero_omniknight", context)
    PrecacheUnitByNameSync("npc_dota_hero_oracle", context)
    PrecacheUnitByNameSync("npc_dota_hero_phantom_assassin", context)
    PrecacheUnitByNameSync("npc_dota_hero_pudge", context)
    PrecacheUnitByNameSync("npc_dota_hero_razor", context)
    PrecacheUnitByNameSync("npc_dota_hero_sand_king", context)
    PrecacheUnitByNameSync("npc_dota_hero_skeleton_king", context)
    PrecacheUnitByNameSync("npc_dota_hero_skywrath_mage", context)
    PrecacheUnitByNameSync("npc_dota_hero_sniper", context)
    PrecacheUnitByNameSync("npc_dota_hero_sven", context)
    PrecacheUnitByNameSync("npc_dota_hero_tidehunter", context)
    PrecacheUnitByNameSync("npc_dota_hero_tiny", context)
    PrecacheUnitByNameSync("npc_dota_hero_vengefulspirit", context)
    PrecacheUnitByNameSync("npc_dota_hero_viper", context)
    PrecacheUnitByNameSync("npc_dota_hero_warlock", context)
    PrecacheUnitByNameSync("npc_dota_hero_windrunner", context)
    PrecacheUnitByNameSync("npc_dota_hero_witch_doctor", context)
    PrecacheUnitByNameSync("npc_dota_hero_zuus", context)
  end

  -- precache all hero econ folders
  -- this makes immortals and stuff work
  -- local allheroes = LoadKeyValues('scripts/npc/npc_heroes.txt')
  -- for key,value in pairs(LoadKeyValues('scripts/npc/herolist.txt')) do
    -- if value == 1 then
      -- local hero = string.sub(key, 15)
      -- PrecacheResource("particle_folder", "particles/econ/items/" .. hero, context)
      -- PrecacheResource("model_folder", "particles/heroes/" .. hero, context)
    -- end
  -- end

  -- Particles can be precached individually or by folder
  -- It it likely that precaching a single particle system will precache all of its children, but this may not be guaranteed
  --PrecacheResource("particle", "particles/econ/generic/generic_aoe_explosion_sphere_1/generic_aoe_explosion_sphere_1.vpcf", context)
  --PrecacheResource("particle_folder", "particles/test_particle", context)

  -- Models can also be precached by folder or individually
  -- PrecacheModel should generally used over PrecacheResource for individual models
  --PrecacheResource("model_folder", "particles/heroes/antimage", context)
  --PrecacheResource("model", "particles/heroes/viper/viper.vmdl", context)
  --PrecacheModel("models/heroes/viper/viper.vmdl", context)
  --PrecacheModel("models/props_gameplay/treasure_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest001.vmdl", context)
  --PrecacheModel("models/props_debris/merchant_debris_chest002.vmdl", context)

  -- Sounds can precached here like anything else
  --PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_gyrocopter.vsndevts", context)

  -- Entire items can be precached by name
  -- Abilities can also be precached in this way despite the name
  --PrecacheItemByNameSync("example_ability", context)
  --PrecacheItemByNameSync("item_example_item", context)

  -- Entire heroes (sound effects/voice/models/particles) can be precached with PrecacheUnitByNameSync
  -- Custom units from npc_units_custom.txt can also have all of their abilities and precache{} blocks precached in this way
  --PrecacheUnitByNameSync("npc_dota_hero_ancient_apparition", context)
  --PrecacheUnitByNameSync("npc_dota_hero_enigma", context)
end

-- Create the game mode when we activate
function Activate()
  GameRules.GameMode = GameMode()
  GameRules.GameMode:_InitGameMode()
end
