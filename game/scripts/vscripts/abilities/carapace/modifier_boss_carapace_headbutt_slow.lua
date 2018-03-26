
modifier_boss_charger_pillar_debuff = class(ModifierBaseClass)

function modifier_boss_charger_pillar_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_boss_charger_pillar_debuff:IsDebuff()
  return true
end

function modifier_boss_charger_pillar_debuff:IsHidden()
  return false
end

function modifier_boss_charger_pillar_debuff:IsPurgable()
  return false
end

function modifier_boss_charger_pillar_debuff:IsStunDebuff()
  return true
end

if IsServer() then
  function modifier_boss_charger_pillar_debuff:OnCreated(keys)
    local ability = self:GetAbility()
    ParticleManager:DestroyParticle(ability.shieldParticle, false)
    ParticleManager:ReleaseParticleIndex(ability.shieldParticle)
  end

  function modifier_boss_charger_pillar_debuff:OnDestroy()
    local ability = self:GetAbility()
    local parent = self:GetParent()
    ability.shieldParticle = ParticleManager:CreateParticle(ability.shieldParticleName, PATTACH_OVERHEAD_FOLLOW, parent)
  end
end

function modifier_boss_charger_pillar_debuff:GetEffectName()
  return "particles/charger/charger_charge_debuff.vpcf"
end

function modifier_boss_charger_pillar_debuff:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_charger_pillar_debuff:GetOverrideAnimation( params )
  return ACT_DOTA_DISABLED
end

function modifier_boss_charger_pillar_debuff:CheckState()
  local state = {
    [MODIFIER_STATE_STUNNED] = true,
    [MODIFIER_STATE_PASSIVES_DISABLED] = true,
    [MODIFIER_STATE_BLOCK_DISABLED] = true,
    [MODIFIER_STATE_EVADE_DISABLED] = true
  }

  return state
end
