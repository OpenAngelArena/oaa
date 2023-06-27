modifier_generic_dead_tracker_oaa = class({})

function modifier_generic_dead_tracker_oaa:IsHidden()
  return true
end

function modifier_generic_dead_tracker_oaa:IsPurgable()
  return false
end

function modifier_generic_dead_tracker_oaa:RemoveOnDeath()
  return false
end

function modifier_generic_dead_tracker_oaa:OnCreated()
  if not IsServer() then
    return
  end
  local caster = self:GetCaster()
  if not caster or caster:IsNull() then
    self:Destroy()
    return
  end
end

function modifier_generic_dead_tracker_oaa:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if parent and not parent:IsNull() then
    parent:RemoveSelf()
  end
end
