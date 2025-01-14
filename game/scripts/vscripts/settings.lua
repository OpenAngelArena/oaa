-- In this file you can set up all the properties and settings for your game mode.

-----------------------------------------------------------------------------------
-- General globals

DOTA_TEAM_SPECTATOR = 1
MANUAL_GARBAGE_CLEANING_TIME = 6

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
NORMAL_KILL_LIMIT = 3                     -- Starting KILL_LIMIT = 16 + NORMAL_KILL_LIMIT x number of players: 5v5 - 46; 4v4 - 40; 3v3 - 34; 2v2 - 28; 1v1 - 22;
ONE_V_ONE_KILL_LIMIT = 3                  -- Starting KILL_LIMIT = 14 + ONE_V_ONE_KILL_LIMIT x number of players: 1v1 - 20; 2v2 - 26; 3v3 - 32; 4v4 - 38; solo - 17;
TEN_V_TEN_KILL_LIMIT = 4                  -- Starting KILL_LIMIT = 10 + TEN_V_TEN_KILL_LIMIT x number of players: 6v6 - 58; 8v8 - 74; 10v10 - 90;
KILL_LIMIT_INCREASE = 1                   -- Extend amount = KILL_LIMIT_INCREASE x number of players: 5v5 - 10; 4v4 - 8;
TEN_V_TEN_LIMIT_INCREASE = 1              -- Extend amount = TEN_V_TEN_LIMIT_INCREASE x number of players: 10v10 - 20; 8v8 - 16; 6v6 - 12;
ONE_V_ONE_LIMIT_INCREASE = 2              -- Extend amount = min(ONE_V_ONE_LIMIT_INCREASE x number of players, 6): 1v1 - 4; 2v2 - 6; 3v3 - 6; 4v4 - 6; solo - 2;
LIMIT_INCREASE_STARTING_COOLDOWN = 60 * 8 -- same as DUEL_INTERVAL so the extension shrine becomes active before the duel

-- poop wards
POOP_WARD_DURATION = 360
POOP_WARD_DURATION_SENTRY = 180
POOP_WARD_COOLDOWN = 240
POOP_WARD_RADIUS = 250

-- scan reveal
SCAN_REVEAL_COOLDOWN = 60
SCAN_REVEAL_RADIUS = 900
SCAN_REVEAL_DURATION = 14                 -- dust duration is 12 seconds
SCAN_DURATION = 14                        -- vanilla duration is 8 seconds

-- glyph
GLYPH_COOLDOWN = 120
GLYPH_DURATION = 10
GLYPH_INTERVAL = 1

-- PICK SCREEN
CAPTAINS_MODE_CAPTAIN_TIME = 20           -- how long players have to claim the captain chair
CAPTAINS_MODE_PICK_BAN_TIME = 30          -- how long you have to do each pick/ban
CAPTAINS_MODE_HERO_PICK_TIME = 45         -- time to choose which hero you're going to play
CAPTAINS_MODE_RESERVE_TIME = 130          -- total bonus time that can be used throughout any selection
CAPTAINS_MODE_TOTAL = CAPTAINS_MODE_CAPTAIN_TIME + 22*CAPTAINS_MODE_PICK_BAN_TIME + CAPTAINS_MODE_HERO_PICK_TIME + 2*CAPTAINS_MODE_RESERVE_TIME

RANKED_PREGAME_TIME = 0
RANKED_BAN_TIME = 30
RANKED_PICK_TIME = 30
if IsInToolsMode() then
  RANKED_BAN_TIME = 5
  RANKED_PICK_TIME = 5
  CAPTAINS_MODE_CAPTAIN_TIME = 5
  CAPTAINS_MODE_PICK_BAN_TIME = 5
  CAPTAINS_MODE_HERO_PICK_TIME = 5
  CAPTAINS_MODE_RESERVE_TIME = 5
end

-- Game timings
PREGAME_TIME = 35
AP_GAME_TIME = 90

-- Duels
INITIAL_DUEL_DELAY = 35                 -- how long after the clock hits 0 should the initial duel start counting down
DUEL_START_WARN_TIME = 10               -- How many seconds to count down before each duel (added as a delay before the duel starts)
DUEL_START_COUNTDOWN = 5                -- How many seconds to count down before each duel (added as a delay before the duel starts)
DUEL_TIMEOUT = 90                       -- Time before the duel starts counting down to end in a stalemate
FIRST_DUEL_TIMEOUT = 80                 -- Timeout for the level 1 duel at the start of the game
FINAL_DUEL_TIMEOUT = 180                -- Timeout for the final duel, the game cannot end unless this duel completes without timing out
ONE_V_ONE_DUEL_TIMEOUT = 70             -- Timeout for every duel in 1v1 mode
DUEL_END_COUNTDOWN = 10                 -- How many seconds to count down before a duel can timeout (added as a delay before the duel times out)
DUEL_RUNE_TIMER = 30                    -- how long until the highground object becomes active in duels
DUEL_INTERVAL = 480                     -- time from duel ending until next duel countdown begins
ONE_V_ONE_DUEL_INTERVAL = 360           -- time from duel ending until next duel countdown begins in low player count mode
DUEL_START_PROTECTION_TIME = 2          -- duel start protection duration

-- CapturePoints
CAPTURE_POINTS_AND_DUELS_NO_OVERLAP = true -- Changing INITIAL_CAPTURE_POINT_DELAY, ONE_V_ONE_INITIAL_CAPTURE_POINT_DELAY, CAPTURE_INTERVAL, ONE_V_ONE_CAPTURE_INTERVAL will have no effect if this is true
INITIAL_CAPTURE_POINT_DELAY = 660       -- how long after the clock hits 0 should the initial Capture Point start counting down. FIRST_DUEL_TIMEOUT + DUEL_INTERVAL + DUEL_TIMEOUT + 10.
ONE_V_ONE_INITIAL_CAPTURE_POINT_DELAY = 510   -- 2 x ONE_V_ONE_DUEL_TIMEOUT + ONE_V_ONE_DUEL_INTERVAL + 10.
CAPTURE_FIRST_WARN = 60                 -- how many seconds before spawn of capture points the first ping on minimap will show
CAPTURE_SECOND_WARN = 30                -- how many seconds before spawn of capture points the second ping on minimap will show
CAPTURE_START_COUNTDOWN = 5             -- How many seconds to count down before each CapturePoint (added as a delay before the duel starts)
CAPTURE_INTERVAL = 480                  -- time from CapturePoint beginning until next CapturePoint begins. DUEL_INTERVAL.
ONE_V_ONE_CAPTURE_INTERVAL = 360        -- ONE_V_ONE_DUEL_INTERVAL
CAPTURE_LENTGH = 20                     -- amount of time for 1 hero to capture the point (less with more)
CAPTURE_POINT_RADIUS = 300

-- Bosses
BOSS_RESPAWN_TIMER = 180                -- time after boss death before spawning the next tier boss
BOSS_RESPAWN_START = 180                -- time for the first boss spawn
BOSS_LEASH_SIZE = 1200                  -- number of units a boss will walk before starting to head back
BOSS_AGRO_FACTOR = 15                   -- boss must take (tier * n) damage before agro
BOSS_DMG_RED_FOR_PCT_SPELLS = 50        -- boss additional damage reduction against percent damage spells (in %)
BOSS_WANDERER_MIN_SPAWN_TIME = 12       -- min time at which first Wanderer can spawn (in minutes)
BOSS_WANDERER_MAX_SPAWN_TIME = 15       -- max time at which first Wanderer can spawn (in minutes)
BOSS_WANDERER_MIN_RESPAWN_TIME = 4      -- min respawn time of the Wanderer (in minutes)
BOSS_WANDERER_MAX_RESPAWN_TIME = 6      -- min respawn time of the Wanderer (in minutes)
BOSS_WANDERER_BUFF_DURATION = 2.5       -- max duration of the Wanderer buff (in minutes)

-- Creeps
CREEP_SPAWN_INTERVAL = 60               -- number of seconds between each creep spawn
INITIAL_CREEP_DELAY = 1                 -- number of seconds to wait before spawning the first wave of creeps
BOTTLE_DESPAWN_TIME = 60                -- Time until Bottles despawn
CREEP_POWER_MAX = 1.5                   -- the total max power creeps will get stacked up to (1 = 100%)
CREEP_BOUNTY_SHARE_RADIUS = 1500        -- the radius in which creep bounty is shared with allies
CREEP_BOUNTY_SHARE_PERCENT = 40         -- the percentage of the creep's gold bounty that's shared with allies
CREEP_BOUNTY_BONUS_PERCENT_CLEAVE = 0   -- the bonus percentage of the creep's bounty that's given to those that kill with Cleave Spark
CREEP_BOUNTY_BONUS_PERCENT_POWER = 0    -- the bonus percentage of the creep's bounty that's given to those that kill with Power Spark

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

-- Formula for XP on hero kill: (HERO_XP_BOUNTY_BASE + HERO_XP_BOUNTY_STREAK + HERO_XP_BONUS_FACTOR x DyingHeroXP) / number_of_killers
HERO_XP_BOUNTY_BASE = 80             -- 100 in normal dota
HERO_XP_BOUNTY_STREAK_BASE = 30      -- Min amount of streak XP bonus (min streak is 3; lvl * 30 in normal dota)
HERO_XP_BOUNTY_STREAK_INCREASE = 100 -- not used for now
HERO_XP_BOUNTY_STREAK_MAX = 3000     -- Max amount of streak XP bonus (lvl * streak * 10 in normal dota where lvl <= 25)
HERO_XP_BONUS_FACTOR = 0.12          -- Multiplier for the XP of the killed hero (0.13 in normal dota)
HERO_XP_BOUNTY_PER_HERO_LVL = 20     -- Multiplier for the lvl of the killed hero (not in normal dota)
HERO_KILL_XP_RADIUS = 1500           -- XP range for killing heroes (1500 in normal dota)
HERO_KILL_GOLD_RADIUS = 1500         -- Gold assist range for killing heroes (1500 in normal dota)
HERO_DYING_STREAK_MAX = 5            -- After how many deaths, hero stops giving bonus xp to the killer

-- Runes
USE_DEFAULT_RUNE_SYSTEM = false      -- Should we use the default dota rune spawn timings and the same runes as dota have?
-- Bounty Runes
FIRST_BOUNTY_RUNE_SPAWN_TIME = 0     -- After what delay in seconds will the first bounty rune spawn?
BOUNTY_RUNE_SPAWN_INTERVAL = 180     -- How long in seconds should we wait between bounty rune respawns?
BOUNTY_RUNE_INITIAL_TEAM_GOLD = 16
BOUNTY_RUNE_INITIAL_TEAM_XP = 9
-- Power-up Runes
FIRST_POWER_RUNE_SPAWN_TIME = 120    -- After what delay in seconds will the first power-up rune spawn?
POWER_RUNE_SPAWN_INTERVAL = 120      -- How long in seconds should we wait between power-up runes respawns?

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

CUSTOM_BUYBACK_COST_ENABLED = false      -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = false  -- Should we use a custom buyback time?
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
DISABLE_GOLD_SOUNDS = false             -- Should we disable the gold sound when players get gold?

MAX_LEVEL = 55                          -- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = true             -- Should we use custom XP values to level up heroes, or the default Dota numbers?

-- Fill this table up with the required XP per level if you want to change it
XP_PER_LEVEL_TABLE = {
	0,
	240,
	600,
	1080,
	1680,
	2300,
	2980,
	3730,
	4620,
	5550,
	6520,
	7530,
	8850,
	9800,
	11000,
	12330,
	13630,
	14955,
	16455,
	18000,
	19645,
	21405,
	23600,
	25950,
	28545,
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
SKIP_TEAM_SETUP = false       -- Should we skip the team setup entirely?
ENABLE_AUTO_LAUNCH = true               -- Should we automatically have the game complete team setup after AUTO_LAUNCH_DELAY seconds?
AUTO_LAUNCH_DELAY = 30                  -- How long should the default team selection launch timer be?  The default for custom games is 30.  Setting to 0 will skip team selection.
LOCK_TEAM_SETUP = false                 -- Should we lock the teams initially?  Note that the host can still unlock the teams

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
SURRENDER_MINIMUM_KILLS_BEHIND = 35
SURRENDER_REQUIRED_YES_VOTES = {1, 2, 2, 3, 4}
SURRENDER_TIME_TO_DISPLAY = 10

USE_AUTOMATIC_PLAYERS_PER_TEAM = false   -- Should we set the number of players to 10 / MAX_NUMBER_OF_TEAMS?

CUSTOM_TEAM_PLAYER_COUNT = {}           -- If we're not automatically setting the number of players per team, use this table

if GetMapName() == "10v10" or GetMapName() == "oaa_bigmode" then
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 10
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 10
elseif GetMapName() == "1v1" then
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 1
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 1
elseif GetMapName() == "tinymode" then
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 4
  CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 4
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
