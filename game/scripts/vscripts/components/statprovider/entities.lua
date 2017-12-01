
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

  if not handle then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = 0,
      ManaRegen = 0
    })
    table.insert(EntityStatProvider.activeEntities, tostring(entity))
    return
  end

  if not handle.GetManaRegen then
    CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
      HealthRegen = handle:GetHealthRegen(),
      ManaRegen = 0
    })
    table.insert(EntityStatProvider.activeEntities, tostring(entity))
    return
  end

  CustomNetTables:SetTableValue("entity_stats", tostring(entity), {
    HealthRegen = handle:GetHealthRegen(),
    ManaRegen = handle:GetManaRegen()
  })
  table.insert(EntityStatProvider.activeEntities, tostring(entity))
end

function EntityStatProvider:CollectGarbage()
  for _,entity in pairs(self.activeEntities) do
    local handle = EntIndexToHScript(entity)
    if not IsValidEntity(handle) then
      CustomNetTables:SetTableValue("entity_stats", tostring(entity), nil)
    end
  end
end
