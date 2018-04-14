AbilityBaseClass = class({})

function AbilityBaseClass:GetAbilityTextureName(brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

function AbilityBaseClass:IsHiddenWhenStolen(arg)
  return self.BaseClass.IsHiddenWhenStolen(self)
end
