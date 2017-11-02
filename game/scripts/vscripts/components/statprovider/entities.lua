
if EntityStatProvider == nil then
  Debug.EnabledModules['statprovider:entities'] = false
  DebugPrint ( 'Creating new EntityStatProvider object.' )
  EntityStatProvider = class({})
end

function EntityStatProvider:Init()
  CustomGameEventManager:RegisterListener("statprovider_entities_request", Dynamic_Wrap(self, "EventHandler"))
end

function EntityStatProvider:EventHandler(keys)
  local entity = keys.entity
  local handle = EntIndexToHScript(entity)

  if not handle then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = 0,
      ManaRegen = 0
    })
    return
  end

  if not handle.GetManaRegen then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = 0,
      ManaRegen = 0
    })
    return
  end

  print(handle:GetClassname())
  print(handle:GetDebugName())

  CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
    HealthRegen = handle:GetHealthRegen(),
    ManaRegen = handle:GetManaRegen()
  })
end
