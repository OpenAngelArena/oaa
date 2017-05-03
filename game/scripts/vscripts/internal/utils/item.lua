

function GetAllItemsByNameInInventory(unit, itemname, bBackpack)
	local items = {}
	for slot = 0, bBackpack and DOTA_STASH_SLOT_6 or DOTA_ITEM_SLOT_9 do
		local item = unit:GetItemInSlot(slot)
		if item and item:GetAbilityName() == itemname then
			table.insert(items, item)
		end
	end
	return items
end

function CDOTA_BaseNPC:UnitHasSlotForItem(itemname, bBackpack)
	if self.HasRoomForItem then
		return self:HasRoomForItem(itemname, bBackpack, true) ~= 4
	else
		for i = 0, bBackpack and DOTA_STASH_SLOT_6 or DOTA_ITEM_SLOT_9 do
			local item = self:GetItemInSlot(i)
			if not IsValidEntity(item) or (item:GetAbilityName() == itemname and item:IsStackable()) then
				return true
			end
		end
		return false
	end
end

function FillSlotsWithDummy(unit, bNoStash)
	for i = 0, bNoStash and DOTA_ITEM_SLOT_9 or DOTA_STASH_SLOT_6 do
		local current_item = unit:GetItemInSlot(i)
		if not current_item then
			unit:AddItem(CreateItem("item_dummy", unit, unit))
		end
	end
end

function ClearSlotsFromDummy(unit, bNoStash)
	for i = 0, bNoStash and DOTA_ITEM_SLOT_9 or DOTA_STASH_SLOT_6 do
		local current_item = unit:GetItemInSlot(i)
		if current_item and current_item:GetAbilityName() == "item_dummy" then
			unit:RemoveItem(current_item)
			UTIL_Remove(current_item)
		end
	end
end

function SetAllItemSlotsLocked(unit, locked, bNoStash)
	for i = 0, bNoStash and DOTA_ITEM_SLOT_9 or DOTA_STASH_SLOT_6 do
		local current_item = unit:GetItemInSlot(i)
		if current_item then
			ExecuteOrderFromTable({
				UnitIndex = unit:GetEntityIndex(), 
				OrderType = DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK,
				AbilityIndex = current_item:GetEntityIndex(),
				TargetIndex = locked and 1 or 0,
				Queue = false
			})
		end
	end
end

function swap_to_item(unit, srcItem, newItem)
	FillSlotsWithDummy(unit)
	if unit:HasItemInInventory(srcItem:GetName()) then
		unit:RemoveItem(srcItem)
		unit:AddItem(newItem)
	end
	
	ClearSlotsFromDummy(unit)
end

function FindItemInInventoryByName(unit, itemname, searchStash, onlyStash, ignoreBackpack)
	local lastSlot = ignoreBackpack and DOTA_ITEM_SLOT_6 or DOTA_ITEM_SLOT_9
	local startSlot = 0
	if searchStash then lastSlot = DOTA_STASH_SLOT_6 end
	if onlyStash then startSlot = DOTA_STASH_SLOT_1 end
	for slot = startSlot, lastSlot do
		local item = unit:GetItemInSlot(slot)
		if item and item:GetAbilityName() == itemname then
			return item
		end
	end
end

function CDOTA_Item:SpendCharge(amount)
	local newCharges = self:GetCurrentCharges() - (amount or 1)
	if newCharges <= 0 then
		UTIL_Remove(self)
	else
		self:SetCurrentCharges(newCharges)
	end
end