LinkLuaModifier("modifier_nevermore_dark_lord_oaa", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_nevermore_dark_lord_oaa_armor_debuff", "abilities/oaa_nevermore_dark_lord.lua", LUA_MODIFIER_MOTION_NONE)

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
  local armor_reduction = self:GetAbility():GetSpecialValueFor("armor_reduction")

  -- Talent that improves armor reduction
  local talent = caster:FindAbilityByName("special_bonus_unique_nevermore_5")
  if talent and talent:GetLevel() > 0 then
    armor_reduction = math.abs(armor_reduction) + math.abs(talent:GetSpecialValueFor("value"))
  end

  self.armor_reduction = armor_reduction

  --self.magic_resistance = 0
  --if caster:HasShardOAA() then
    --self.magic_resistance = -14
  --end
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:OnRefresh()
  self:OnCreated()
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    --MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
  }
end

function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierPhysicalArmorBonus()
  return 0 - math.abs(self.armor_reduction)
end

-- function modifier_nevermore_dark_lord_oaa_armor_debuff:GetModifierMagicalResistanceBonus()
  -- return self.magic_resistance
-- end
