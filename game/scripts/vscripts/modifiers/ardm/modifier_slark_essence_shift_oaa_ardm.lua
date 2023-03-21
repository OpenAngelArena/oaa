
modifier_slark_essence_shift_oaa_ardm = modifier_slark_essence_shift_oaa_ardm or class({})

function modifier_slark_essence_shift_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_slark_essence_shift_oaa_ardm:IsDebuff()
  return false
end

function modifier_slark_essence_shift_oaa_ardm:IsPurgable()
  return false
end

function modifier_slark_essence_shift_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_slark_essence_shift_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS
  }
end

function modifier_slark_essence_shift_oaa_ardm:GetModifierBonusStats_Agility()
  return self:GetStackCount()
end

function modifier_slark_essence_shift_oaa_ardm:GetTexture()
  return "slark_essence_shift"
end
