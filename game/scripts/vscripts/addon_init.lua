-- Load Base Classes

require("abilities/baseclass")
require("items/baseclass")
require("modifiers/baseclass")
--require("modifiers/aura_baseclass")
--require("items/transformation/baseclass")

-- Link modifiers that don't have an ability
require("linker")

if IsClient() then -- Load clientside utility lib
  require("libraries/basenpc")
end
require("libraries/abilities")
