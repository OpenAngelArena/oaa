-- Though we shouldn't encounter a case where this gets initialized twice, don't allow it to happen anyway
if (D2CustomLogging == nil) then
    D2CustomLogging = {
        -- TODO: Make this validate based on what kind of game is being launched if there is an care on not logging dev games
        --[[
            @var bool isEnabled - State true if logging is to be enabled
        ]]--
        isEnabled = true,

        --[[
            @var string gameClientVersion - The string game client version detected when the game started up
        ]]--
        gameClientVersion = CLIENT_VERSION,

        --[[
            @var string gameModeVersion - The string game version detected when the game started up
        ]]--
        gameModeVersion = GAME_VERSION,

        --[[
            @var string gameUID - The string game UID detected when the game started up
        ]]--
        gameUID = '',

        -- TODO: Determine these!
        --[[
            @const int LOG_ENDPOINT_HOSTNAME - The hostname to send the payload to
        ]]--
        LOG_ENDPOINT_HOSTNAME = '',
        --[[
            @const int LOG_ENDPOINT_PATHNAME - The pathname to seek to on the hostname when sending the request
        ]]--
        LOG_ENDPOINT_PATHNAME = '',

        -- TODO: Are there more levels needed from this?
        --[[
            @const int LOG_LEVEL_INVALID - The logging level UID of an invalid or not implemented logging level
        ]]--
        LOG_LEVEL_INVALID = -1,

        --[[
            @const int LOG_LEVEL_INFO - The logging level UID of an informational request
        ]]--
        LOG_LEVEL_INFO = 0,

        --[[
            @const int LOG_LEVEL_STATUS - The logging level UID of a system status request
        ]]--
        LOG_LEVEL_STATUS = 1,

        --[[
            @const int LOG_LEVEL_SYNC - The logging level UID of a syncronization event request
        ]]--
        LOG_LEVEL_SYNC = 2,

        --[[
            @const int LOG_LEVEL_EXCEPTION - The logging level UID of a system exception (Caught)
        ]]--
        LOG_LEVEL_EXCEPTION = 3,

        --[[
            @const int LOG_LEVEL_ERROR - The logging level UID of an error (Uncaught)
        ]]--
        LOG_LEVEL_ERROR = 4,

        --[[
            @const int LOG_LEVEL_FATAL - The logging level UID of a fatal crash (Caught)
        ]]--
        LOG_LEVEL_FATAL = 5
    }

    -- If external logging is disabled, ONLY PRINT THIS ONCE!
    if (not (D2CustomLogging.isEnabled)) then
        print('[D2CustomLogging] Logging to server is disabled for this game')
    end

    --[[
        Sends a payload to the reporting server

        @param int eventSeverity       - The integer event severity
        @param string eventDescription - The string description for this event
        @param table eventPayload      - The table payload of additional data to sent to the server

        @return void
    ]]--
    function D2CustomLogging:sendPayloadForTracking(...)
        -- Bail early if the logging is disabled, allowing existing calls to omit needing a check (They assume we just handle things for them)
        if ((not (D2CustomLogging.isEnabled)) or (not (LOGGLY_ACCOUNT_ID))) then
            return
        end

        local args = {...}

        local eventSeverity    = args[1]
        local eventDescription = args[2]
        local eventPayload     = args[3]

        -- Validate that the event severity is within the defined values we maintain on the internal version
        if (
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_INFO))      and
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_STATUS))    and
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_SYNC))      and
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_EXCEPTION)) and
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_ERROR))     and
            (not (eventSeverity == D2CustomLogging.LOG_LEVEL_FATAL))
        ) then
            print('Correcting invalid logging level')

            eventSeverity = D2CustomLogging.LOG_LEVEL_INVALID
        end

        -- Validate the event name is actually a string and meets out maximum length requirement
        if (not (type(eventDescription) == 'string')) then
            -- TODO: Determine how this should be handled.  This is NOT valid and MUST be corrected before the request can be sent successfully
            print('Event Description was not a string!  Rejecting request to server')

            return
        elseif (string.len(eventDescription) > 200) then
            -- TODO: Should this be a rejection on the event?
            print('Correcting Event Description length')

            eventDescription = string.sub(eventDescription, 197)..'...'
        end

        -- Event payload is optional and can safely be assigned to a default if no value is provided
        if (not (type(eventPayload) == 'table')) then
            eventPayload = {}
        end

        -- Anything above an error needs to include a stack automatically
        if (
            (eventSeverity == D2CustomLogging.LOG_LEVEL_EXCEPTION) or
            (eventSeverity == D2CustomLogging.LOG_LEVEL_ERROR) or
            (eventSeverity == D2CustomLogging.LOG_LEVEL_FATAL)
        ) then
            eventPayload.__STACK = debug.traceback()
        end

        -- Start the HTTP request
        -- For the moment, just hardcode the Loggly URI construction.  This will likely be a module that will be loaded at a later date
        local requestClient = CreateHTTPRequestScriptVM('POST', 'https://logs-01.loggly.com/inputs/' .. LOGGLY_ACCOUNT_ID .. '/tag/http/')
        -- local encodedPayload = json.encode(payload)

        -- For Loggly, send all fields as separate entities WILL be replaced with a more mutable system later on
        requestClient:SetHTTPRequestGetOrPostParameter('eventSeverity', json.encode(eventSeverity))
        requestClient:SetHTTPRequestGetOrPostParameter('eventDescription', eventDescription)
        for name,value in pairs(eventPayload) do
            if (type(value) == 'string') then
                requestClient:SetHTTPRequestGetOrPostParameter(name, value)
            else
                requestClient:SetHTTPRequestGetOrPostParameter(name, json.encode(value))
            end
        end

        -- Dispatch the request
        requestClient:Send(function(response)
            -- V0 only sends exceptions, so we don't care if we have a response, we only care that we actually got something out, if at all possible
        end)

        return
    end
end
