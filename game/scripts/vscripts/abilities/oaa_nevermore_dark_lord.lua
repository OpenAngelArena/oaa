LinkLuaModifier("modifier_nevermore_dark_lord_oaa", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_dark_lord_oaa_armor_debuff", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_special_bonus_unique_nevermore_armor_reduction", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)

nevermore_dark_lord_oaa = class(AbilityBaseClass)

function nevermore_dark_lord_oaa:GetIntrinsicModifierName()
  return "modifier_nevermore_dark_lord_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_nevermore_dark_lord_oaa = class(ModifierBaseClass)

function modifier_nevermore_dark_lord_oaa:IsHidden()
  return true
end

function modifier_nevermore_dark_lord_oaa:IsPurgable()
  return false
end

function modifier_nevermore_dark_lord_oaa:RemoveOnDeath()
  return false
end

function modifier_nevermore_dark_lord_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_nevermore_dark_lord_oaa:GetModifierAura()
  return "modifier_nevermore_dark_lord_oaa_armor_debuff"
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_nevermore_dark_lord_oaa:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_nevermore_dark_lord_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("aura_radius")
end

---------------------------------------------------------------------------------------------------

modifier_nevermore_dark_lord_oaa_armor_debuff = class(ModifierBaseClass)

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsHidden()
  return true
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsDebuff()
  return true
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:IsPurgable()
  return false
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:OnCreated()
  local caster = self:GetCaster()
  self.armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")
  self.magic_resistance = 0
  if IsServer() then
    local talent = caster:FindAbilityByName("special_bonus_unique_nevermore_5")
    if talent and talent:GetLevel() > 0 then
      local armor_reduction = self.armor_reduction + talent:GetSpecialValueFor("value")
      self.armor_reduction = armor_reduction
      caster:AddNewModifier(caster, talent, "modifier_special_bonus_unique_nevermore_armor_reduction", {})
    else
      caster:RemoveModifierByName("modifier_special_bonus_unique_nevermore_armor_reduction")
    end
  else
    if caster:HasModifier("modifier_special_bonus_unique_nevermore_armor_reduction") and caster.special_bonus_unique_nevermore_armor_reduction then
      local armor_reduction = self.armor_reduction + caster.special_bonus_unique_nevermore_armor_reduction
      self.armor_reduction = armor_reduction
    end
  end

  if caster:HasShardOAA() then
    self.magic_resistance = -14
  end
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:OnRefresh()
  self:OnCreated()
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
  return funcs
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierPhysicalArmorBonus()
  return self.armor_reduction
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierMagicalResistanceBonus()
  return self.magic_resistance
end

---------------------------------------------------------------------------------------------------

-- Modifier on caster used for talent that improve aura armor reduction
modifier_special_bonus_unique_nevermore_armor_reduction = class(ModifierBaseClass)

function modifier_special_bonus_unique_nevermore_armor_reduction:IsHidden()
  return true
end

function modifier_special_bonus_unique_nevermore_armor_reduction:IsPurgable()
  return false
end

function modifier_special_bonus_unique_nevermore_armor_reduction:RemoveOnDeath()
  return false
end

function modifier_special_bonus_unique_nevermore_armor_reduction:OnCreated()
  if not IsServer() then
    local parent = self:GetParent()
    local talent = self:GetAbility()
    parent.special_bonus_unique_nevermore_armor_reduction = talent:GetSpecialValueFor("value")
  end
end

function modifier_special_bonus_unique_nevermore_armor_reduction:OnDestroy()
  local parent = self:GetParent()
  if parent and parent.special_bonus_unique_nevermore_armor_reduction then
    parent.special_bonus_unique_nevermore_armor_reduction = nil
  end
end
