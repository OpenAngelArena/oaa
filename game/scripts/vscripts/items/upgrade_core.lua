item_upgrade_core = class( ItemBaseClass )

--------------------------------------------------------------------------------

function item_upgrade_core:GetChannelTime()
	return self:GetSpecialValueFor( "channel_time" )
end

--------------------------------------------------------------------------------

function item_upgrade_core:GetSplitCoreType()
	return nil
end

--------------------------------------------------------------------------------

function item_upgrade_core:IsStillInInventory()
	local caster = self:GetCaster()

	if self and IsValidEntity( self ) and self:GetItemState() == 1 then
		return true
	end

	return false
end

--------------------------------------------------------------------------------

function item_upgrade_core:OnSpellStart()
end

--------------------------------------------------------------------------------

function item_upgrade_core:OnChannelThink( interval )
	-- cease channeling immediately if core is no longer in active inventory
	if not self:IsStillInInventory() then
		self:EndChannel( true )
	end
end

--------------------------------------------------------------------------------

function item_upgrade_core:OnChannelFinish( interrupted )
	local caster = self:GetCaster()
	local coreType = self:GetSplitCoreType()

	-- if we didn't get interrupted, destroy the core and give two new ones
	-- we also want to make sure we're actually getting a core out of this
	-- in case we somehow started channeling upgrade core 1

	-- this'll be where i learn if ability scripts cancel immediately after their
	-- ability is destroyed, or will still complete
	-- turns out they still persist past this point
	-- ... even if the item was destroyed several seconds ago
	-- huh
	if coreType and not interrupted and self:IsStillInInventory() then
		local coreCount = self:GetSpecialValueFor( "core_count" )
		-- if we don't make the purchase time persist, then players could split a "stale" core
		-- into two "fresh" cores that'll sell for more
		-- that's silly so we're not doing that
		-- ( could also just set the resulting core's purchase time forwad ten seconds, but
		-- this is slicker )
		local purchaseTime = self:GetPurchaseTime()
		local purchaser = self:GetPurchaser()
		local player = purchaser:GetPlayerOwner()

		caster:RemoveItem( self )

		for i = 1, coreCount do
			local item = CreateItem( coreType, player, player )
			item:SetPurchaseTime( purchaseTime )
			caster:AddItem( item )
			item:SetPurchaser( purchaser )
		end
	end
end

--------------------------------------------------------------------------------

item_upgrade_core_2 = class( item_upgrade_core )

function item_upgrade_core_2:GetSplitCoreType()
	return "item_upgrade_core"
end

--------------------------------------------------------------------------------

item_upgrade_core_3 = class( item_upgrade_core )

function item_upgrade_core_3:GetSplitCoreType()
	return "item_upgrade_core_2"
end

--------------------------------------------------------------------------------

item_upgrade_core_4 = class( item_upgrade_core )

function item_upgrade_core_4:GetSplitCoreType()
	return "item_upgrade_core_3"
end
