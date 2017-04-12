
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
  "npc_dota_healing_mine",
}

function ZoneCleaner:CleanZone(state)
  --DebugDrawBox(state.origin, state.bounds.Mins, state.bounds.Maxs, 255, 100, 0, 0, 30)
  --DebugDrawSphere(state.origin, Vector(255, 100, 0), 0, max(state.bounds.Maxs.x + state.bounds.Maxs.y, state.bounds.Mins.x + state.bounds.Mins.y), true, 30)

  local entities = Entities:FindAllInSphere(state.origin, max(max(state.bounds.Mins.x, state.bounds.Maxs.x),max(state.bounds.Mins.y, state.bounds.Maxs.y)))

  for _,entity in pairs(entities) do
    for _,entry in pairs(ZoneCleaner.ForbiddenEntities) do
      if not entity:IsNull() then
        if entry == entity:GetName() then
          entity:RemoveSelf()
        end
      end
    end
  end
end
