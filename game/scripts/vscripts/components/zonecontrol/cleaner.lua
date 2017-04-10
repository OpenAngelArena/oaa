
if ZoneCleaner  == nil then
  Debug.EnabledModules['zonecontrol:cleaner'] = true
  DebugPrint('Creating ZoneCleaner')
  ZoneCleaner = class({})
end

ZoneCleaner.ForbiddenEntities = {
  "npc_dota_observer_wards",
  "npc_dota_sentry_wards",
  "npc_dota_venomancer_plague_ward_1",
  "npc_dota_venomancer_plague_ward_2",
  "npc_dota_venomancer_plague_ward_3",
  "npc_dota_venomancer_plague_ward_4",
  "npc_dota_venomancer_plague_ward_5",
  "npc_dota_venomancer_plague_ward_6",
  "npc_dota_techies_land_mine",
  "npc_dota_techies_remote_mine",
  "npc_dota_broodmother_web",
  "npc_dota_techies_stasis_trap",
  "npc_dota_templar_assassin_psionic_trap",
  "npc_dota_earth_spirit_stone",
  "npc_dota_ember_spirit_remnant",
  "npc_dota_healing_mine",
}

function ZoneCleaner:CleanZone(state)
  DebugPrint('Cleaning Zone')
  DebugDrawBox(state.origin, state.bounds.Mins, state.bounds.Maxs, 255, 100, 0, 0, 10)

  for _,entry in pairs(ZoneCleaner.ForbiddenEntities) do
    DebugPrint('Searching for "' .. entry .. '"')
    DebugPrintTable(Entities:FindAllByClassname(entry)) -- WHY DON'T YOU FUCKING FIND THIS SHIT?
    DebugPrintTable(Entities:FindAllByName(entry)) -- I'M EVEN USING THE OTHER FUCKING FUNCTION
    for _,entity in pairs(Entities:FindAllByClassname(entry)) do -- ARE THESE NO ENTITIES OR WHAT?
      DebugPrint('Found ' .. entity:GetClassname())
      if InArea(entity.GetAbsOrigin(), state.origin + state.bounds.Mins, state.origin + state.bounds.Maxs) then
        DebugPrint('Found entity is in zone.')
        DebugPrintTable(entity)
        entity:RemoveSelf()
      end
    end
  end
end

function ZoneCleaner:CleanZones (states)
  DebugPrint('Cleaning multiple Zones')


end

function IsInArea (vector, mins, maxs)
  if IsBetween(vector.x, mins.x, maxs.x) and
     IsBetween(vector.y, mins.y, maxs.z) then
    return true
  end
  return false
end

function IsInBox(vector, mins, maxs)
  if IsBetween(vector.x, mins.x, maxs.x) and
     IsBetween(vector.y, mins.y, maxs.z) and
     IsBetween(vector.z, mins.z, maxs.y) then
    return true
  end
  return false
end

function IsBetween (x, a, b)
  if a > x and x < b or b > x and x < a then
    return true
  end
  return false
end
