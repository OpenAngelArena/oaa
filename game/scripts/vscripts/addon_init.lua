-- Load Base Classes

require("abilities/baseclass")
require("items/baseclass")
require("modifiers/baseclass")
require("modifiers/aura_baseclass")

require("items/transformation/baseclass")
if IsClient() then -- Load clientside utility lib
  require("libraries/basenpc")
end
