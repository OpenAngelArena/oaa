--[[
-- Modifer to check how if the player picks up bottles and adds them to a bottle stack count. 
-- This is to make sure players can have infinite stacks and they dont need to hold more than one bottle
]]
modifier_bottle_charges = class({})

function modifier_bottle_charges:OnIntervalThink()
    
  if IsServer() then

    local bottlesFound = 0 
    for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
      item = self:GetCaster():GetItemInSlot(slot)
      if item ~= nil then
          itemName = item:GetAbilityName()
          if itemName == "item_bottle" then
            bottlesFound = bottlesFound + 1
          end
      end
    end 

    -- If there is more than one bottle, remove bottles that have full charges and addd them to stack count
    if bottlesFound > 1 then
      for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        item = self:GetCaster():GetItemInSlot(slot)
        if item ~= nil then
            itemName = item:GetAbilityName()
            if itemName == "item_bottle" then
              if item:GetCurrentCharges() == 3 then
                if bottlesFound > 1 then
                  bottlesFound = bottlesFound - 1           
                  local chargesToAbsorb = item:GetCurrentCharges()
                  self:SetStackCount(self:GetStackCount() + chargesToAbsorb)
                  item:RemoveSelf()                 
                end
              end
            end
        end
      end
    end

    -- If there is only 1 bottle, check how many charges it has. If its 0, and there is stacks, add 1 charge, if no stacks, remove the bottle
    if bottlesFound == 1 then
      for slot =  DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
        item = self:GetCaster():GetItemInSlot(slot)
        if item ~= nil then
            itemName = item:GetAbilityName()
            if itemName == "item_bottle" then
              if item:GetCurrentCharges() == 0 then             
                if self:GetStackCount() >= 1 then
                  item:SetCurrentCharges(1)
                  self:SetStackCount(self:GetStackCount() - 1)
                else
                  item:RemoveSelf()
                  
                end
              end
            end
        end
      end
    end

    if bottlesFound == 0 then
      self:GetCaster():RemoveModifierByName("modifier_bottle_charges")
    end

  end 
end

function modifier_bottle_charges:RemoveOnDeath()
  return false  
end
 
function modifier_bottle_charges:IsHidden()
    return false
end

function modifier_bottle_charges:GetTexture()
    return "custom/bottlecharges"
end

function modifier_bottle_charges:IsPurgable()
    return false
end
 
function modifier_bottle_charges:OnCreated()
  self:StartIntervalThink(0.03)
end
 
