-- In this file you can set up all the properties and settings for your game mode.

-----------------------------------------------------------------------------------
-- General globals

DOTA_TEAM_SPECTATOR = 1

-----------------------------------------------------------------------------------
-- OAA specific settings

-- Respawn time settings
RESPAWN_NEUTRAL_DEATH_PENALTY = 5 -- Extra respawn time for dying to neutrals
RESPAWN_TIME_TABLE = {} -- Lookup table mapping level to respawn time. Can be used to override respawn time for specific levels
-- Set function to calculate respawn time based on level
setmetatable(RESPAWN_TIME_TABLE, {
  __index = function (table, key)
    local minLevel = 1
    local maxLevel = 49
    local minTime = 5
    local maxTime = 30
    local clampedLevel = math.min(maxLevel, key)
    -- Store result instead of recalculating for lookups for the same level
    -- Linear interpolation between min and max level/time pairs
    table[key] = math.floor(minTime + (clampedLevel - minLevel) * (maxTime - minTime) / (maxLevel - minLevel))
    return table[key]
  end
})

-- safe to leave
TIME_TO_ABANDON = 300                     -- how long a player can be disconnected before they're forced to abandon
AUTO_ABANDON_IN_CM = false                -- if force abandon should be enabled in captains mode
MIN_MATCH_TIME = 180                      -- if someone abandons before this point, the match doesn't count
ABANDON_DIFF_NEEDED = 2                   -- how many more abandons you need on your team for the countdown to start
ABANDON_NEEDED = 3                        -- how many total abandons you need before auto win conditions can trigger

-- kill limits
NORMAL_KILL_LIMIT = 40
TEN_V_TEN_KILL_LIMIT = 80
KILL_LIMIT_INCREASE = 10

-- poop wards
POOP_WARD_DURATION = 360
POOP_WARD_COOLDOWN = 120
POOP_WARD_RADIUS = 150

-- scan reveal
SCAN_REVEAL_COOLDOWN = 60
SCAN_REVEAL_RADIUS = 900
SCAN_REVEAL_DURATION = 14
SCAN_DURATION = 14

-- PICK SCREEN
CAPTAINS_MODE_CAPTAIN_TIME = 20           -- how long players have to claim the captain chair
CAPTAINS_MODE_PICK_BAN_TIME = 30          -- how long you have to do each pick/ban
CAPTAINS_MODE_HERO_PICK_TIME = 45         -- time to choose which hero you're going to play
CAPTAINS_MODE_RESERVE_TIME = 130          -- total bonus time that can be used throughout any selection

RANKED_PREGAME_TIME = 0
RANKED_BAN_TIME = 30
RANKED_PICK_TIME = 30

-- Game timings
PREGAME_TIME = 35
AP_GAME_TIME = 90

-- Duels
INITIAL_DUEL_DELAY = 35                 -- how long after the clock hits 0 should the initial duel start counting down
DUEL_START_WARN_TIME = 10               -- How many seconds to count down before each duel (added as a delay before the duel starts)
DUEL_START_COUNTDOWN = 5                -- How many seconds to count down before each duel (added as a delay before the duel starts)
DUEL_TIMEOUT = 90                       -- Time before the duel starts counting down to end in a stalemate
FIRST_DUEL_TIMEOUT = 80                 -- Timeout for the level 1 duel at the start of them game
FINAL_DUEL_TIMEOUT = 300                -- Timeout for the final duel, the game cannot end unless this duel completes without timing out
DUEL_END_COUNTDOWN = 10                 -- How many seconds to count down before a duel can timeout (added as a delay before the duel times out)
DUEL_RUNE_TIMER = 30                    -- how long until the highground object becomes active in duels
DUEL_INTERVAL = 480                     -- time from duel ending until dnext duel countdown begins
DUEL_START_PROTECTION_TIME = 2          -- duel start protection duration

-- Sparks
SPARK_LEVEL_1_TIME = 0                  -- just a placeholder so the other names make more sense
SPARK_LEVEL_2_TIME = 240                -- 4 minutes
SPARK_LEVEL_3_TIME = 900                -- 15 minutes
SPARK_LEVEL_4_TIME = 1500               -- 25 minutes
SPARK_LEVEL_5_TIME = 2100               -- 35 minutes

-- CapturePoints
INITIAL_CAPTURE_POINT_DELAY = 600       -- how long after the clock hits 0 should the initial Capture Point start counting down
CAPTURE_FIRST_WARN = 60                 -- how many seconds before spawn of capture points the first ping on minimap will show
CAPTURE_SECOND_WARN = 30                -- how many seconds before spawn of capture points the second ping on minimap will show
CAPTURE_START_COUNTDOWN = 5             -- How many seconds to count down before each CapturePoint (added as a delay before the duel starts)
CAPTURE_INTERVAL = 600                  -- time from CapturePoint beginning until next CapturePoint begins
CAPTURE_LENTGH = 30                     -- amount of time for 1 hero to capture the point (less with more)

-- Bosses
BOSS_RESPAWN_TIMER = 60                 -- time after boss death before spawning the next tier boss
BOSS_RESPAWN_START = 180                -- time for the first boss spawn
BOSS_LEASH_SIZE = 1200                  -- number of units a boss will walk before starting to head back
BOSS_AGRO_FACTOR = 20                   -- boss must take (tier * n) damage before agro
BOSS_WANDERER_SPAWN_START = 12 * 60     -- start time for wanderer spawn
BOSS_WANDERER_RESPAWN = 5 * 60          -- start time for wanderer spawn

-- Creeps
CREEP_SPAWN_INTERVAL = 60               -- number of seconds between each creep spawn
INITIAL_CREEP_DELAY = 1                 -- number of seconds to wait before spawning the first wave of creeps
BOTTLE_DESPAWN_TIME = 60                -- Time until Bottles despawn
CREEP_POWER_MAX = 1.5                   -- the total max power creeps will get stacked up to (1 = 100%)
CREEP_BOUNTY_SHARE_RADIUS = 1500        -- the radius in which creep bounty is shared with allies
CREEP_BOUNTY_SHARE_PERCENT = 35         -- the percentage of the creep's bounty that's given to shared allies
CREEP_BOUNTY_BONUS_PERCENT_CLEAVE = 15  -- the bonus percentage of the creep's bounty that's given to those that kill with Cleave Spark
CREEP_BOUNTY_BONUS_PERCENT_POWER = 30   -- the bonus percentage of the creep's bounty that's given to those that kill with Power Spark

-- Player
GAME_ABANDON_TIME = 90                 -- Time until game ends if a team has left

-- Save/resume state
SAVE_STATE_ENABLED = true              -- kill switch
SAVE_STATE_INTERVAL = 21               -- kind of a random number so they're unpredictable. it makes them seem more frequent on load
SAVE_STATE_AP = true                   -- should we save state in all pick games?

--Gold
_G.BOOT_GOLD_FACTOR = 1.0               -- Multiplier to account for the presence of bonus gold boots

--Cave
_G.CAVE_ROOM_INTERVAL = 2               -- Expected time of room clear, in minutes
_G.CAVE_DIFFICULTY = 3                  -- Multiplies cave difficulty growth compared to normal creeps
_G.CAVE_BOUNTY = 1                      -- Accelerates cave bounty increase compared to the rest of the game
CAVE_RELEVANCE_FACTOR = 10              -- magic haga value, originally "k"
CAVE_MAX_MULTIPLIER = 2                 -- magic haga value, originally "m"

-- Logging
-- TODO: Make this a module loader so the following can be handled:
    -- Multiple log instances for different logging levels
    -- Simple configuration for several setups, such as Loggly and a custom implementation
LOGGLY_ACCOUNT_ID = 'afa7c97f-1110-4738-9e10-4423f3675386'      -- The Loggly token to toss errors to

-- XP gain and rubberband on hero kills
USE_CUSTOM_HERO_LEVELS = true  -- Should the heroes give a custom amount of XP when killed? Set to true if you don't want DotA default values.

-- Formula for XP on hero kill: (HERO_XP_BOUNTY_BASE + HERO_XP_BOUNTY_STREAK + HERO_XP_BONUS_FACTOR x DyingHeroXP)/number_of_killers
-- Old formula: DyingHeroBaseXPBounty + (AOE_XP_LEVEL_MULTIPLIER × DyingHeroLevel) + (AOE_XP_BONUS_FACTOR × TeamXPDiff × DyingHeroXP)
HERO_XP_BOUNTY_BASE = 20             -- 40 in normal dota
HERO_XP_BOUNTY_STREAK_BASE = 50      -- 400 in normal dota (XP bonus when killing heroes with Killing Spree - 3 kills in a row)
HERO_XP_BOUNTY_STREAK_INCREASE = 100 -- 200 in normal dota
HERO_XP_BOUNTY_STREAK_MAX = 850      -- 1800 in normal dota (XP bonus when killing heroes with Beyond Godlike - 10+ kills in a row)
HERO_XP_BONUS_FACTOR = 0.07          -- 0.13 in normal dota
HERO_KILL_XP_RADIUS = 1500           -- 1500 in normal dota

-- Bounty runes
FIRST_BOUNTY_RUNE_SPAWN_TIME = 120        -- After what delay in seconds will the first bounty rune spawn?
BOUNTY_RUNE_SPAWN_INTERVAL = 120        -- How long in seconds should we wait between bounty rune spawns?
BOUNTY_RUNE_INITIAL_TEAM_GOLD = 16
BOUNTY_RUNE_INITIAL_TEAM_XP = 9

-- end OAA specific settings
-----------------------------------------------------------------------------------

ENABLE_HERO_RESPAWN = true              -- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             -- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = false       -- Should we let people select the same hero as each other

CUSTOM_GAME_SETUP_TIME = 30.0           -- How long to show custom game setup? 0 disables
HERO_SELECTION_TIME = 30.0              -- How long should we let people select their hero?
POST_GAME_TIME = 60.0                   -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 -- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 1                       -- How much gold should players get per tick? This increases over time in OAA.
GOLD_TICK_TIME = 1                      -- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = false     -- Should we disable the recommened builds for heroes
CAMERA_DISTANCE_OVERRIDE = 1268           -- How far out should we allow the camera to go?  Use -1 for the default (1134) while still allowing for panorama camera distance changes

MINIMAP_ICON_SIZE = 1                   -- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1              -- What icon size should we use for runes?

CUSTOM_BUYBACK_COST_ENABLED = true      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = true  -- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 -- Should we allow people to buyback when they die?

DISABLE_FOG_OF_WAR_ENTIRELY = false     -- Should we disable fog of war entirely for both teams?
USE_UNSEEN_FOG_OF_WAR = false           -- Should we make unseen and fogged areas of the map completely black until uncovered by each team?
                                            -- Note: DISABLE_FOG_OF_WAR_ENTIRELY must be false for USE_UNSEEN_FOG_OF_WAR to work
USE_STANDARD_DOTA_BOT_THINKING = true   -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true    -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = true        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true                  -- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true             -- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = false       -- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = false               -- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50         -- How many kills for a team should signify an end of game?

MAX_LEVEL = 50                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {
	0,
	240,
	600,
	1080,
	1680,
	2300,
	2940,
	3600,
	4280,
	5080,
	5900,
	6740,
	7640,
	8865,
	10115,
	11390,
	12690,
	14015,
	15415,
	16905,
	18505,
	20405,
	22605,
	25105,
	27800,
}
for i = #XP_PER_LEVEL_TABLE + 1, MAX_LEVEL do
  XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + (300 * ( i - 15 ))
end

ENABLE_FIRST_BLOOD = true               -- Should we enable first blood for the first kill in this game?
HIDE_KILL_BANNERS = false               -- Should we hide the kill banners that show when a player is killed?
LOSE_GOLD_ON_DEATH = true               -- Should we have players lose the normal amount of dota gold on death?
SHOW_ONLY_PLAYER_INVENTORY = false      -- Should we only allow players to see their own inventory even when selecting other units?
DISABLE_STASH_PURCHASING = false        -- Should we prevent players from being able to buy items into their stash when not at a shop?
DISABLE_ANNOUNCER = false               -- Should we disable the announcer from working in the game?
FORCE_PICKED_HERO = "npc_dota_hero_dummy_dummy" -- What hero should we force all players to spawn as? (e.g. "npc_dota_hero_axe").  Use nil to allow players to pick their own hero.

FIXED_RESPAWN_TIME = -1                 -- What time should we use for a fixed respawn timer?  Use -1 to keep the default dota behavior.
FOUNTAIN_CONSTANT_MANA_REGEN = -1       -- What should we use for the constant fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_MANA_REGEN = -1     -- What should we use for the percentage fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_HEALTH_REGEN = -1   -- What should we use for the percentage fountain health regen?  Use -1 to keep the default dota behavior.
MAXIMUM_ATTACK_SPEED = 600              -- What should we use for the maximum attack speed?
MINIMUM_ATTACK_SPEED = 20               -- What should we use for the minimum attack speed?

GAME_END_DELAY = -1                     -- How long should we wait after the game winner is set to display the victory banner and End Screen?  Use -1 to keep the default (about 10 seconds)
VICTORY_MESSAGE_DURATION = 3            -- How long should we wait after the victory message displays to show the End Screen?  Use
STARTING_GOLD = 825                     -- How much starting gold should we give to each player?
DISABLE_DAY_NIGHT_CYCLE = false         -- Should we disable the day night cycle from naturally occurring? (Manual adjustment still possible)
DISABLE_KILLING_SPREE_ANNOUNCER = false -- Should we disable the killing spree announcer?
DISABLE_STICKY_ITEM = false             -- Should we disable the sticky item button in the quick buy area?
SKIP_TEAM_SETUP = true and IsInToolsMode()       -- Should we skip the team setup entirely?
ENABLE_AUTO_LAUNCH = true               -- Should we automatically have the game complete team setup after AUTO_LAUNCH_DELAY seconds?
AUTO_LAUNCH_DELAY = 30                  -- How long should the default team selection launch timer be?  The default for custom games is 30.  Setting to 0 will skip team selection.
LOCK_TEAM_SETUP = false                 -- Should we lock the teams initially?  Note that the host can still unlock the teams

USE_DEFAULT_RUNE_SYSTEM = false     -- Should we use the default dota rune spawn timings and the same runes as dota have?
FIRST_POWER_RUNE_SPAWN_TIME = 120   -- After what delay in seconds will the first power-up rune spawn?
POWER_RUNE_SPAWN_INTERVAL = 120     -- How long in seconds should we wait between power-up runes spawns?

ENABLED_RUNES = {}                      -- Which runes should be enabled to spawn in our game mode?
ENABLED_RUNES[DOTA_RUNE_DOUBLEDAMAGE] = true
ENABLED_RUNES[DOTA_RUNE_HASTE] = true
ENABLED_RUNES[DOTA_RUNE_ILLUSION] = true
ENABLED_RUNES[DOTA_RUNE_INVISIBILITY] = true
ENABLED_RUNES[DOTA_RUNE_REGENERATION] = true
ENABLED_RUNES[DOTA_RUNE_BOUNTY] = true
ENABLED_RUNES[DOTA_RUNE_ARCANE] = true  -- If this doesn't spawn use RuneSpawn filter

MAX_NUMBER_OF_TEAMS = 2                -- How many potential teams can be in this game mode?
USE_CUSTOM_TEAM_COLORS = false           -- Should we use custom team colors?
USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS = true          -- Should we use custom team colors to color the players/minimap?

TEAM_COLORS = {}                        -- If USE_CUSTOM_TEAM_COLORS is set, use these colors.
TEAM_COLORS[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }  --    Teal
TEAM_COLORS[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }   --    Yellow
TEAM_COLORS[DOTA_TEAM_CUSTOM_1] = { 197, 77, 168 }  --    Pink
TEAM_COLORS[DOTA_TEAM_CUSTOM_2] = { 255, 108, 0 }   --    Orange
TEAM_COLORS[DOTA_TEAM_CUSTOM_3] = { 52, 85, 255 }   --    Blue
TEAM_COLORS[DOTA_TEAM_CUSTOM_4] = { 101, 212, 19 }  --    Green
TEAM_COLORS[DOTA_TEAM_CUSTOM_5] = { 129, 83, 54 }   --    Brown
TEAM_COLORS[DOTA_TEAM_CUSTOM_6] = { 27, 192, 216 }  --    Cyan
TEAM_COLORS[DOTA_TEAM_CUSTOM_7] = { 199, 228, 13 }  --    Olive
TEAM_COLORS[DOTA_TEAM_CUSTOM_8] = { 140, 42, 244 }  --    Purple

-- Surrender Options
SURRENDER_MINIMUM_KILLS_BEHIND = 50
SURRENDER_REQUIRED_YES_VOTES = {1, 2, 2, 3, 4}
SURRENDER_TIME_TO_DISPLAY = 10

USE_AUTOMATIC_PLAYERS_PER_TEAM = false   -- Should we set the number of players to 10 / MAX_NUMBER_OF_TEAMS?

CUSTOM_TEAM_PLAYER_COUNT = {}           -- If we're not automatically setting the number of players per team, use this table

if GetMapName() == "10v10" then
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 10
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 10
else
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 5
end

-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_1] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_2] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_3] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_4] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_5] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_6] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_7] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_8] = 1
