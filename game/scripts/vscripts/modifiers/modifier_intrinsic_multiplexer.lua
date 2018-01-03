LinkLuaModifier("modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE)

require('libraries/fun')()

modifier_intrinsic_multiplexer = class(ModifierBaseClass)

function modifier_intrinsic_multiplexer:IsHidden()
  return true
end

function modifier_intrinsic_multiplexer:IsPurgable()
  return false
end

function modifier_intrinsic_multiplexer:RemoveOnDeath()
  return false
end

function modifier_intrinsic_multiplexer:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_intrinsic_multiplexer:OnCreated()
  self.modifiers = {}
  if IsServer() then
    Timers:CreateTimer(0.1, function ()
      self:CreateModifiers()
    end)
  end
end

function modifier_intrinsic_multiplexer:OnRefresh()
  if IsServer() then
    self:DestroyModifiers()
    self:CreateModifiers()
  end
end

function modifier_intrinsic_multiplexer:OnDestroy()
  if IsServer() then
    self:DestroyModifiers()
  end
end

function modifier_intrinsic_multiplexer:CreateModifiers()
  -- Exit if self has been deleted because for some reason this happens with Tempest Double
  if self:IsNull() then
    return
  end

  local hero = self:GetParent()
  if not hero or not hero.AddNewModifier then
    return
  end
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if ability == nil or ability:IsNull() then
    -- sometimes we create modifiers that don't have abilities and i don't know why yet
    return
  end
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
