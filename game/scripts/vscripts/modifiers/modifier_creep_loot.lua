-- Modifier that will drop items on parent dea
-- Dropped items are passed in as parameters on creation

modifier_creep_loot = class({})

function modifier_creep_loot:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_creep_loot:IsHidden()
  return true
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

function modifier_creep_loot:CopyToUnit(unit)
  unit:AddNewModifier(self:GetCaster(), self:GetAbility(), self:GetName(), {drop = self.drop})
end

function modifier_creep_loot:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_creep_loot:OnDeath(keys)
  local parent = self:GetParent()
  if keys.unit == parent then
    local deathLocation = parent:GetAbsOrigin()
    local function DropItem(itemName)
      CreepItemDrop:CreateDrop(itemName, deathLocation)
    end

    DropItem(self.drop)
  end
end
