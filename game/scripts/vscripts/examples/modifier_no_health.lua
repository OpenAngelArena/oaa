modifier_no_health = class({})

function modifier_no_health:CheckState()
  local state = {
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
  }

  return state
end

function modifier_no_health:IsHidden()
    return true
end

function modifier_no_health:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT
end