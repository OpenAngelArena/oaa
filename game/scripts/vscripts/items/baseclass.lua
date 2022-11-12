ItemBaseClass = class({})

function ItemBaseClass:GetAbilityTextureName(brokenAPI)
  return self.BaseClass.GetAbilityTextureName(self)
end

function ItemBaseClass:ProcsMagicStick()
  return false
end
