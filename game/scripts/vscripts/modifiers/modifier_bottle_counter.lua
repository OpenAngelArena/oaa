modifier_bottle_counter = class({})

function modifier_bottle_counter:OnRefresh(kv)
  if IsServer() then
    self:SetStackCount(self:GetParent():GetPlayerOwner().bottleCount)
  end
end

function modifier_bottle_counter:IsPermanent()
  return true
end
