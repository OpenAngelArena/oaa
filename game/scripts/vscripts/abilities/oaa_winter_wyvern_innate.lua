-- Eldwurm Wisdom

LinkLuaModifier("modifier_winter_wyvern_innate_oaa", "abilities/oaa_winter_wyvern_innate.lua", LUA_MODIFIER_MOTION_NONE)

winter_wyvern_innate_oaa = class(AbilityBaseClass)

function winter_wyvern_innate_oaa:GetIntrinsicModifierName()
  return "modifier_winter_wyvern_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_winter_wyvern_innate_oaa = class(ModifierBaseClass)

function modifier_winter_wyvern_innate_oaa:IsHidden()
  return true
end

function modifier_winter_wyvern_innate_oaa:IsDebuff()
  return false
end

function modifier_winter_wyvern_innate_oaa:IsPurgable()
  return false
end

function modifier_winter_wyvern_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_winter_wyvern_innate_oaa:OnCreated()
  self.bonus_spell_amp_per_mana = self:GetAbility():GetSpecialValueFor("spell_amp_per_mana")
end

function modifier_winter_wyvern_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_winter_wyvern_innate_oaa:GetModifierSpellAmplify_Percentage()
  local parent = self:GetParent()
  if parent:PassivesDisabled() then
    return 0
  end
  return self.bonus_spell_amp_per_mana * parent:GetMaxMana()
end
