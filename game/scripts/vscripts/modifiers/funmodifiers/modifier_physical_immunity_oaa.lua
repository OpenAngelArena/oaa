modifier_physical_immunity_oaa = class(ModifierBaseClass)

function modifier_physical_immunity_oaa:IsHidden()
  return true
end

function modifier_physical_immunity_oaa:IsDebuff()
  return false
end

function modifier_physical_immunity_oaa:IsPurgable()
  return false
end

function modifier_physical_immunity_oaa:RemoveOnDeath()
  return false
end

function modifier_physical_immunity_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
  }
end

function modifier_physical_immunity_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

--function modifier_physical_immunity_oaa:GetTexture()
  --return ""
--end
