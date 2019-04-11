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

function item_upgrade_core:OnSpellStart()
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
	if coreType and not interrupted then
		local coreCount = self:GetSpecialValueFor( "core_count" )

		caster:RemoveItem( self )

		for i = 1, coreCount do
			caster:AddItemByName( coreType )
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
