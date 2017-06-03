LinkLuaModifier("modifier_auto_doom", "abilities/fountain_auto_doom.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_hyper_doom", "abilities/fountain_auto_doom.lua", LUA_MODIFIER_MOTION_NONE)

fountain_auto_doom = class({})

function fountain_auto_doom:GetIntrinsicModifierName()
  return "modifier_auto_doom"
end

------------------------------------------------------------------------

modifier_auto_doom = class({})

function modifier_auto_doom:IsHidden()
  return true
end

function modifier_auto_doom:IsPurgable()
  return false
end

function modifier_auto_doom:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

function modifier_auto_doom:OnAttackLanded(keys)
  local parent = self:GetParent()
  if keys.attacker and not keys.attacker:IsNull() and keys.attacker == parent then
    keys.target:AddNewModifier(parent, self, "modifier_hyper_doom", {duration = 1})
    --keys.target:Kill(self, parent)
  end
end

function modifier_auto_doom:CheckState()
  return {
    [MODIFIER_STATE_CANNOT_MISS] = true
  }
end

------------------------------------------------------------------------

modifier_hyper_doom = class({})

function modifier_hyper_doom:IsHidden()
  return false
end

function modifier_hyper_doom:IsPurgable()
  return false
end

function modifier_hyper_doom:IsDebuff()
  return true
end

function modifier_hyper_doom:RemoveOnDeath()
  return false
end

function modifier_hyper_doom:GetTexture()
  return "doom_bringer_doom"
end

function modifier_hyper_doom:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_SILENCED] = true,
    [MODIFIER_STATE_MUTED] = true,
    [MODIFIER_STATE_BLOCK_DISABLED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_BLIND] = true
  }
end
