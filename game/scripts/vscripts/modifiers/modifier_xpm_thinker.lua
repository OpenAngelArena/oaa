-- class for xpm handler
modifier_xpm_thinker = class( {} )

local XPM_TICK_INTERVAL = 5.0
--------------------------------------------------------------------------------

function modifier_xpm_thinker:IsPurgable()
  return false
end

function modifier_xpm_thinker:IsPermanent()
  return true
end

--------------------------------------------------------------------------------

function modifier_xpm_thinker:OnCreated( event )
  if IsServer() then
    -- start thinking every 5 seconds
    self:StartIntervalThink( XPM_TICK_INTERVAL )
  end
end
--------------------------------------------------------------------------------

function modifier_xpm_thinker:OnIntervalThink()
  if IsServer() then
    if Duels:IsActive() then
      return
    end
    --print( "xpm think" )
    -- iterate through all possible players
    for playerID = 0, DOTA_MAX_PLAYERS do
      -- make sure player is valid
      if PlayerResource:IsValidPlayerID( playerID ) and not PlayerResource:IsBroadcaster( playerID ) then
        -- grab player hero
        local hero = PlayerResource:GetSelectedHeroEntity( playerID )

        if hero then
          -- give hero xp
          local xp = self:GetXPMForPlayer( playerID )
          --print( "giving hero " .. hero:GetUnitName() .. " " .. xp .. " xp" )
          hero:AddExperience( xp, DOTA_ModifyXP_Unspecified, false, true )
        end
      end
    end
  end
end
--------------------------------------------------------------------------------

-- function for determining the amount of xp given each tick
function modifier_xpm_thinker:GetXPMForPlayer( playerID )
  if IsServer() then
    local time = HudTimer:GetGameTime()
    if time and time > 0 then
      local gameTime = math.floor(time/XPM_TICK_INTERVAL);
      local a = 3
      local b = 35
      local c = 28817
      local divisor = 1152
      local percent = 20

      local value = ( ( a * gameTime * gameTime ) + ( b * gameTime ) + c ) * (percent / 100) / divisor

      -- quick and dirty rounding
      value = math.floor( value + 0.5 )

      return value
    else
      return 0
    end

  end
end
