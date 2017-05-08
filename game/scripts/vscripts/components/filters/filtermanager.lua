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
  FilterManager.ItemAddedToInventory = 5
  FilterManager.ModifierGained = 6
  FilterManager.ModifyExperience = 7
  FilterManager.ModifyGold = 8
  FilterManager.RuneSpawn = 9
  FilterManager.TrackingProjectile = 10
  FilterManager.NumFilterTypes = 10

  Debug.EnabledModules["filters:*"] = false
end

function FilterManager:Init()
  -- Registered filter function table
  self.Filters = {}
  -- Master filter function table
  self.MasterFilters = {}
  for i=1, self.NumFilterTypes do
    -- Populate self.Filters with empty tables so that AddFilter can table.insert Filter entries
    self.Filters[i] = {}

    -- Generate master filter functions
    local function MasterFilter(this, keys)
      return this:RunFilterForType(keys, i)
    end
    self.MasterFilters[i] = MasterFilter
  end

  local gameMode = GameRules:GetGameModeEntity()
  gameMode:SetAbilityTuningValueFilter(Dynamic_Wrap(self.MasterFilters, self.AbilityTuningValue), self)
  gameMode:SetBountyRunePickupFilter(Dynamic_Wrap(self.MasterFilters, self.BountyRunePickup), self)
  gameMode:SetDamageFilter(Dynamic_Wrap(self.MasterFilters, self.Damage), self)
  gameMode:SetExecuteOrderFilter(Dynamic_Wrap(self.MasterFilters, self.ExecuteOrder), self)
  gameMode:SetItemAddedToInventoryFilter(Dynamic_Wrap(self.MasterFilters, self.ItemAddedToInventory), self)
  gameMode:SetModifierGainedFilter(Dynamic_Wrap(self.MasterFilters, self.ModifierGained), self)
  gameMode:SetModifyExperienceFilter(Dynamic_Wrap(self.MasterFilters, self.ModifyExperience), self)
  gameMode:SetModifyGoldFilter(Dynamic_Wrap(self.MasterFilters, self.ModifyGold), self)
  gameMode:SetRuneSpawnFilter(Dynamic_Wrap(self.MasterFilters, self.RuneSpawn), self)
  gameMode:SetTrackingProjectileFilter(Dynamic_Wrap(self.MasterFilters, self.TrackingProjectile), self)
end

function FilterManager:AddFilter(filterType, context, filterFunc)
  table.insert(self.Filters[filterType], {context, filterFunc})
end

function FilterManager.ApplyFilter(keys, context, filterFunc)
  return filterFunc(context, keys)
end

function FilterManager:CreateFilterIterator(filterType)
  -- create iterator on table and then unpack each entry
  return map(unpack, iter(self.Filters[filterType]))
end

function FilterManager:ApplyFiltersToIterator(keys, filterIter)
  -- ApplyFilter(keys, entry) for each entry and return the results
  return map(partial(self.ApplyFilter, keys), filterIter)
end

function FilterManager:RunFilterForType(keys, type)
  local filterIter = self:CreateFilterIterator(type)
  local filterResults = self:ApplyFiltersToIterator(keys, filterIter)

  return reduce(operator.land, true, filterResults)
end
