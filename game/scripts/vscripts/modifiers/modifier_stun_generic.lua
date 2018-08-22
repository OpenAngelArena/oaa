modifier_stun_generic = class (ModifierBaseClass)

--------------------------------------------------------------------------------
function modifier_stun_generic:IsHidden()
  return true
end

function modifier_stun_generic:IsStunDebuff()
  return true
end

function modifier_stun_generic:IsAura()
  return false
end

function modifier_stun_generic:IsDebuff()
  return true
end

function modifier_stun_generic:IsPurgable()
  return false
end

function modifier_stun_generic:IsPurgeException()
  return true
end

function modifier_stun_generic:RemoveOnDeath()
  return true
end

function modifier_stun_generic:GetEffectName()
  return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_stun_generic:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_stun_generic:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_OVERRIDE_ANIMATION
  }
  return funcs
end

function modifier_stun_generic:GetOverrideAnimation( params )
  return ACT_DOTA_DISABLED
end

function modifier_stun_generic:OnCreated()
  return
end

function modifier_stun_generic:OnRefresh()
  return
end

function modifier_stun_generic:OnDestroy()
  return
end

function modifier_stun_generic:CheckState()
  local state = {
  [MODIFIER_STATE_STUNNED] = true
  }
  return state
end

