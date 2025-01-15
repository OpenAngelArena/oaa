lycan_feral_movement_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_lycan_feral_movement_aura_oaa", "abilities/oaa_lycan_feral_movement.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lycan_feral_movement_effect_oaa", "abilities/oaa_lycan_feral_movement.lua", LUA_MODIFIER_MOTION_NONE)

function lycan_feral_movement_oaa:GetIntrinsicModifierName()
  return "modifier_lycan_feral_movement_aura_oaa"
end

function lycan_feral_movement_oaa:OnHeroCalculateStatBonus()
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

function lycan_feral_movement_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_lycan_feral_movement_aura_oaa = class(ModifierBaseClass)

function modifier_lycan_feral_movement_aura_oaa:IsHidden()
  return true
end

function modifier_lycan_feral_movement_aura_oaa:IsDebuff()
  return false
end

function modifier_lycan_feral_movement_aura_oaa:IsPurgable()
  return false
end

function modifier_lycan_feral_movement_aura_oaa:RemoveOnDeath()
  return false
end

function modifier_lycan_feral_movement_aura_oaa:IsAura()
  if self:GetParent():PassivesDisabled() then
    return false
  end
  return true
end

function modifier_lycan_feral_movement_aura_oaa:GetModifierAura()
  return "modifier_lycan_feral_movement_effect_oaa"
end

function modifier_lycan_feral_movement_aura_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_lycan_feral_movement_aura_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_lycan_feral_movement_aura_oaa:GetAuraRadius()
  return self:GetAbility():GetSpecialValueFor("radius")
end

---------------------------------------------------------------------------------------------------

modifier_lycan_feral_movement_effect_oaa = class(ModifierBaseClass)

function modifier_lycan_feral_movement_effect_oaa:IsHidden()
  return false
end

function modifier_lycan_feral_movement_effect_oaa:IsDebuff()
  return false
end

function modifier_lycan_feral_movement_effect_oaa:IsPurgable()
  return false
end

function modifier_lycan_feral_movement_effect_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed_flat = ability:GetSpecialValueFor("attack_speed_flat")
    self.attack_speed_pct = ability:GetSpecialValueFor("attack_speed_pct")
    self.evasion = ability:GetSpecialValueFor("evasion")
  else
    self.attack_speed_flat = 0
    self.attack_speed_pct = 0
    self.evasion = 15
  end
end

modifier_lycan_feral_movement_effect_oaa.OnRefresh = modifier_lycan_feral_movement_effect_oaa.OnCreated

function modifier_lycan_feral_movement_effect_oaa:CheckState()
  return {
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
  }
end

function modifier_lycan_feral_movement_effect_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_PERCENTAGE,
    MODIFIER_PROPERTY_EVASION_CONSTANT,
  }
end

function modifier_lycan_feral_movement_effect_oaa:GetModifierAttackSpeedBonus_Constant()
  return math.abs(self.attack_speed_flat)
end

function modifier_lycan_feral_movement_effect_oaa:GetModifierAttackSpeedPercentage()
  return math.abs(self.attack_speed_pct)
end

function modifier_lycan_feral_movement_effect_oaa:GetModifierEvasion_Constant()
  return self.evasion
end
