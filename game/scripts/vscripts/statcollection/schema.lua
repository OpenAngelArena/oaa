customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Listen for changes in the current state
    ListenToGameEvent('game_rules_state_change', function(keys)
        local state = GameRules:State_Get()

        -- Send custom stats when the game ends
        if state == DOTA_GAMERULES_STATE_POST_GAME then

            -- Build game array
            local game = BuildGameArray()

            -- Build players array
            local players = BuildPlayersArray()

            -- Print the schema data to the console
            if statCollection.TESTING then
                PrintSchema(game, players)
            end

            -- Send custom stats
            if statCollection.HAS_SCHEMA then
                statCollection:sendCustom({ game = game, players = players })
            end
        end
    end, nil)

    -- Write 'test_schema' on the console to test your current functions instead of having to end the game
    if Convars:GetBool('developer') then
        Convars:RegisterCommand("test_schema", function() PrintSchema(BuildGameArray(), BuildPlayersArray()) end, "Test the custom schema arrays", 0)
        Convars:RegisterCommand("test_end_game", function() GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) end, "Test the end game", 0)
    end
end

-------------------------------------

-- In the statcollection/lib/utilities.lua, you'll find many useful functions to build your schema.
-- You are also encouraged to call your custom mod-specific functions

-- Returns a table with our custom game tracking.
function BuildGameArray()
  local game = {
    gl = math.floor(HudTimer:GetGameTime() or 0), -- Game length, from the horn sound, in seconds
    wt = GAME_WINNER_TEAM, -- Winning team

    -- Score stats
    sl = PointsManager:GetLimit(), -- Score limit
    st1 = PointsManager:GetPoints(DOTA_TEAM_GOODGUYS), -- score team 1
    st2 = PointsManager:GetPoints(DOTA_TEAM_BADGUYS), -- score team 2

    -- Cave Stats
    cct1 = 0,
    cct2 = 0,
  }

  return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)
                if hero then
                  table.insert(players, {
                      -- steamID32 required in here
                      steamID32 = PlayerResource:GetSteamAccountID(playerID),

                      -- Example functions for generic stats are defined in statcollection/lib/utilities.lua
                      -- Add player values here as someValue = GetSomePlayerValue(),
                      ph = GetHeroName(playerID), --Hero by its short name
                      pk = hero:GetKills(), --Number of kills of this players hero
                      pd = hero:GetDeaths(), --Number of deaths of this players hero
                      pl = hero:GetLevel(), --Player Levels
                      nt = GetNetworth(hero), --Sum of hero gold and item worth

                      -- Item List
                      il = GetItemList(hero),

                      -- Bottel Count
                      bc = BottleCounter:GetBottles(playerID)
                  })
                end
            end
        end
    end

    return players
end

-- Prints the custom schema, required to get an schemaID
function PrintSchema(gameArray, playerArray)
    print("-------- GAME DATA --------")
    DeepPrintTable(gameArray)
    print("\n-------- PLAYER DATA --------")
    DeepPrintTable(playerArray)
    print("-------------------------------------")
end

-------------------------------------

-- If your gamemode is round-based, you can use statCollection:submitRound(bLastRound) at any point of your main game logic code to send a round
-- If you intend to send rounds, make sure your settings.kv has the 'HAS_ROUNDS' set to true. Each round will send the game and player arrays defined earlier
-- The round number is incremented internally, lastRound can be marked to notify that the game ended properly
function customSchema:submitRound()

    local winners = BuildRoundWinnerArray()
    local game = BuildGameArray()
    local players = BuildPlayersArray()

    statCollection:sendCustom({ game = game, players = players })
end

-- A list of players marking who won this round
function BuildRoundWinnerArray()
    local winners = {}
    local current_winner_team = GameRules.Winner or 0 --You'll need to provide your own way of determining which team won the round
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
            end
        end
    end
    return winners
end

-------------------------------------
