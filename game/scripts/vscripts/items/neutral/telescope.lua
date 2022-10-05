LinkLuaModifier("modifier_item_telescope_oaa_effect", "items/neutral/telescope.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_telescope_oaa_aura", "items/neutral/telescope.lua", LUA_MODIFIER_MOTION_NONE)

item_telescope_oaa = class(ItemBaseClass)

function item_telescope_oaa:GetIntrinsicModifierName()
  return "modifier_item_telescope_oaa_aura"
end

---------------------------------------------------------------------------------------------------
modifier_item_telescope_oaa_aura = class(ModifierBaseClass)

function modifier_item_telescope_oaa_aura:IsHidden()
  return true
end

function modifier_item_telescope_oaa_aura:IsDebuff()
  return false
end

function modifier_item_telescope_oaa_aura:IsPurgable()
  return false
end

function modifier_item_telescope_oaa_aura:IsAura()
  return true
end

function modifier_item_telescope_oaa_aura:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.aura_radius = ability:GetSpecialValueFor("aura_range")
  end
end

modifier_item_telescope_oaa_aura.OnRefresh = modifier_item_telescope_oaa_aura.OnCreated

function modifier_item_telescope_oaa_aura:GetAuraRadius()
  return self.aura_radius or 1200
end

function modifier_item_telescope_oaa_aura:GetModifierAura()
  return "modifier_item_telescope_oaa_effect"
end

function modifier_item_telescope_oaa_aura:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_telescope_oaa_aura:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

--function modifier_item_telescope_oaa_aura:GetAuraSearchFlags()
  --return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
--end
---------------------------------------------------------------------------------------------------

modifier_item_telescope_oaa_effect = class(ModifierBaseClass)

function modifier_item_telescope_oaa_effect:IsHidden()
  return false
end

function modifier_item_telescope_oaa_effect:IsDebuff()
  return false
end

function modifier_item_telescope_oaa_effect:IsPurgable()
  return false
end

function modifier_item_telescope_oaa_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_range = ability:GetSpecialValueFor("bonus_attack_range")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
    self.vision = ability:GetSpecialValueFor("bonus_vision")
  end
end

modifier_item_telescope_oaa_effect.OnRefresh = modifier_item_telescope_oaa_effect.OnCreated

function modifier_item_telescope_oaa_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    MODIFIER_PROPERTY_BONUS_DAY_VISION,
    MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
  }
end

function modifier_item_telescope_oaa_effect:GetModifierAttackRangeBonus()
  if self:GetParent():IsRangedAttacker() then
    return self.attack_range or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
  end

  return 0
end

function modifier_item_telescope_oaa_effect:GetModifierCastRangeBonusStacking()
  return self.cast_range or self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end

function modifier_item_telescope_oaa_effect:GetBonusDayVision()
  return self.vision or self:GetAbility():GetSpecialValueFor("bonus_vision")
end

function modifier_item_telescope_oaa_effect:GetBonusNightVision()
  return self.vision or self:GetAbility():GetSpecialValueFor("bonus_vision")
end

function modifier_item_telescope_oaa_effect:GetTexture()
  return "item_spy_gadget"
end
