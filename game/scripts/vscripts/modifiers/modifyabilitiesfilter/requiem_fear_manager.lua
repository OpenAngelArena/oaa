---------------------------------------------------------------------------------------------------

modifier_oaa_requiem_allowed = modifier_oaa_requiem_allowed or class({})

function modifier_oaa_requiem_allowed:IsHidden()
  return true
end

function modifier_oaa_requiem_allowed:IsDebuff()
  return false
end

function modifier_oaa_requiem_allowed:IsPurgable()
  return false
end

function modifier_oaa_requiem_allowed:RemoveOnDeath()
  return true
end

function modifier_oaa_requiem_allowed:OnCreated(keys)
  if not IsServer() then
    return
  end
  self.immune_time = keys.immune_time
end

function modifier_oaa_requiem_allowed:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() or not self.immune_time then
    return
  end

  parent:AddNewModifier(parent, nil, "modifier_oaa_requiem_not_allowed", {duration = self.immune_time})
end

---------------------------------------------------------------------------------------------------

modifier_oaa_requiem_not_allowed = modifier_oaa_requiem_not_allowed or class({})

function modifier_oaa_requiem_not_allowed:IsHidden()
  return true
end

function modifier_oaa_requiem_not_allowed:IsDebuff()
  return false
end

function modifier_oaa_requiem_not_allowed:IsPurgable()
  return false
end

function modifier_oaa_requiem_not_allowed:RemoveOnDeath()
  return true
end

function modifier_oaa_requiem_not_allowed:OnCreated()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  parent:RemoveModifierByName("modifier_nevermore_requiem_slow")
  parent:RemoveModifierByName("modifier_nevermore_requiem_fear")
end
