-- class for xpm handler
modifier_xpm_thinker = class( {} )

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
		-- since the game actually starts at non-0 dota time, we'll need to set the baseline
		-- to when this thing is created
		self.baseTime = GameRules:GetDOTATime( true, true )

		-- start thinking every 5 seconds
		self:StartIntervalThink( 5.0 )
	end
end
--------------------------------------------------------------------------------

function modifier_xpm_thinker:OnIntervalThink()
	if IsServer() then
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
		local gameTime = ( GameRules:GetDOTATime( true, true ) - self.baseTime ) / 5.0
		local a = 15
		local b = 103
		local c = 116401
		local divisor = 5760 * 20 -- this isn't any different from adding a 0 but it's more future proof

		local value = ( ( a * gameTime * gameTime ) + ( b * gameTime ) + c ) / divisor

		-- quick and dirty rounding
		value = math.floor( value + 0.5 )

		return value
	end
end
