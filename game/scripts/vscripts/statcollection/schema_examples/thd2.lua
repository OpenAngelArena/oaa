customSchema = class({})

function customSchema:init()

    -- Check the schema_examples folder for different implementations

    -- Flag Example
    statCollection:setFlags({ version = "1.0" })

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
    --game.rs = GetRoshanKills() -- This is an example of a function that returns how many times roshan was killed
    return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
    local players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then

                local hero = PlayerResource:GetSelectedHeroEntity(playerID)

                local teamname = "Moriya Shrine"
                if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                    teamname = "Hakurei Shrine"
                end

                local item0 = hero:GetItemInSlot(0)
                local item1 = hero:GetItemInSlot(1)
                local item2 = hero:GetItemInSlot(2)
                local item3 = hero:GetItemInSlot(3)
                local item4 = hero:GetItemInSlot(4)
                local item5 = hero:GetItemInSlot(5)

                local itemName0 = ""
                local itemName1 = ""
                local itemName2 = ""
                local itemName3 = ""
                local itemName4 = ""
                local itemName5 = ""

                if item0 then
                    itemName0 = item0:GetAbilityName()
                end
                if item1 then
                    itemName1 = item1:GetAbilityName()
                end
                if item2 then
                    itemName2 = item2:GetAbilityName()
                end
                if item3 then
                    itemName3 = item3:GetAbilityName()
                end
                if item4 then
                    itemName4 = item4:GetAbilityName()
                end
                if item5 then
                    itemName5 = item5:GetAbilityName()
                end

                local ability1 = hero:GetAbilityByIndex(0)
                local ability2 = hero:GetAbilityByIndex(1)
                local ability3 = hero:GetAbilityByIndex(2)
                local ability4 = hero:GetAbilityByIndex(3)
                local ability5 = hero:GetAbilityByIndex(4)
                local ability6 = hero:GetAbilityByIndex(5)
                local ability7 = hero:GetAbilityByIndex(6)
                local ability8 = hero:GetAbilityByIndex(7)
                local ability9 = hero:GetAbilityByIndex(8)
                local ability10 = hero:GetAbilityByIndex(9)

                local abilityLevel1 = 0
                local abilityLevel2 = 0
                local abilityLevel3 = 0
                local abilityLevel4 = 0
                local abilityLevel5 = 0
                local abilityLevel6 = 0
                local abilityLevel7 = 0
                local abilityLevel8 = 0
                local abilityLevel9 = 0
                local abilityLevel10 = 0

                if ability1 then
                    abilityLevel1 = ability1:GetLevel()
                end
                if ability2 then
                    abilityLevel2 = ability2:GetLevel()
                end
                if ability3 then
                    abilityLevel3 = ability3:GetLevel()
                end
                if ability4 then
                    abilityLevel4 = ability4:GetLevel()
                end
                if ability5 then
                    abilityLevel5 = ability5:GetLevel()
                end
                if ability6 then
                    abilityLevel6 = ability6:GetLevel()
                end
                if ability7 then
                    abilityLevel7 = ability7:GetLevel()
                end
                if ability8 then
                    abilityLevel8 = ability8:GetLevel()
                end
                if ability9 then
                    abilityLevel9 = ability9:GetLevel()
                end
                if ability10 then
                    abilityLevel10 = ability10:GetLevel()
                end


                table.insert(players, {
                    --steamID32 required in here
                    steamID32 = PlayerResource:GetSteamAccountID(playerID),
                    ph = GetHeroName(playerID), -- Hero name
                    pl = hero:GetLevel(), -- Levels
                    pk = hero:GetKills(), -- Kills
                    pa = hero:GetAssists(), -- Assists
                    pd = hero:GetDeaths(), -- Deaths
                    pg = hero:GetGold(), -- Now gold
                    dn = hero:GetDenies(), -- Denies
                    lh = hero:GetLastHits(), -- Lasthit
                    sa = math.floor(PlayerResource:GetStuns(playerID)), -- StunAmount
                    sb = PlayerResource:GetGoldSpentOnBuybacks(playerID), -- Gold spent buy backs
                    sc = PlayerResource:GetGoldSpentOnConsumables(playerID), -- Gold spent on consumables
                    si = PlayerResource:GetGoldSpentOnItems(playerID), -- Gold spent on items
                    ss = PlayerResource:GetGoldSpentOnSupport(playerID), -- Gold spent on support
                    pc = PlayerResource:GetNumConsumablesPurchased(playerID), -- Num consumables purchased
                    pi = PlayerResource:GetNumItemsPurchased(playerID), -- Num items purchased
                    eg = PlayerResource:GetTotalEarnedGold(playerID), -- Total earned gold
                    ex = hero:GetCurrentXP(), -- Total earned xp
                    nw = GetNetworth(hero), -- Networth
                    i1 = itemName0,
                    i2 = itemName1,
                    i3 = itemName2,
                    i4 = itemName3,
                    i5 = itemName4,
                    i6 = itemName5,
                    al1 = abilityLevel1,
                    al2 = abilityLevel2,
                    al3 = abilityLevel3,
                    al4 = abilityLevel4,
                    al5 = abilityLevel5,
                    al6 = abilityLevel6,
                    al7 = abilityLevel7,
                    al8 = abilityLevel8,
                    al9 = abilityLevel9,
                    al10 = abilityLevel10,
                    pt = teamname, -- Team name
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

--NOTE THAT THIS FUNCTION RELIES ON YOUR npc_items_custom.txt
--having "ID" properly set to unique values (within your mod)
function GetItemNameList(hero)
    --Create a table of items for the hero
    --Order that table to remove the impact of slot order
    --Concatonate the table into a single string
    local item
    local itemID
    local itemTable = {}
    local itemList

    for i = 0, 5 do
        item = hero:GetItemInSlot(i)
        if item then
            itemID = item:GetAbilityName()
            itemID = string.gsub(itemID, "item_", "")
            if itemID then
                table.insert(itemTable, itemID)
            end
        end
    end

    table.sort(itemTable)
    itemList = table.concat(itemTable, ",")

    return itemList
end

function GetAbilityNameList(hero)
    local abilityName
    local abilityData = {}
    local abilityCount = 0
    while abilityCount < 16 do
        local ab = hero:GetAbilityByIndex(abilityCount)

        if IsValidEntity(ab) then
            abilityName = ab:GetAbilityName()
            table.insert(abilityData, abilityName)
        end

        abilityCount = abilityCount + 1
    end

    table.sort(abilityData)
    local abilityNameList = table.concat(abilityData, ",")
    return abilityNameList
end