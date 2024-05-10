---------------------------------------------------------------------------------------------------

modifier_tidehunter_anchor_smash_oaa_boss = modifier_tidehunter_anchor_smash_oaa_boss or class({})

function modifier_tidehunter_anchor_smash_oaa_boss:IsHidden()
  return false
end

function modifier_tidehunter_anchor_smash_oaa_boss:IsDebuff()
  return true
end

function modifier_tidehunter_anchor_smash_oaa_boss:IsPurgable()
  return true
end

function modifier_tidehunter_anchor_smash_oaa_boss:OnCreated()
  self.damage_reduction = -30

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.damage_reduction = 0 - math.abs(ability:GetSpecialValueFor("damage_reduction_bosses"))
  end
end

modifier_tidehunter_anchor_smash_oaa_boss.OnRefresh = modifier_tidehunter_anchor_smash_oaa_boss.OnCreated

function modifier_tidehunter_anchor_smash_oaa_boss:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_tidehunter_anchor_smash_oaa_boss:GetModifierBaseDamageOutgoing_Percentage()
  return self.damage_reduction
end

function modifier_tidehunter_anchor_smash_oaa_boss:GetTexture()
  return "tidehunter_anchor_smash"
end
