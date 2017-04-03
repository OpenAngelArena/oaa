
modifier_boss_charger_pillar_debuff = class({})

function modifier_boss_charger_pillar_debuff:OnCreated(keys)
  if not IsServer() then
    return
  end
  local ability = self:GetAbility()

  self.armor_reduction = ability:GetSpecialValueFor( "debuff_armor" )
  self.magic_resist_reduction = ability:GetSpecialValueFor( "debuff_magic_resist" )

  print('reducing ' .. self.armor_reduction .. ' and ' .. self.magic_resist_reduction)
end

function modifier_boss_charger_pillar_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
  }
end

function modifier_boss_charger_pillar_debuff:GetModifierPhysicalArmorBonus()
  return self.armor_reduction
end

function modifier_boss_charger_pillar_debuff:GetModifierMagicalResistanceBonus()
  return self.magic_resist_reduction
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
  return "particles/generic_gameplay/generic_stunned.vpcf"
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
