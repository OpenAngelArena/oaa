item_sonic = class(ItemBaseClass)

LinkLuaModifier("modifier_item_sonic", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sonic_fly", "modifiers/modifier_sonic_fly.lua", LUA_MODIFIER_MOTION_NONE)

function item_sonic:GetIntrinsicModifierName()
  return "modifier_sonic_fly"
end

function item_sonic:OnToggle()
  local caster = self.GetCaster()
  local state = self.GetToggleState()
  local ability = self.GetAbility()

  if state == true then
    caster.AddNewModifier(caster, self, "modifier_sonic_fly", {})
  else
    caster.RemoveModifierByName("modifier_sonic_fly")
  end
  ability:StartCooldown(ability:GetCooldown(ability:GetLevel()))
end

function item_sonic:OnOwnerDied()
  local owner = self.GetOwner()
  if owner.HasModifier("modifier_sonic_fly") then
    owner.RemoveModifierByName("modifier_sonic_fly")
  end
end

modifier_item_sonic = class(ModifierBaseClass)

function modifier_item_sonic:IsHidden()
  return true
end

function modifier_item_sonic:IsPurgable()
  return false
end

function modifier_item_sonic:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT
  }
end

function modifier_item_sonic:GetModifierBonusStats_Intellect()
  return self.GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_sonic:GetModifierBonusStats_Strength()
  return self.GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_sonic:GetModifierBonusStats_Agility()
  return self.GetAbility():GetSpecialValueFor("bonus_agi")
end

function modifier_item_sonic:GetModifierConstantManaRegen()
  return self.GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

