modifier_creep_loot = class(ModifierBaseClass)

function modifier_creep_loot:OnCreated(keys)
  if not IsServer() then return end
  self.locationString = keys.locationString
end

function modifier_creep_loot:IsHidden()
  return true
end

function modifier_creep_loot:IsPurgable()
  return false
end

function modifier_creep_loot:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_EVENT_ON_DOMINATED
  }
end

if IsServer() then
  function modifier_creep_loot:OnDeath(keys)
    local parent = self:GetParent()
    if keys.unit == parent then
      local itemToDrop = CreepItemDrop:RandomDropItemName(self.locationString)
      if itemToDrop and itemToDrop ~= "" then
        local killer = keys.attacker
        local death_location = parent:GetAbsOrigin()
        local killer_location
        local has_room = true
        if killer and not killer:IsNull() then
          killer_location = killer:GetAbsOrigin()
          -- Check if killer has room in the inventory, if killer is not a hero it behaves like there is room
          -- this bit of code is not ideal but it's better than nothing
          if killer.HasInventory then
            if killer:HasInventory() and killer.HasAnyAvailableInventorySpace then
              has_room = killer:HasRoomForItemOAA(false, false)
            end
          end
        end
        CreepItemDrop:CreateDrop(itemToDrop, death_location, killer_location, has_room)
      end
    end
  end
end

function modifier_creep_loot:OnDominated(keys)
  local parent = self:GetParent()
  if keys.unit == parent then
    -- Remove self when creeps are dominated
    self:Destroy()
  end
end
