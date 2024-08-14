modifier_temple_guardian_statue = class(ModifierBaseClass)

-----------------------------------------------------------------------------

function modifier_temple_guardian_statue:IsHidden()
  return true
end

function modifier_temple_guardian_statue:IsDebuff()
  return false
end

function modifier_temple_guardian_statue:IsPurgable()
  return false
end

-------------------------------------------------------------------

function modifier_temple_guardian_statue:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    parent:SetForwardVector(Vector(0, -1, 0))
  end
end

--------------------------------------------------------------------------------

function modifier_temple_guardian_statue:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_TURNING,
  }
end

function modifier_temple_guardian_statue:GetModifierDisableTurning()
  return 1
end
