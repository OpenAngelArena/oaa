modifier_change_to_int_oaa = class(ModifierBaseClass)

function modifier_change_to_int_oaa:IsHidden()
  return self:GetElapsedTime() > 5 * 60
end

function modifier_change_to_int_oaa:IsDebuff()
  return false
end

function modifier_change_to_int_oaa:IsPurgable()
  return false
end

function modifier_change_to_int_oaa:RemoveOnDeath()
  return false
end

function modifier_change_to_int_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has the stuff
  if parent.GetPrimaryAttribute == nil then
    return
  end

  -- Change Primary attribute to Intelligence
  if parent:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_INTELLECT then
    parent:SetPrimaryAttribute(DOTA_ATTRIBUTE_INTELLECT)
  end
end

function modifier_change_to_int_oaa:GetTexture()
  return "item_mystic_staff"
end
