modifier_anti_stun_oaa = class(ModifierBaseClass)

function modifier_anti_stun_oaa:IsHidden()
  return true
end

function modifier_anti_stun_oaa:IsPurgable()
  return false
end

function modifier_anti_stun_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_anti_stun_oaa:CheckState()
  local state = {
    [MODIFIER_STATE_HEXED] = false,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_SILENCED] = false,
    [MODIFIER_STATE_STUNNED] = false,
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    [MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true,
  }

  return state
end
