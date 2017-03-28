--[[
-- Modifer to check how if the player picks up bottles and adds them to a bottle stack count.
-- This is to make sure players can have infinite stacks and they dont need to hold more than one bottle
]]
modifier_bottle_charges = class({})

function modifier_bottle_charges:OnIntervalThink()

  if IsServer() then

    local haveBottle = false
    
    for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      item = self:GetCaster():GetItemInSlot(slot)
      if item ~= nil then
        itemName = item:GetAbilityName()
        if itemName == "item_bottle" then
          
          -- If there is more than 3 charges, add the extra charges to a modifer buff to be used later
          if item:GetCurrentCharges() > 3 then

            local chargesToAbsorb = item:GetCurrentCharges() - 3
            item:SetCurrentCharges(3)
            self:SetStackCount(self:GetStackCount() + chargesToAbsorb)

            -- If there is only 1 bottle, check how many charges it has. If its 0, and there is stacks, add 1 charge, if no stacks, remove the bottle
          elseif item:GetCurrentCharges() == 0 then

            if self:GetStackCount() >= 1 then
              item:SetCurrentCharges(1)
              self:SetStackCount(self:GetStackCount() - 1)
            else
              item:RemoveSelf()
              haveBottle = false
            end
          -- If somehow the player has done some tricky to get another bottle, remove it
          elseif haveBottle == true then
            item:RemoveSelf()
          end

          haveBottle = true
        end
      end
    end


    if haveBottle == false then
      self:GetCaster():RemoveModifierByName("modifier_bottle_charges")
    end

  end
end

function modifier_bottle_charges:RemoveOnDeath()
  return false
end

function modifier_bottle_charges:IsHidden()
  if self:GetStackCount() == 0 then
    return true
  end
  return false
end

function modifier_bottle_charges:GetTexture()
  return "custom/bottlecharges"
end

function modifier_bottle_charges:IsPurgable()
  return false
end

function modifier_bottle_charges:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.03)
  end
end

