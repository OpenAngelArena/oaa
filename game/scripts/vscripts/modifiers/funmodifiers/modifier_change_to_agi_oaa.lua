modifier_change_to_agi_oaa = class(ModifierBaseClass)

function modifier_change_to_agi_oaa:IsHidden()
  return self:GetElapsedTime() > 5 * 60
end

function modifier_change_to_agi_oaa:IsDebuff()
  return false
end

function modifier_change_to_agi_oaa:IsPurgable()
  return false
end

function modifier_change_to_agi_oaa:RemoveOnDeath()
  return false
end

function modifier_change_to_agi_oaa:OnCreated()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- Check if parent has the stuff
  if parent.GetPrimaryAttribute == nil then
    return
  end

  -- Change Primary attribute to Agility
  if parent:GetPrimaryAttribute() ~= DOTA_ATTRIBUTE_AGILITY then
    parent:SetPrimaryAttribute(DOTA_ATTRIBUTE_AGILITY)
  end
end

function modifier_change_to_agi_oaa:GetTexture()
  return "item_eagle"
end
