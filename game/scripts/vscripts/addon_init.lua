-- Load Base Classes

require("abilities/baseclass")
require("items/baseclass")
require("modifiers/baseclass")
require("modifiers/aura_baseclass")

require("items/transformation/baseclass")
if IsClient() then -- Load clientside utility lib
	require("libraries/talents/talents_client")
else
	require("libraries/talents/talents_server")
end

-- Library for not-pure cleave (server-side only)
if IsServer() then
  require("libraries/cleave")
end
