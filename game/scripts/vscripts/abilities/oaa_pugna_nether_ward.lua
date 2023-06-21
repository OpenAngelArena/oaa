pugna_nether_ward_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_pugna_nether_ward_oaa", "abilities/oaa_pugna_nether_ward.lua", LUA_MODIFIER_MOTION_NONE)

function pugna_nether_ward_oaa:GetIntrinsicModifierName()
  if self:GetLevel() >= 5 then
    return "modifier_pugna_nether_ward_oaa"
  end
end

function pugna_nether_ward_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()

  local vanilla_ability = caster:FindAbilityByName("pugna_nether_ward")
  if not vanilla_ability then
    return
  end

  if ability_level > 4 then
    vanilla_ability:SetLevel(4)
    return
  end

  vanilla_ability:SetLevel(ability_level)
end

function pugna_nether_ward_oaa:OnSpellStart()
  local caster = self:GetCaster()
  --local level = self:GetLevel()
  local ability = caster:FindAbilityByName("pugna_nether_ward")

  if not ability then
    return
  end

  -- Cast the vanilla ability
  caster:SetCursorPosition(self:GetCursorPosition())
  ability:OnSpellStart()

  --caster:CastAbilityOnPosition(self:GetCursorPosition(), ability, caster:GetPlayerID())
end

function pugna_nether_ward_oaa:GetAssociatedSecondaryAbilities()
  return "pugna_nether_ward"
end

function pugna_nether_ward_oaa:OnStolen(hSourceAbility)
  -- local caster = self:GetCaster()
  -- local vanilla_ability = caster:FindAbilityByName("pugna_nether_ward")
  -- if not vanilla_ability then
    -- return
  -- end
  -- vanilla_ability:SetHidden(true) -- doesn't work
  self:SetHidden(true) -- doesn't work for Morphling
end

function pugna_nether_ward_oaa:OnUnStolen()
  local caster = self:GetCaster()
  if caster:HasModifier("modifier_pugna_nether_ward_oaa") then
    caster:RemoveModifierByName("modifier_pugna_nether_ward_oaa")
  end
end

-- Doesn't work for Rubick Spell Steal
--function pugna_nether_ward_oaa:IsHiddenWhenStolen()
  --return true
--end

---------------------------------------------------------------------------------------------------

modifier_pugna_nether_ward_oaa = class(ModifierBaseClass)

function modifier_pugna_nether_ward_oaa:IsHidden()
  return true
end

function modifier_pugna_nether_ward_oaa:IsDebuff()
  return false
end

function modifier_pugna_nether_ward_oaa:IsPurgable()
  return false
end

function modifier_pugna_nether_ward_oaa:RemoveOnDeath()
  return false
end

function modifier_pugna_nether_ward_oaa:OnCreated()
  self.keyvalues_to_upgrade = {
    "AbilityDuration",
    "base_damage",
    "mana_multiplier",
  }
end

function modifier_pugna_nether_ward_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE
  }
end

function modifier_pugna_nether_ward_oaa:GetModifierOverrideAbilitySpecial(keys)
  local ability = self:GetAbility()
  if not ability or not keys.ability or not keys.ability_special_value then
    return 0
  end

  if keys.ability:GetAbilityName() ~= "pugna_nether_ward" then
    return 0
  end

  local level = ability:GetLevel()
  if level <= 4 then
    return 0
  end

  for _, v in pairs(self.keyvalues_to_upgrade) do
    if keys.ability_special_value == v then
      return 1
    end
  end

  return 0
end

function modifier_pugna_nether_ward_oaa:GetModifierOverrideAbilitySpecialValue(keys)
  local ability = self:GetAbility()
  local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)

  if ability then
    if keys.ability:GetAbilityName() ~= "pugna_nether_ward" or ability:GetLevel() <= 4 then
      return value
    end

    for _, v in pairs(self.keyvalues_to_upgrade) do
      local new_value = ability:GetLevelSpecialValueFor(v, ability:GetLevel()-1)
      if keys.ability_special_value == v then
        return new_value
      end
    end
  end

  return value
end
