modifier_disable_control = class({})

function modifier_disable_control:CheckState()
  local state = {
      [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }

  return state
end

function modifier_disable_control:IsHidden()
    return true
end
