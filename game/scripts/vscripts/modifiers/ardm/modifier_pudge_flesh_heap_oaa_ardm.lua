
modifier_pudge_flesh_heap_oaa_ardm = modifier_pudge_flesh_heap_oaa_ardm or class({})

function modifier_pudge_flesh_heap_oaa_ardm:IsHidden()
  return false -- needs tooltip
end

function modifier_pudge_flesh_heap_oaa_ardm:IsDebuff()
  return false
end
function modifier_pudge_flesh_heap_oaa_ardm:IsPurgable()
  return false
end

function modifier_pudge_flesh_heap_oaa_ardm:RemoveOnDeath()
  return false
end

function modifier_pudge_flesh_heap_oaa_ardm:DeclareFunctions()
  return {
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
  }
end

function modifier_pudge_flesh_heap_oaa_ardm:GetModifierBonusStats_Strength()
  return self:GetStackCount()
end

--function modifier_pudge_flesh_heap_oaa_ardm:GetModifierMagicalResistanceBonus()
  --return 10
--end

function modifier_pudge_flesh_heap_oaa_ardm:GetTexture()
  return "pudge_flesh_heap"
end
