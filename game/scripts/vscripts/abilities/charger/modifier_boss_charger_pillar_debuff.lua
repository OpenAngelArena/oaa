
modifier_boss_charger_pillar_debuff = class(ModifierBaseClass)

function modifier_boss_charger_pillar_debuff:OnCreated(keys)
  if not IsServer() then
    return
  end
  local ability = self:GetAbility()
end

function modifier_boss_charger_pillar_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
  }
end

function modifier_boss_charger_pillar_debuff:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor( "debuff_armor" )
end

function modifier_boss_charger_pillar_debuff:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor( "debuff_magic_resist" )
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
