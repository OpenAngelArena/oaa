modifier_creep_loot = class(ModifierBaseClass)

function modifier_creep_loot:OnCreated(keys)
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

function modifier_creep_loot:OnDeath(keys)
  local parent = self:GetParent()
  if keys.unit == parent then
    local itemToDrop = CreepItemDrop:RandomDropItemName(self.locationString)
    if itemToDrop ~= "" and itemToDrop ~= nil then
      CreepItemDrop:CreateDrop(itemToDrop, parent:GetAbsOrigin())
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
