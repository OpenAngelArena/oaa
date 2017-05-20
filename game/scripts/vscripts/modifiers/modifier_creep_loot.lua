-- Modifier that will drop items on parent dea
-- Dropped items are passed in as parameters on creation

modifier_creep_loot = class({})

function modifier_creep_loot:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_creep_loot:IsHidden()
  return false
end

function modifier_creep_loot:IsPurgable()
  return false
end

function modifier_creep_loot:IsPurgeException()
  return false
end

function modifier_creep_loot:OnCreated(keys)
  self.drop = keys.drop
end

function modifier_creep_loot:OnDestroy()
  local deathLocation = self:GetParent():GetAbsOrigin()
  local function DropItem(itemName)
    CreepItemDrop:CreateDrop(itemName, deathLocation)
  end

  DropItem(self.drop)
end
