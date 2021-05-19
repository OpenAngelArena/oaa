razor_storm_surge_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_razor_storm_surge_oaa", "abilities/oaa_razor_storm_surge.lua", LUA_MODIFIER_MOTION_NONE)

function razor_storm_surge_oaa:GetIntrinsicModifierName()
  return "modifier_razor_storm_surge_oaa"
end

function razor_storm_surge_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("razor_unstable_current")

	-- Check to not enter a level up loop
  if vanilla_ability and vanilla_ability:GetLevel() ~= ability_level then
    vanilla_ability:SetLevel(ability_level)
  end
end

function razor_storm_surge_oaa:IsStealable()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_razor_storm_surge_oaa = class(ModifierBaseClass)

function modifier_razor_storm_surge_oaa:IsHidden()
  return true
end

function modifier_razor_storm_surge_oaa:IsDebuff()
  return false
end

function modifier_razor_storm_surge_oaa:IsPurgable()
  return false
end

function modifier_razor_storm_surge_oaa:RemoveOnDeath()
  return false
end

function modifier_razor_storm_surge_oaa:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.attack_projectile_speed = ability:GetSpecialValueFor("bonus_attack_projectile_speed")
  end
end

function modifier_razor_storm_surge_oaa:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
    self.attack_projectile_speed = ability:GetSpecialValueFor("bonus_attack_projectile_speed")
  end
end

function modifier_razor_storm_surge_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
  }
end

function modifier_razor_storm_surge_oaa:GetModifierAttackSpeedBonus_Constant()
  if self:GetParent():PassivesDisabled() then
    return 0
  end
  return self.attack_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_razor_storm_surge_oaa:GetModifierProjectileSpeedBonus()
  if self:GetParent():PassivesDisabled() then
    return 0
  end
  return self.attack_projectile_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_projectile_speed")
end
