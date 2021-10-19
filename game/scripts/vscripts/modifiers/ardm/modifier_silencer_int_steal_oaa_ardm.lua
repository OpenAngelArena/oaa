
modifier_silencer_int_steal_oaa_ardm = modifier_silencer_int_steal_oaa_ardm or class({})

function modifier_silencer_int_steal_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_silencer_int_steal_oaa_ardm:IsDebuff()
  return false
end

function modifier_silencer_int_steal_oaa_ardm:IsPurgable()
  return false
end

function modifier_silencer_int_steal_oaa_ardm:RemoveOnDeath()
  return false
end

-- function modifier_silencer_int_steal_oaa_ardm:OnCreated()
  -- if not IsServer() then
    -- return
  -- end
  -- local parent = self:GetParent()

  -- parent:ModifyIntellect(self:GetStackCount())
  -- parent:CalculateStatBonus(true)
-- end

function modifier_silencer_int_steal_oaa_ardm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_silencer_int_steal_oaa_ardm:GetModifierBonusStats_Intellect()
  return self:GetStackCount()
end

function modifier_silencer_int_steal_oaa_ardm:GetTexture()
  return "silencer_glaives_of_wisdom"
end
