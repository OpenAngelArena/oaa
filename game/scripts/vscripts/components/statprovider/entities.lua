
if EntityStatProvider == nil then
  Debug.EnabledModules['statprovider:entities'] = false
  DebugPrint ( 'Creating new EntityStatProvider object.' )
  EntityStatProvider = class({})
end

function EntityStatProvider:Init()
  CustomGameEventManager:RegisterListener("statprovider_entities_request", Dynamic_Wrap(self, "EventHandler"))

  self.activeEntities = {}

  Timers:CreateTimer(function ()
    self:CollectGarbage()
    return 300
  end)
end

function EntityStatProvider:EventHandler(keys)
  local entity = keys.entity
  local handle = EntIndexToHScript(entity)
  EntityStatProvider.activeEntities[entity] = handle

  if not handle then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = 0,
      ManaRegen = 0
    })
    return
  end

  if not handle.GetManaRegen then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = handle:GetHealthRegen(),
      ManaRegen = 0
    })
    return
  end

  CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
    HealthRegen = handle:GetHealthRegen(),
    ManaRegen = handle:GetManaRegen()
  })
end

function EntityStatProvider:CollectGarbage()
  for entity,handle in pairs(self.activeEntities) do
    if not IsValidEntity(handle) then
      CustomNetTables:SetTableValue("entity_stats", tostring(entity), nil)
      self.activeEntities[entity] = nil
    end
  end
end
