modifier_no_cast_points_oaa = class(ModifierBaseClass)

function modifier_no_cast_points_oaa:IsHidden()
  return true
end

function modifier_no_cast_points_oaa:IsPurgable()
  return false
end

function modifier_no_cast_points_oaa:RemoveOnDeath()
  return false
end

function modifier_no_cast_points_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_CASTTIME_PERCENTAGE
  }
end

--function modifier_no_cast_points_oaa:GetTexture()
  --return ""
--end

function modifier_no_cast_points_oaa:GetModifierPercentageCasttime()
  return 100
end
