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
        local drop_location = death_location
        if killer and not killer:IsNull() then
          if (killer:GetAbsOrigin() - death_location):Length2D() <= 800 then
            drop_location = killer:GetAbsOrigin()
          end
        end
        CreepItemDrop:CreateDrop(itemToDrop, drop_location)
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
