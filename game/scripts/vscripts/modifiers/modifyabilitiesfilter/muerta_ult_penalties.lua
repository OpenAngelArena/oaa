---------------------------------------------------------------------------------------------------

modifier_muerta_pierce_the_veil_penalty_oaa = modifier_muerta_pierce_the_veil_penalty_oaa or class({})

function modifier_muerta_pierce_the_veil_penalty_oaa:IsHidden()
  return true
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsDebuff()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:IsPurgable()
  return false
end

function modifier_muerta_pierce_the_veil_penalty_oaa:OnCreated()
  self.dmg_penalty = -50
  self.dmg_penalty_bosses = -40

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_penalty = 0 - math.abs(ability:GetSpecialValueFor("damage_penalty"))
    self.dmg_penalty_bosses = 0 - math.abs(ability:GetSpecialValueFor("damage_penalty_bosses"))
  end
end

modifier_muerta_pierce_the_veil_penalty_oaa.OnRefresh = modifier_muerta_pierce_the_veil_penalty_oaa.OnCreated

function modifier_muerta_pierce_the_veil_penalty_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
  }
end

function modifier_muerta_pierce_the_veil_penalty_oaa:GetModifierTotalDamageOutgoing_Percentage(event)
  if event.target:IsOAABoss() then
    return self.dmg_penalty_bosses
  end
  return self.dmg_penalty
end
