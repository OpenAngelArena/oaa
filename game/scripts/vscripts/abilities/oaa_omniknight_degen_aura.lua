omniknight_degen_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_omniknight_degen_aura_oaa", "abilities/oaa_omniknight_degen_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_omniknight_degen_aura_effect_oaa", "abilities/oaa_omniknight_degen_aura.lua", LUA_MODIFIER_MOTION_NONE)

function omniknight_degen_aura_oaa:GetIntrinsicModifierName()
  return "modifier_omniknight_degen_aura_oaa"
end

--[[
function omniknight_degen_aura_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("omniknight_degen_aura")

	-- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end
]]

function omniknight_degen_aura_oaa:OnHeroCalculateStatBonus()
  local caster = self:GetCaster()

  if caster:HasShardOAA() then
    self:SetHidden(false)
    if self:GetLevel() <= 0 then
      self:SetLevel(1)
    end
  else
    self:SetHidden(true)
    --self:SetLevel(0)
  end
end

function omniknight_degen_aura_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_omniknight_degen_aura_oaa = class(ModifierBaseClass)

function modifier_omniknight_degen_aura_oaa:IsHidden()
  return true
end

function modifier_omniknight_degen_aura_oaa:IsDebuff()
  return false
end

function modifier_omniknight_degen_aura_oaa:IsPurgable()
  return false
end

function modifier_omniknight_degen_aura_oaa:RemoveOnDeath()
  return false
end

function modifier_omniknight_degen_aura_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_omniknight_degen_aura_oaa:GetModifierAura()
  return "modifier_omniknight_degen_aura_effect_oaa"
end

function modifier_omniknight_degen_aura_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_omniknight_degen_aura_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_omniknight_degen_aura_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

---------------------------------------------------------------------------------------------------

modifier_omniknight_degen_aura_effect_oaa = class(ModifierBaseClass)

function modifier_omniknight_degen_aura_effect_oaa:IsHidden()
  return false
end

function modifier_omniknight_degen_aura_effect_oaa:IsDebuff()
  return true
end

function modifier_omniknight_degen_aura_effect_oaa:IsPurgable()
  return false
end

function modifier_omniknight_degen_aura_effect_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
    self.move_slow = ability:GetSpecialValueFor("move_speed_slow")
  else
    self.heal_prevent_percent = -6
    self.attack_slow = -10
    self.move_slow = -10
  end
end

function modifier_omniknight_degen_aura_effect_oaa:OnRefresh()
  local ability = self:GetAbility()
  if ability then
    self.heal_prevent_percent = ability:GetSpecialValueFor("heal_prevent_percent")
    self.attack_slow = ability:GetSpecialValueFor("attack_speed_slow")
    self.move_slow = ability:GetSpecialValueFor("move_speed_slow")
  else
    self.heal_prevent_percent = -6
    self.attack_slow = -10
    self.move_slow = -10
  end
end

function modifier_omniknight_degen_aura_effect_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET,
    --MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
    --MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
  }
end

function modifier_omniknight_degen_aura_effect_oaa:GetModifierMoveSpeedBonus_Percentage()
  return self.move_slow
end

function modifier_omniknight_degen_aura_effect_oaa:GetModifierAttackSpeedBonus_Constant()
  return self.attack_slow
end

function modifier_omniknight_degen_aura_effect_oaa:GetModifierHealAmplify_PercentageTarget()
  return self.heal_prevent_percent
end

function modifier_omniknight_degen_aura_effect_oaa:GetModifierHPRegenAmplify_Percentage()
  return self.heal_prevent_percent
end

-- Doesn't work, Thanks Valve!
-- function modifier_omniknight_degen_aura_effect_oaa:GetModifierLifestealRegenAmplify_Percentage()
  -- return self.heal_prevent_percent
-- end

-- Doesn't work, Thanks Valve!
-- function modifier_omniknight_degen_aura_effect_oaa:GetModifierSpellLifestealRegenAmplify_Percentage()
  -- return self.heal_prevent_percent
-- end

function modifier_omniknight_degen_aura_effect_oaa:GetEffectName()
  return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_omniknight_degen_aura_effect_oaa:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
