customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Flag Example
    statCollection:setFlags({ version = GetVersion() })

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
end

-------------------------------------
function customSchema:submitRound(args)
    winners = BuildRoundWinnerArray()
    game = BuildGameArray()
    players = BuildPlayersArray()

    statCollection:sendCustom({ game = game, players = players })

    return { winners = winners, lastRound = false }
end

-------------------------------------
function BuildRoundWinnerArray()
    local winners = {}
    local current_winner_team = GameRules.Winner or 0
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
            end
        end
    end
    return winners
end

-- Returns a table with our custom game tracking.
function BuildGameArray()
    local game = {}
    game.rnd = GameMode.nCurrentRound -- Current Round
    game.ch = GameMode.livesUsed -- Chances Used
    game.dth = GameMode.nDeaths -- Total ninja deaths
    game.the = GetTheme() -- Game Theme (can be 0,1 or "yes", "no")
    return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)

                table.insert(players, {
                    --steamID32 required in here
                    steamID32 = PlayerResource:GetSteamAccountID(playerID),

                    -- Example functions of generic stats (keep, delete or change any that you don't need)
                    ph = GetHeroName(playerID), --Hero by its short name
                    lvl = hero:GetLevel(), --Return the level of the hero
                    pd = hero:GetDeaths(), --Number of deaths of this players hero
                    nt = GetNetworth(hero), --Sum of hero gold and item worth

                    -- Item List
                    il = GetItemList(hero),

                    -- Ability List
                    an1 = GetAbilityName(hero, 0), --ability 1 (name) -- shows us the total selection and winrate of each skill, broken into SB and Normal theme
                    al1 = GetAbilityNameLevel(hero, 0), --ability 1 (name + level) -- shows us the final level and its winrate of each skill, broken into SB and Normal theme

                    an2 = GetAbilityName(hero, 1), --ability 2 (name)
                    al2 = GetAbilityNameLevel(hero, 1), --ability 2 (name + level)

                    an3 = GetAbilityName(hero, 2), --ability 3 (name)
                    al3 = GetAbilityNameLevel(hero, 2), --ability 3 (name + level)

                    an4 = GetAbilityName(hero, 3), --ability 4 (name)
                    al4 = GetAbilityNameLevel(hero, 3), --ability 4 (name + level)

                    -- SNS Specific
                    scr = hero.score, --Save-to-death ratio
                })
            end
        end
    end

    return players
end

-------------------------------------
-- Stat Functions         --
-------------------------------------
function PrintSchema(gameArray, playerArray)
    print("-------- GAME DATA --------")
    DeepPrintTable(gameArray)
    print("\n-------- PLAYER DATA --------")
    DeepPrintTable(playerArray)
    print("-------------------------------------")
end

function GetHeroName(playerID)
    local heroName = PlayerResource:GetSelectedHeroName(playerID)
    heroName = string.gsub(heroName, "npc_dota_hero_", "") --Cuts the npc_dota_hero_ prefix
    return heroName
end

function GetNetworth(hero)
    local gold = hero:GetGold()

    -- Iterate over item slots adding up its gold cost
    for i = 0, 15 do
        local item = hero:GetItemInSlot(i)
        if item then
            gold = gold + item:GetCost()
        end
    end
    return gold
end

function GetItemName(hero, slot)
    local item = hero:GetItemInSlot(slot)
    if item then
        local itemName = item:GetAbilityName()
        print(itemName)
        return itemName
    else
        return ""
    end
end

function GetItemList(hero)
    local itemTable = {}
    for i = 0, 5 do
        local item = hero:GetItemInSlot(i)
        if item then
            local itemName = string.gsub(item:GetAbilityName(), "item_", "")
            table.insert(itemTable, itemName)
        end
    end
    table.sort(itemTable)
    local itemList = table.concat(itemTable, ",")
    return itemList
end

function GetAbilityName(hero, id)
    local ability = hero:GetAbilityByIndex(id)
    if ability then
        local abilityName = string.gsub(ability:GetAbilityName(), "antimage_", "") --remove unnecessary parts of string
        abilityName = string.gsub(ability:GetAbilityName(), "spongebob_", "sb_") --remove unnecessary parts of string
        return abilityName
    end
    return ""
end

function GetAbilityNameList(hero)
    local nameTable = {}
    for i = 0, 3 do
        table.insert(nameTable, GetAbilityName(hero, i))
    end
    return table.concat(nameTable, ",")
end

function GetAbilityLevel(hero, id)
    ability = hero:GetAbilityByIndex(id)
    if ability then
        return ability:GetLevel()
    end
    return 0
end

function GetAbilityLevelList(hero)
    local nameTable = {}
    for i = 0, 3 do
        table.insert(nameTable, GetAbilityLevel(hero, i))
    end
    return table.concat(nameTable, ",")
end

function GetAbilityNameLevel(hero, id)
    return GetAbilityName(hero, id) .. "__" .. GetAbilityLevel(hero, id)
end

function GetTheme()
    local theme = GameMode.gameTheme
    if theme == 1 then
        return "Normal"
    elseif theme == 2 then
        return "SpongeBob"
    end
    return "Unknown"
end