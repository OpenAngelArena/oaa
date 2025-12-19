---------------------------------------------------------------------------------------------------

modifier_faceless_void_time_dilation_degen_oaa = modifier_faceless_void_time_dilation_degen_oaa or class({})

function modifier_faceless_void_time_dilation_degen_oaa:IsHidden()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:IsDebuff()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:IsPurgable()
  return true
end

function modifier_faceless_void_time_dilation_degen_oaa:OnCreated()
  self.heal_prevent_percent = -10

  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.heal_prevent_percent = 0 - math.abs(ability:GetSpecialValueFor("heal_prevent_percent"))
  end
end

modifier_faceless_void_time_dilation_degen_oaa.OnRefresh = modifier_faceless_void_time_dilation_degen_oaa.OnCreated

function modifier_faceless_void_time_dilation_degen_oaa:OnDestroy()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() then
    return
  end
  local mods = parent:FindAllModifiersByName("modifier_item_enhancement_crude")
  for _, mod in pairs(mods) do
    if mod and not mod:IsNull() then
      local mod_ability = mod:GetAbility()
      local mod_caster = mod:GetCaster()
      if mod_ability and mod_caster then
        if mod_ability == ability and mod_caster == caster then
          mod:Destroy()
          break
        end
      end
    end
  end
end

function modifier_faceless_void_time_dilation_degen_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_faceless_void_time_dilation_degen_oaa:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

-- Doesn't work, Thanks Valve!
-- function modifier_faceless_void_time_dilation_degen_oaa:GetModifierLifestealRegenAmplify_Percentage()
  -- return self.heal_prevent_percent
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_faceless_void_time_dilation_degen_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return self.heal_prevent_percent
-- end
