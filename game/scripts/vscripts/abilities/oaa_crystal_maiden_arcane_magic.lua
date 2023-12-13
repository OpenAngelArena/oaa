crystal_maiden_arcane_magic_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_crystal_maiden_arcane_aura_oaa", "abilities/oaa_crystal_maiden_arcane_magic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_crystal_maiden_arcane_aura_effect_oaa", "abilities/oaa_crystal_maiden_arcane_magic.lua", LUA_MODIFIER_MOTION_NONE)

function crystal_maiden_arcane_magic_oaa:GetIntrinsicModifierName()
  return "modifier_crystal_maiden_arcane_aura_oaa"
end

function crystal_maiden_arcane_magic_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("crystal_maiden_brilliance_aura")

	-- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end

function crystal_maiden_arcane_magic_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_crystal_maiden_arcane_aura_oaa = class(ModifierBaseClass)

function modifier_crystal_maiden_arcane_aura_oaa:IsHidden()
  return true
end

function modifier_crystal_maiden_arcane_aura_oaa:IsDebuff()
  return false
end

function modifier_crystal_maiden_arcane_aura_oaa:IsPurgable()
  return false
end

function modifier_crystal_maiden_arcane_aura_oaa:RemoveOnDeath()
  return false
end

function modifier_crystal_maiden_arcane_aura_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_crystal_maiden_arcane_aura_oaa:GetModifierAura()
  return "modifier_crystal_maiden_arcane_aura_effect_oaa"
end

function modifier_crystal_maiden_arcane_aura_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_crystal_maiden_arcane_aura_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_crystal_maiden_arcane_aura_oaa:GetAuraRadius()
  return 20000
end

---------------------------------------------------------------------------------------------------

modifier_crystal_maiden_arcane_aura_effect_oaa = class(ModifierBaseClass)

function modifier_crystal_maiden_arcane_aura_effect_oaa:IsHidden()
  return false
end

function modifier_crystal_maiden_arcane_aura_effect_oaa:IsDebuff()
  return false
end

function modifier_crystal_maiden_arcane_aura_effect_oaa:IsPurgable()
  return false
end

function modifier_crystal_maiden_arcane_aura_effect_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    --self.mana_cost_reduction = ability:GetSpecialValueFor("mana_cost_reduction_pct")
    self.spell_amp = ability:GetSpecialValueFor("bonus_spell_amp")
    --self.cd_reduction = ability:GetSpecialValueFor("cd_reduction")
    --self.mana_regen = ability:GetSpecialValueFor("mana_regen")
    --self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resistance")
    self.int = ability:GetSpecialValueFor("bonus_intelligence")
  end
end

modifier_crystal_maiden_arcane_aura_effect_oaa.OnRefresh = modifier_crystal_maiden_arcane_aura_effect_oaa.OnCreated

function modifier_crystal_maiden_arcane_aura_effect_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
    --MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING, --GetModifierPercentageManacostStacking
    --MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, -- GetModifierPercentageCooldown
    --MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, -- GetModifierConstantManaRegen
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, -- GetModifierMagicalResistanceBonus
    --MODIFIER_PROPERTY_TOOLTIP, -- OnTooltip
    --MODIFIER_PROPERTY_TOOLTIP2, -- OnTooltip2
  }
end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierPercentageManacostStacking()
  --return self.mana_cost_reduction or self:GetAbility():GetSpecialValueFor("mana_cost_reduction_pct")
--end

function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierSpellAmplify_Percentage()
  return self.spell_amp or self:GetAbility():GetSpecialValueFor("bonus_spell_amp")
end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierPercentageCooldown()
  --return self.cd_reduction or self:GetAbility():GetSpecialValueFor("cd_reduction")
--end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierConstantManaRegen()
  --return self.mana_regen or self:GetAbility():GetSpecialValueFor("mana_regen")
--end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierMagicalResistanceBonus()
  --return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resistance")
--end

function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierBonusStats_Intellect()
  return self.int or self:GetAbility():GetSpecialValueFor("bonus_intelligence")
end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:OnTooltip()
  --return self.mana_cost_reduction
--end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:OnTooltip2()
  --return self.spell_amp
--end
