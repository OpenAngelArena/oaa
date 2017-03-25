local statInfo = LoadKeyValues('scripts/vscripts/statcollection/settings.kv')
if not statInfo then
    print("Stat Collection: Critical Error, no settings.kv file found")
    return
end

require("statcollection/schema")
require('statcollection/lib/statcollection')
require('statcollection/staging')
require('statcollection/lib/utilities')

local COLLECT_STATS = not Convars:GetBool('developer')
local TESTING = tobool(statInfo.TESTING)
local MIN_PLAYERS = tonumber(statInfo.MIN_PLAYERS)

if COLLECT_STATS or TESTING then
    ListenToGameEvent('game_rules_state_change', function(keys)
        local state = GameRules:State_Get()

        if state >= DOTA_GAMERULES_STATE_INIT and not statCollection.doneInit then

            if PlayerResource:GetPlayerCount() >= MIN_PLAYERS or TESTING then
                -- Init stat collection
                statCollection:init()
                customSchema:init()
            end
        end
    end, nil)
end