modifier_aura_item_upgrade = class(ModifierBaseClass)

if IsServer() then
  function modifier_aura_item_upgrade:OnCreated( kv )
    print("modifier_aura_item_upgrade AURA CREATED")
    self.ItemName = kv.ItemName
    self.PlayerId = kv.PlayerId
    print("modifier_aura_item_upgrade : " .. self.ItemName)
    print("modifier_aura_item_upgrade Player: " .. self.PlayerId)

    local hero = PlayerResource:GetPlayer(self.PlayerId):GetAssignedHero()

    -- only remove the item if it is in a active slot
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = hero:GetItemInSlot(i)
      if item then
        if item:GetName() == self.ItemName then
          self.ItemSlot = i
          hero:RemoveItem(item)
          self:StartIntervalThink( 1 )
        end
      end
    end

  end

--------------------------------------------------------------------------------

  function modifier_aura_item_upgrade:FindItemSlot(hItem)
    local hero = PlayerResource:GetPlayer(self.PlayerId):GetAssignedHero()
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      local item = hero:GetItemInSlot(i)
      if item == hItem then
        return i
      end
    end
    return -1
  end
--------------------------------------------------------------------------------

  function modifier_aura_item_upgrade:OnIntervalThink()
    local hero = PlayerResource:GetPlayer(self.PlayerId):GetAssignedHero()
    local itemOnUpgradeSpot = hero:GetItemInSlot(self.ItemSlot)
    local itemOnUpgradeSpotName = ""

    if itemOnUpgradeSpot ~= nil then
      itemOnUpgradeSpotName = itemOnUpgradeSpot:GetName()
      hero:RemoveItem( itemOnUpgradeSpot )
    end

    local upgradeItem = hero:AddItemByName( self.ItemName )
    local upgradeItemSlot = self:FindItemSlot(upgradeItem)
    if upgradeItemSlot ~= self.ItemSlot and  upgradeItemSlot > -1 then
      hero:SwapItems(upgradeItemSlot, self.ItemSlot)
    end

    if itemOnUpgradeSpot ~= nil then
      hero:AddItemByName( itemOnUpgradeSpotName )
    end

    UTIL_Remove( self:GetParent() )
	end

end

function modifier_aura_item_upgrade:OnDestroy()
end
