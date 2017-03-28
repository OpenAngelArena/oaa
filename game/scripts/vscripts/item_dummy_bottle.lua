
function bottlePickup( event )
    local caster = event.caster
    local ability = event.ability

    if caster:IsRealHero() == false then
    	caster = caster:GetPlayerOwner():GetAssignedHero()
    end
    print("fired")
    local bottlesFound = false
    if caster then      
        for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
            item = caster:GetItemInSlot(slot)
            if item ~= nil then
                itemName = item:GetAbilityName()
                if itemName == "item_bottle" then
                    bottlesFound = true
                    -- Ingame, the charges should never be higher than 3, but this is just a safety mechanism, 9 charges will crash
                    if item:GetCurrentCharges() < 5 then
                        item:SetCurrentCharges(item:GetCurrentCharges() + 3)
                    end
                end
            end
        end
    end 

    if bottlesFound == false then
      caster:AddItemByName('item_bottle')
    end
          
    local modifier = caster:FindModifierByName("modifier_bottle_charges")
    if not modifier then
        caster:AddNewModifier(caster, nil, "modifier_bottle_charges", {duration = duration})
        modifier = caster:FindModifierByName("modifier_bottle_charges")
    end
end
