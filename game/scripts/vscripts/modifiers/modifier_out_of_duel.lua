modifier_out_of_duel = class(ModifierBaseClass)

function modifier_out_of_duel:CheckState()
  return {
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_FROZEN] = true,
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
  }
end

function modifier_out_of_duel:IsHidden()
  return false
end

function modifier_out_of_duel:IsPurgeable()
  return false
end

function modifier_out_of_duel:IsPurgeException()
  return false
end
