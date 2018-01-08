modifier_aura_item_upgrade = class(ModifierBaseClass)

function modifier_aura_item_upgrade:IsHidden()
  return true
end

function modifier_aura_item_upgrade:IsPurgable()
  return false
end

function modifier_aura_item_upgrade:RemoveOnDeath()
  return false
end

function modifier_aura_item_upgrade:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

if IsServer() then
  function modifier_aura_item_upgrade:OnCreated( kv )
    local auraItems =
    {
      "item_greater_guardian_greaves_",
      "item_greater_travel_boots_",
      "item_ancient_janggo_of_endurance_",
      "item_assault_",
      "item_crimson_pipe_",
      "item_helm_of_the_dominator_",
      "item_lucience_",
      "item_mekansm_",
      "item_pipe_",
      "item_radiance_",
      "item_ring_of_aquila_",
      "item_shivas_guard_",
      "item_urn_of_sorcery_",
      "item_vladmir_",
    }

    local hero = self:GetParent()
    local item

    -- Only remove the item if it has aura upgrade
    for _, value in ipairs(auraItems) do
      if string.find(kv.ItemName, value) then
        -- only remove the item if it is in a active slot
        for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
          item = hero:GetItemInSlot(i)
          if item and item:GetName() == kv.ItemName then
            self.ItemSlot = i
            self.hUpgradeItem = hero:TakeItem(item)
            self:StartIntervalThink(1)
            return
          end
        end
      end
    end

    self:Destroy()
  end

--------------------------------------------------------------------------------

  function modifier_aura_item_upgrade:FindItemSlot(hItem)
    local hero = self:GetParent()
    for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
      local item = hero:GetItemInSlot(i)
      if item == hItem then
        return i
      end
    end
    return -1
  end
--------------------------------------------------------------------------------

  function modifier_aura_item_upgrade:OnIntervalThink()
    local hero = self:GetParent()
    local itemOnUpgradeSpot = hero:GetItemInSlot(self.ItemSlot)
    local itemOnUpgradeSpotName = ""

    -- if there is a item on the slot remove it, otherwise the upgraded item can
    -- be sent to stash, backpack or ground
    if itemOnUpgradeSpot ~= nil then
      itemOnUpgradeSpotName = itemOnUpgradeSpot:GetName()
      itemOnUpgradeSpot = hero:TakeItem( itemOnUpgradeSpot )
    end

    local upgradeItem = hero:AddItem( self.hUpgradeItem )
    local upgradeItemSlot = self:FindItemSlot(upgradeItem)

    -- if the item is in another slot swap it to its place
    if upgradeItemSlot ~= self.ItemSlot and  upgradeItemSlot > -1 then
      hero:SwapItems(upgradeItemSlot, self.ItemSlot)
    end

    -- readd the item that was on the upgrade slot
    if itemOnUpgradeSpot ~= nil then
      hero:AddItem( itemOnUpgradeSpot )
    end

    self:Destroy()
  end
end

