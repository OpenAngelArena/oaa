modifier_disable_control = class(ModifierBaseClass)

function modifier_disable_control:CheckState()
  return {
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
  }
end

function modifier_disable_control:IsHidden()
  return true
end

function modifier_disable_control:IsPurgable()
  return false
end
