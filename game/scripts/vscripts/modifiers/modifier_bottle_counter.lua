modifier_bottle_counter = class({})

function modifier_bottle_counter:OnRefresh(kv)
  if IsServer() then
    local playerID = self:GetParent():GetPlayerID()
    self:SetStackCount(BottleCounter:GetBottles(playerID))
  end
end

function modifier_bottle_counter:IsPermanent()
  return true
end

function modifier_bottle_counter:GetTexture()
  return "item_bottle"
end
