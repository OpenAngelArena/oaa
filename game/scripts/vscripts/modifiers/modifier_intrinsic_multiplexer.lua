require('libraries/fun')()

modifier_intrinsic_multiplexer = class({})

function modifier_intrinsic_multiplexer:IsHidden()
  return true
end

function modifier_intrinsic_multiplexer:IsPurgable()
  return false
end

function modifier_intrinsic_multiplexer:OnCreated()
  self.modifiers = {}
  self:CreateModifiers()
end

function modifier_intrinsic_multiplexer:OnRefresh()
  self:DestroyModifiers()
  self:CreateModifiers()
end

function modifier_intrinsic_multiplexer:OnDestroy()
  self:DestroyModifiers()
end

function modifier_intrinsic_multiplexer:CreateModifiers()
  local hero = self:GetParent()
  if not hero or not hero.AddNewModifier then
    return
  end
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if not ability.GetIntrinsicModifierNames then
    print('Ability does not have a GetIntrinsicModifierNames method')
    return
  end
  local modifiers = ability:GetIntrinsicModifierNames(self)
  iter(modifiers):each(function (modifierName)
    self.modifiers[modifierName] = hero:AddNewModifier(caster, ability, modifierName, {})
  end)
end

function modifier_intrinsic_multiplexer:DestroyModifiers()
  iter(self.modifiers):each(function (name, mod)
    if mod and not mod:IsNull() then
      mod:Destroy()
    end
  end)
  self.modifiers = {}
end
