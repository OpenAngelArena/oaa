
modifier_temple_guardian_immunity = class(ModifierBaseClass)

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_immunity:IsHidden()
  return true
end

function modifier_temple_guardian_immunity:IsDebuff()
  return false
end

function modifier_temple_guardian_immunity:IsPurgable()
  return false
end

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_immunity:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
  }
end

-----------------------------------------------------------------------------------------

function modifier_temple_guardian_immunity:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end
