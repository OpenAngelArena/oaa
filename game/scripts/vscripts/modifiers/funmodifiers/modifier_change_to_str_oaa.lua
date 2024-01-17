modifier_change_to_str_oaa = class(ModifierBaseClass)

function modifier_change_to_str_oaa:IsHidden()
  return self:GetElapsedTime() > 5 * 60
end

function modifier_change_to_str_oaa:IsDebuff()
  return false
end

function modifier_change_to_str_oaa:IsPurgable()
  return false
end

function modifier_change_to_str_oaa:RemoveOnDeath()
  return false
end

function modifier_change_to_str_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has the stuff
  if parent.GetPrimaryAttribute == nil then
    return
  end

  -- Change Primary attribute to Strength
  if parent:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_STRENGTH then
    parent:SetPrimaryAttribute(DOTA_ATTRIBUTE_STRENGTH)
  end
end

function modifier_change_to_str_oaa:GetTexture()
  return "item_reaver"
end
