
Runes = Runes or class({})

function Runes:Init()
  --Debug.EnableDebugging()
  --DebugPrint('Init runes module')
  if self.initialized then
    print("Runes were already initialized and there was an attempt to initialize it again -> preventing")
    return nil
  end

  -- Check every 0.5 second if there is a rune spawned before the first duel, if yes remove it
  Timers:CreateTimer(function()
    if HudTimer and HudTimer:GetGameTime() then
      if HudTimer:GetGameTime() < -1 then
        Runes:RemoveAllRunes()
        return 0.5
      end
    else
      return 0.5
    end
  end)

  -- Configuring rune spawn time would be easy if RuneSpawn filter actually worked, just return false in filter if the time isn't right
  --FilterManager:AddFilter(FilterManager.RuneSpawn, self, Dynamic_Wrap(Runes, "RunesSpawnFilter"))

  -- dota_item_rune entities are some special entities, they are not items or npcs !!!
  -- GetName() works on rune entities but returns nothing, thanks Valve
  -- with GetModelName() you can find out what rune it is (model names can be found in assets browser)
  -- GetOrigin() and SetOrigin() work on rune entities, at least something
  -- Spawning rune entity with SpawnEntityFromTableSynchronous("dota_item_rune", { model = "", origin =}) works partially only for double damage
  -- Nobody knows what parameters should be used in the table for SpawnEntityFromTableSynchronous
  self.initialized = true
end

function Runes:RemoveAllRunes()
  local all_runes = Entities:FindAllByClassname("dota_item_rune")
  for _,rune in pairs(all_runes) do
    if rune and not rune:IsNull() then
      UTIL_Remove(rune)
    end
  end
end
