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

function crystal_maiden_arcane_magic_oaa:GetBehavior()
  if self:GetSpecialValueFor("activatable") == 1 then
    return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT
  end
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function crystal_maiden_arcane_magic_oaa:GetCooldown(level)
  if self:GetSpecialValueFor("activatable") == 1 then
    local cd = self:GetSpecialValueFor("activation_cooldown")
    if cd > 0 then
      return cd
    end
  end
  return 0
end

function crystal_maiden_arcane_magic_oaa:CastFilterResult()
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResult(self)

  if caster:HasModifier("modifier_crystal_maiden_freezing_field") then
    return UF_FAIL_CUSTOM
  end

  return defaultFilterResult
end

function crystal_maiden_arcane_magic_oaa:GetCustomCastError()
  local caster = self:GetCaster()
  if caster:HasModifier("modifier_crystal_maiden_freezing_field") then
    return "#dota_hud_error_ability_inactive"
  end
end

function crystal_maiden_arcane_magic_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local vanilla_ability = caster:FindAbilityByName("crystal_maiden_brilliance_aura")
  if vanilla_ability then
    vanilla_ability:OnSpellStart()
  end
end

function crystal_maiden_arcane_magic_oaa:ProcsMagicStick()
  if self:GetSpecialValueFor("activatable") == 1 then
    return true
  end
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
  return 30000
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
    --self.int = ability:GetSpecialValueFor("bonus_intelligence")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
  end
end

modifier_crystal_maiden_arcane_aura_effect_oaa.OnRefresh = modifier_crystal_maiden_arcane_aura_effect_oaa.OnCreated

function modifier_crystal_maiden_arcane_aura_effect_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, -- GetModifierSpellAmplify_Percentage
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    --MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, -- GetModifierBonusStats_Intellect
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

-- function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierBonusStats_Intellect()
  -- return self.int or self:GetAbility():GetSpecialValueFor("bonus_intelligence")
-- end

function modifier_crystal_maiden_arcane_aura_effect_oaa:GetModifierCastRangeBonusStacking()
  return self.cast_range or self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:OnTooltip()
  --return self.mana_cost_reduction
--end

--function modifier_crystal_maiden_arcane_aura_effect_oaa:OnTooltip2()
  --return self.spell_amp
--end
