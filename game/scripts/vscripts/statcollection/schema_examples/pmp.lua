customSchema = class({})

function customSchema:init(options)

    -- Flags
    statCollection:setFlags({ version = GetVersion() })

    -- Listen for changes in the current state
    ListenToGameEvent('game_rules_state_change', function(keys)
        -- Grab the current state
        local state = GameRules:State_Get()

        if state == DOTA_GAMERULES_STATE_POST_GAME then

            -- Build game array
            local game = BuildGameArray()

            -- Build players array
            local players = BuildPlayersArray()

            -- Send custom stats
            statCollection:sendCustom({ game = game, players = players })
        end
    end, nil)
end

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

function BuildGameArray()
    local game = {}
    game.bk = GetBossKilled() --boss_killed
    game.tt = GetTimesTraded() --times_traded
    return game
end

function BuildPlayersArray()
    players = {}
    for playerID = 0, DOTA_MAX_PLAYERS do
        if PlayerResource:IsValidPlayerID(playerID) then
            if not PlayerResource:IsBroadcaster(playerID) then
                local player_upgrades = PMP:GetUpgradeList(playerID)
                table.insert(players, {
                    --steamID32 required in here
                    steamID32 = PlayerResource:GetSteamAccountID(playerID),
                    ph = GetPlayerRace(playerID), --player_hero
                    pk = PlayerResource:GetKills(playerID), --player_kills
                    pd = PlayerResource:GetDeaths(playerID), --player_deaths
                    pl = GetHeroLevel(playerID), --player_level

                    -- Resources
                    tge = GetTotalEarnedGold(playerID), --total_gold_earned
                    tle = GetTotalEarnedLumber(playerID), --total_lumber_earned
                    txe = GetTotalEarnedXP(playerID), --total_xp_earned
                    pf = GetFoodLimit(playerID), --player_food
                    psr = GetSpawnRate(playerID), --player_spawn_rate

                    -- Defensive abilities
                    spu = GetSuperPeonsUsed(playerID), --super_peons_used
                    bu = GetBarricadesUsed(playerID), --barricades_used
                    ru = GetRepairsUsed(playerID), --repairs_used

                    -- Upgrades
                    uw = GetPlayerWeaponLevel(playerID), --upgrade_weapon
                    uh = player_upgrades["helm"] or 0, --upgrade_helm
                    ua = player_upgrades["armor"] or 0, --upgrade_armor
                    uw = player_upgrades["wings"] or 0, --upgrade_wings
                    uhp = player_upgrades["health"] or 0, --upgrade_health

                    -- Passive ability upgrades
                    acs = player_upgrades["critical_strike"] or 0, --ability_critical_strike
                    ash = player_upgrades["stun_hit"] or 0, --ability_stun_hit
                    apw = player_upgrades["poisoned_weapons"] or 0, --ability_poisoned_weapons
                    ar = player_upgrades["racial"] or 0, --ability_racial
                    ad = player_upgrades["dodge"] or 0, --ability_dodge
                    asa = player_upgrades["spiked_armor"] or 0, --ability_spiked_armor

                    -- Hero global upgrades
                    pdmg = player_upgrades["pimp_damage"] or 0, --pimp_damage
                    parm = player_upgrades["pimp_armor"] or 0, --pimp_armor
                    pspd = player_upgrades["pimp_speed"] or 0, --pimp_speed
                    preg = player_upgrades["pimp_regen"] or 0, --pimp_regen
                })
            end
        end
    end

    return players
end

function GetPlayerWeaponLevel(playerID)
    local player_upgrades = PMP:GetUpgradeList(playerID)
    local race = GetPlayerRace(playerID)
    local weapon_level = 0

    if race == "night_elf" then
        weapon_level = player_upgrades["bow"] + player_upgrades["quiver"]
    else
        weapon_level = player_upgrades["weapon"]
    end

    return weapon_level
end