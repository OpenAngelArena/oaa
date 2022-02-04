modifier_hyper_experience_oaa = class(ModifierBaseClass)

function modifier_hyper_experience_oaa:IsHidden()
  return false
end

function modifier_hyper_experience_oaa:IsPurgable()
  return true
end

function modifier_hyper_experience_oaa:RemoveOnDeath()
  return false
end

-- function modifier_hyper_experience_oaa:GetTexture()
--   return ""
-- end
