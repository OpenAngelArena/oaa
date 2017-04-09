
if ZoneCleaner  == nil then
  Debug.EnabledModules['zonecontrol:cleaner'] = true
  DebugPrint('Creating ZoneCleaner')
  ZoneCleaner = class({})
end

ZoneCleaner.ForbiddenEntities = {

}

function ZoneCleaner:CleanZone(state)
  DebugPrint('Cleaning Zone')
  DebugDrawBox(state.origin, state.bounds.Mins, state.bounds.Maxs, 255, 100, 0, 0, 10)

  for _,v in ipairs(ZoneCleaner.ForbiddenEntities) do
    local entities = FindAllByName(v) --TableConcat(entities, )
    for _,v in ipairs(entities) do
      if InArea(v.GetAbsOrigin(), state.bounds.Mins, state.bounds.Maxs) then
        DebugPrintTable(v)
        v:RemoveSelf()
      end
    end
  end


end

function ZoneCleaner:CleanZones (states)
  DebugPrint('Cleaning multiple Zones')


end

function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function InArea (vector, min, max)
  -- body...
end
