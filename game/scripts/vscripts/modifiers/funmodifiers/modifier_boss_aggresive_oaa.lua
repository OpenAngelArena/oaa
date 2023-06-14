-- Hostile bosses

modifier_boss_aggresive_oaa = class(ModifierBaseClass)

function modifier_boss_aggresive_oaa:IsHidden()
  return false
end

function modifier_boss_aggresive_oaa:IsDebuff()
  return false
end

function modifier_boss_aggresive_oaa:IsPurgable()
  return false
end

function modifier_boss_aggresive_oaa:RemoveOnDeath()
  return true
end

function modifier_boss_aggresive_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_DISABLE_HEALING,
  }
end

function modifier_boss_aggresive_oaa:GetDisableHealing()
  return 1
end

function modifier_boss_aggresive_oaa:GetTexture()
  return "ancient_apparition_ice_blast"
end
