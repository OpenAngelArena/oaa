modifier_bottle_collector_oaa = class(ModifierBaseClass)

function modifier_bottle_collector_oaa:IsHidden()
  return false
end

function modifier_bottle_collector_oaa:IsDebuff()
  return false
end

function modifier_bottle_collector_oaa:IsPurgable()
  return false
end

function modifier_bottle_collector_oaa:RemoveOnDeath()
  return false
end

function modifier_bottle_collector_oaa:OnCreated()
  self.damage_per_bottle_charge = 1.5
  self.spell_amp_per_bottle_charge = 0.1

  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_bottle_collector_oaa:OnIntervalThink()
  local parent = self:GetParent()

  -- Check if parent has any bottle in the inventory
  if parent.HasItemInInventory and not parent:HasItemInInventory("item_infinite_bottle") then
    self:SetStackCount(0)
    return
  end

  if not parent:IsAlive() then
    return
  end

  local bottle
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = parent:GetItemInSlot(i)
    if item then
      if item:GetAbilityName() == "item_infinite_bottle" then
        bottle = item
        break
      end
    end
  end

  if not bottle then
    self:SetStackCount(0)
    return
  end

  self:SetStackCount(0 - bottle:GetCurrentCharges())
end

function modifier_bottle_collector_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
    MODIFIER_EVENT_ON_DEATH,
  }
end

function modifier_bottle_collector_oaa:GetModifierPreAttack_BonusDamage()
  return self.damage_per_bottle_charge * math.abs(self:GetStackCount())
end

function modifier_bottle_collector_oaa:GetModifierSpellAmplify_Percentage()
  return self.spell_amp_per_bottle_charge * math.abs(self:GetStackCount())
end

if IsServer() then
  function modifier_bottle_collector_oaa:OnDeath(event)
    local parent = self:GetParent()
    local dead = event.unit

    if dead ~= parent then
      return
    end

    -- Dead unit already deleted, don't continue to prevent errors
    if not parent or parent:IsNull() then
      return
    end

    if math.abs(self:GetStackCount()) < 3 then
      return
    end

    local bottle
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = parent:GetItemInSlot(i)
      if item then
        if item:GetAbilityName() == "item_infinite_bottle" then
          bottle = item
          break
        end
      end
    end

    if not bottle then
      -- Check backpack too
      for i = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
        local item = parent:GetItemInSlot(i)
        if item then
          if item:GetAbilityName() == "item_infinite_bottle" then
            bottle = item
            break
          end
        end
      end
      -- If no bottle even in backpack then don't continue
      if not bottle then
        return
      end
    end

    local old_charges = bottle:GetCurrentCharges()
    if old_charges <= 1 then
      return
    end

    bottle:SetCurrentCharges(math.ceil(old_charges * 2/3))

    local death_location = parent:GetAbsOrigin()
    local newItem = CreateItem("item_infinite_bottle", nil, nil) -- CDOTA_Item

    newItem:SetPurchaseTime(0)
    newItem:SetCurrentCharges(math.floor(old_charges * 1/3))

    CreateItemOnPositionSync(death_location, newItem) -- CDOTA_Item_Physical
    newItem:LaunchLoot(false, 300, 0.75, death_location + RandomVector(RandomFloat(50, 350)), nil)

    -- Bottle expire (despawn); can collide with ClearBottles, hence why multiple null checks
    Timers:CreateTimer(BOTTLE_DESPAWN_TIME, function ()
      -- check if safe to destroy
      if newItem and not newItem:IsNull() then
        local container = newItem:GetContainer() -- CDOTA_Item_Physical
        if container and not container:IsNull() then
          UTIL_Remove(container) -- Remove item container (CDOTA_Item_Physical)
        end
      end
    end)
  end
end

function modifier_bottle_collector_oaa:GetTexture()
  return "item_bottle"
end
