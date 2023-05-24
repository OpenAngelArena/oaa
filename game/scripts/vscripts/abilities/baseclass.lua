AbilityBaseClass = class({})

function AbilityBaseClass:GetAbilityTextureName(brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

