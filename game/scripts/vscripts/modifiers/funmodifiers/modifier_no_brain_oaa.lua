modifier_no_brain_oaa = class(ModifierBaseClass)

function modifier_no_brain_oaa:IsHidden()
  return false
end

function modifier_no_brain_oaa:IsDebuff()
  return true
end

function modifier_no_brain_oaa:IsPurgable()
  return false
end

function modifier_no_brain_oaa:RemoveOnDeath()
  return false
end

function modifier_no_brain_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
  }
end

function modifier_no_brain_oaa:GetModifierBonusStats_Intellect()
  return -999
end

function modifier_no_brain_oaa:GetModifierAttackSpeedBonus_Constant()
  return 350
end

function modifier_no_brain_oaa:GetEffectName()
  return "particles/units/heroes/hero_faceless_void/faceless_void_dialatedebuf.vpcf"
end

function modifier_no_brain_oaa:GetEffectAttachType()
  return PATTACH_CENTER_FOLLOW
end

function modifier_no_brain_oaa:GetTexture()
  return "faceless_void_time_dilation"
end
