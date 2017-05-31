-- Component for various chat commands useful for testing
-- Majority of original command code by Darklord

DevCheats = class({})

function DevCheats:Init()
  ChatCommand:LinkCommand("-print_modifiers", "PrintModifiers", self)
end

function DevCheats:PrintModifiers(keys)
  local playerID = keys.playerid
  local hero = PlayerResource:GetSelectedHeroEntity(playerID)
  local modifiers = hero:FindAllModifiers()

  local function PrintModifier(modifier)
    print(modifier:GetName())
  end

  foreach(PrintModifier, modifiers)
end
