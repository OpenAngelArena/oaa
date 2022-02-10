modifier_hyper_experience_oaa = class(ModifierBaseClass)

function modifier_hyper_experience_oaa:IsHidden()
  return false
end

function modifier_hyper_experience_oaa:IsDebuff()
  return false
end

function modifier_hyper_experience_oaa:IsPurgable()
  return false
end

function modifier_hyper_experience_oaa:RemoveOnDeath()
  return false
end

function modifier_hyper_experience_oaa:GetTexture()
  return "chen_hand_of_god"
end
