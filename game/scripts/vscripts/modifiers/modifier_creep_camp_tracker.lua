-- Modifier to handle removing creeps from the table tracking creeps in camps
-- and redistribution of loot when creeps are dominated
modifier_creep_camp_tracker = class({})

function modifier_creep_camp_tracker:IsHidden()
  return true
end

function modifier_creep_camp_tracker:IsPurgable()
  return false
end

function modifier_creep_camp_tracker:IsPurgeException()
  return false
end

function modifier_creep_camp_tracker:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DOMINATED
  }
end

function modifier_creep_camp_tracker:OnCreated(keys)
  if IsServer() then
    self.locationString = keys.locationString
    self.creepIndex = keys.creepIndex
  end
end

function modifier_creep_camp_tracker:OnDestroy()
  if IsServer() then
    -- Remove entry of parent from LivingCreepsTable
    CreepCamps.LivingCreepsTable[self.locationString][self.creepIndex] = nil
    CreepCamps.LivingCreepsTable[self.locationString].count = CreepCamps.LivingCreepsTable[self.locationString].count - 1

    local parent = self:GetParent()
    if parent and not parent:IsNull() and parent:IsAlive() then
      local function IsNotNumber(value)
        return not (type(value) == "number")
      end

      local lootModifiers = parent:FindAllModifiersByName("modifier_creep_loot")
      local creeps = CreepCamps.LivingCreepsTable[self.locationString]
      -- creeps table is not a sequence and has a count property
      -- so we filter out the numeric count property and form the rest of the data into a sequence
      local sequencedCreeps = totable(filter(IsNotNumber, pairs(creeps)))

      local function MoveLootModifier(modifier)
        local creepIndex = RandomInt(1, #sequencedCreeps)
        local selectedCreep = sequencedCreeps[creepIndex]
        if #sequencedCreeps > 0 and selectedCreep then
          modifier:CopyToUnit(selectedCreep)
        end
        modifier:Destroy()
      end

      -- Redistribute loot modifiers to other creeps in camp
      foreach(MoveLootModifier, lootModifiers)
    end
  end
end

function modifier_creep_camp_tracker:OnDominated(keys)
  Debug.EnabledModules["modifiers:modifier_creep_camp_tracker"] = true
  -- DebugPrintTable(keys)
  if keys.unit and keys.unit == self:GetParent() then
    self:Destroy()
  end
end
