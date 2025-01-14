if ZoneCleaner  == nil then
  Debug.EnabledModules['zonecontrol:cleaner'] = true
  DebugPrint('Creating ZoneCleaner')
  ZoneCleaner = class({})
end

-- https://moddota.com/forums/discussion/92/tutorial-proposal-document-the-baseclasses
ZoneCleaner.ForbiddenEntities = {
  --"npc_dota_observer_wards",
  --"npc_dota_sentry_wards",
  "npc_dota_ward_base",
  "npc_dota_ward_base_truesight",
  --"npc_dota_venomancer_plague_ward_1",
  --"npc_dota_venomancer_plague_ward_2",
  --"npc_dota_venomancer_plague_ward_3",
  --"npc_dota_venomancer_plague_ward_4",
  --"npc_dota_venomancer_plague_ward_5",
  --"npc_dota_venomancer_plague_ward_6",
  "npc_dota_venomancer_plagueward",
  --"npc_dota_techies_land_mine",
  --"npc_dota_techies_remote_mine",
  "npc_dota_techies_mines",
  "npc_dota_techies_minefield_sign",
  "npc_dota_broodmother_web",
  "npc_dota_techies_stasis_trap",
  "npc_dota_templar_assassin_psionic_trap",
  "npc_dota_earth_spirit_stone",
  "npc_dota_ember_spirit_remnant",
  --"npc_dota_treant_eyes",
}

function ZoneCleaner:CleanZone(state)
  -- Calculate zone bounds
  local minX = state.origin.x + state.bounds.Mins.x
  local maxX = state.origin.x + state.bounds.Maxs.x
  local minY = state.origin.y + state.bounds.Mins.y
  local maxY = state.origin.y + state.bounds.Maxs.y

  -- Use a smaller padding for the search radius
  local padding = 200
  local radius = math.max(math.max(math.abs(state.bounds.Mins.x), math.abs(state.bounds.Maxs.x)),
                         math.max(math.abs(state.bounds.Mins.y), math.abs(state.bounds.Maxs.y))) + padding

  local entities = Entities:FindAllInSphere(state.origin, radius)

  for _,entity in pairs(entities) do
    if not entity:IsNull() then
      -- Get entity position
      local pos = entity:GetAbsOrigin()

      -- Only remove if entity is actually inside the zone bounds
      if pos.x >= minX and pos.x <= maxX and
         pos.y >= minY and pos.y <= maxY then
        for _,entry in pairs(self.ForbiddenEntities) do
          if entry == entity:GetName() then
            entity:RemoveSelf()
            break
          end
        end
      end
    end
  end

  -- Calculate minimum radius needed to encompass the entire rectangular arena
  -- Using Pythagorean theorem: radius = sqrt(width^2 + height^2) / 2
  local width = maxX - minX
  local height = maxY - minY
  local treeRadius = math.sqrt(width * width + height * height) / 2
  -- Add small padding to ensure we get trees right at the edges
  treeRadius = treeRadius + 50

  GridNav:DestroyTreesAroundPoint(state.origin, treeRadius, true)
end
