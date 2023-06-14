-- Quick Spellcasting

modifier_no_cast_points_oaa = class(ModifierBaseClass)

function modifier_no_cast_points_oaa:IsHidden()
  return false
end

function modifier_no_cast_points_oaa:IsDebuff()
  return false
end

function modifier_no_cast_points_oaa:IsPurgable()
  return false
end

function modifier_no_cast_points_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_no_cast_points_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
    MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
  }
end

if IsServer() then
  function modifier_no_cast_points_oaa:GetModifierPercentageCasttime()
    return 100
  end

  function modifier_no_cast_points_oaa:GetModifierIgnoreCastAngle()
    return 1
  end
end

function modifier_no_cast_points_oaa:GetTexture()
  return "wisp_spirits"
end
