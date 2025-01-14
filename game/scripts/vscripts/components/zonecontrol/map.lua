
MapControl = Components:Register('MapControl', COMPONENT_STRATEGY)

function MapControl:Init ()
  if GetMapName() == "oaa_legacy" or GetMapName() == "tinymode" or GetMapName() == "oaa_alternate" then
    return
  end
  ZoneControl:CreateZone('map_border_n', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {}
  })
  ZoneControl:CreateZone('map_border_s', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {}
  })
  ZoneControl:CreateZone('map_border_e', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {}
  })
  ZoneControl:CreateZone('map_border_w', {
    mode = ZONE_CONTROL_INCLUSIVE,
    players = {}
  })
end
