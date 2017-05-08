--[[ ============================================================================================================
	Charge BKB: Combines magic_wand functionality with BKB functionality, and charges decay with time.
	Written by RamonNZ
	Version 1.04
	Credit: Some original code from Rook
	RamonNZ: The code below starts when you activate the BKB:
	RamonNZ: Added basic purge on BKB start.
================================================================================================================= ]]

require( "libraries/Timers" )	--needed for the timers.

function modifier_charge_bkb_on_spell_start(keys)

--RamonNZ: Wand Effect: Idea: May as well keep the small wand heal effect in addition to the BKB effect. Can be commented out if not wanted or just set to 0 in the kv.
	local amount_to_restore = keys.ability:GetCurrentCharges() * keys.RestorePerCharge --RestorePerCharge
	keys.caster:Heal(amount_to_restore, keys.caster)
	keys.caster:GiveMana(amount_to_restore)
--RamonNZ: BKB Effect:
	local modifier_duration = keys.ChargeImmunityTime*keys.ability:GetCurrentCharges()
-- Basic Purge:
	local RemovePositiveBuffs = false
	local RemoveDebuffs = true
	local BuffsCreatedThisFrameOnly = false
	local RemoveStuns = false
	local RemoveExceptions = false
	keys.caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

	print ("--> bkb spell immunity length = ", modifier_duration)
	keys.caster:AddNewModifier(keys.caster, keys.ability, "modifier_charge_bkb_spell_immunity", {duration = modifier_duration})
	keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_charge_bkb_spell_immunity", {duration = modifier_duration}) -- why did I do this twice? I'll figure it out later

	local modified_cooldown = keys.ChargeCooldownTime*keys.ability:GetCurrentCharges() + keys.ability:GetCooldownTime()
	keys.ability:SetCurrentCharges(0)
	keys.ability:StartCooldown( modified_cooldown )
end



--[[ ============================================================================================================
	RamonNZ: This code adds charges when abilities are used by enemies.
	Known Bugs (by Rook - wand code): Because OnAbilityExecuted does not pass in information about the ability that was just executed, this code cannot use ProcsMagicStick() to determine if Magic Stick should gain a charge.  For now, every cast ability awards a charge.
	RamonNZ: Fixed - Charges can be added by neutral abilities, just like wand
================================================================================================================= ]]
function modifier_charge_bkb_aura_on_ability_executed(keys)
	if keys.caster:GetTeam() ~= keys.unit:GetTeam() and keys.caster:CanEntityBeSeenByMyTeam(keys.unit) then
		 --Rook's code: Search for a Charge_BKB in the aura creator's inventory.  If there are multiple Charge_BKBs in the player's inventory, the oldest one that's not full receives a charge.
		local oldest_unfilled_wand = nil

		for i=0, 5, 1 do
			local current_item = keys.caster:GetItemInSlot(i)
			if current_item ~= nil and current_item:GetName() == "item_charge_bkb" and current_item:GetCurrentCharges() < keys.MaxCharges then
				if oldest_unfilled_wand == nil or current_item:GetEntityIndex() < oldest_unfilled_wand:GetEntityIndex() then
					oldest_unfilled_wand = current_item
				end
			end
		end

		--RamonNZ: Increment the Magic Wand's current charges by 1, but only if CurrentCharges are less than MaxCharges
		if oldest_unfilled_wand ~= nil then
			if oldest_unfilled_wand:GetCurrentCharges() < keys.MaxCharges then
				oldest_unfilled_wand:SetCurrentCharges(oldest_unfilled_wand:GetCurrentCharges() + 1)
				--RamonNZ: start the charges decay timer when a new charge is added
				create_decay_timer(keys)
			end
		end
	end
end


--[[ ============================================================================================================
	RamonNZ: This is the decay timer - every charge added creates a one-shot timer based on ChargeDecayTime
================================================================================================================= ]]
function create_decay_timer(keys)
	Timers:CreateTimer({
	useGameTime = true,
	endTime = keys.ChargeDecayTime,
	callback = function()
		if keys.ability:GetCurrentCharges() > 0 then
			print ("--> -1 Charge_BKB charge")
			keys.ability:SetCurrentCharges(keys.ability:GetCurrentCharges()-1)
		end
		return nil
	end})
end


--[[ ============================================================================================================
	RamonNZ: This code creates a decay timer * every initial charge when item is created
================================================================================================================= ]]
function modifier_charge_bkb_on_created(keys)
	for i=1, keys.ability:GetCurrentCharges() do
		create_decay_timer(keys)
	end
	--Removed test timer to allow you to test in single game
--	  Timers:CreateTimer(function()
--     keys.ability:SetCurrentCharges(keys.ability:GetCurrentCharges()+1)
--      return 10.0
--   end)
end
