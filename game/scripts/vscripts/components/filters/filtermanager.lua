-- In order to add a filter, call FilterManager:AddFilter(filterType, context, filterFunc)
--filterType is a constant number corresponding to Filters as listed below
--context is the same as hContext in vanilla API Set*Filter
--filterFunc is the same as hFunction in vanilla API Set*Filter

if not FilterManager then
  DebugPrint("Creating FilterManager...")
  FilterManager = class({})
  -- Filter type constants
  FilterManager.AbilityTuningValue = 1
  FilterManager.BountyRunePickup = 2
  FilterManager.Damage = 3
  FilterManager.ExecuteOrder = 4
  FilterManager.ItemAddedtoInventory = 5
  FilterManager.ModifierGained = 6
  FilterManager.ModifyExperience = 7
  FilterManager.ModifyGold = 8
  FilterManager.RuneSpawn = 9
  FilterManager.TrackingProjectile = 10
  FilterManager.NumFilterTypes = 10

  Debug.EnabledModules["filters:*"] = true
end

function FilterManager:Init()
  -- Filter function table
  self.Filters = {}
  for i=1, self.NumFilterTypes do
    self.Filters[i] = {}
  end

  local gameMode = GameRules:GetGameModeEntity()
  gameMode:SetAbilityTuningValueFilter(Dynamic_Wrap(self, "AbilityTuningValueFilter"), self)
  gameMode:SetBountyRunePickupFilter(Dynamic_Wrap(self, "BountyRunePickupFilter"), self)
  gameMode:SetDamageFilter(Dynamic_Wrap(self, "DamageFilter"), self)
  gameMode:SetExecuteOrderFilter(Dynamic_Wrap(self, "ExecuteOrderFilter"), self)
  gameMode:SetItemAddedToInventoryFilter(Dynamic_Wrap(self, "ItemAddedtoInventoryFilter"), self)
  gameMode:SetModifierGainedFilter(Dynamic_Wrap(self, "ModifierGainedFilter"), self)
  gameMode:SetModifyExperienceFilter(Dynamic_Wrap(self, "ModifyExperienceFilter"), self)
  gameMode:SetModifyGoldFilter(Dynamic_Wrap(self, "ModifyGoldFilter"), self)
  gameMode:SetRuneSpawnFilter(Dynamic_Wrap(self, "RuneSpawnFilter"), self)
  gameMode:SetTrackingProjectileFilter(Dynamic_Wrap(self, "TrackingProjectileFilter"), self)
end

function FilterManager:AddFilter(filterType, context, filterFunc)
  table.insert(self.Filters[filterType], {context, filterFunc})
end

function FilterManager.ApplyFilter(keys, context, filterFunc)
  return filterFunc(context, keys)
end

---------------------------------
-- Master filter functions which call filter functions registered through FilterManager:AddFilter

function FilterManager:AbilityTuningValueFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.AbilityTuningValue]))))
end

function FilterManager:BountyRunePickupFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.BountyRunePickup]))))
end

function FilterManager:DamageFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.Damage]))))
end

function FilterManager:ExecuteOrderFilter(keys)
  DebugPrintTable(self.Filters)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.ExecuteOrder]))))
end

function FilterManager:ItemAddedtoInventoryFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.ItemAddedtoInventory]))))
end

function FilterManager:ModifierGainedFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.ModifierGained]))))
end

function FilterManager:ModifyExperienceFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.ModifyExperience]))))
end

function FilterManager:ModifyGoldFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.ModifyGold]))))
end

function FilterManager:RuneSpawnFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.RuneSpawn]))))
end

function FilterManager:TrackingProjectileFilter(keys)
  return reduce(operator.land, true, map(partial(self.ApplyFilter, keys), map(unpack, iter(self.Filters[self.TrackingProjectile]))))
end

---------------------------------
