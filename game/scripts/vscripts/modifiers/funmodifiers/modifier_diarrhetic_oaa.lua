modifier_diarrhetic_oaa = class(ModifierBaseClass)

function modifier_diarrhetic_oaa:IsHidden()
  return false
end

function modifier_diarrhetic_oaa:IsPurgable()
  return true
end

function modifier_diarrhetic_oaa:RemoveOnDeath()
  return false
end

-- function modifier_diarrhetic_oaa:GetTexture()
--   return ""
-- end
