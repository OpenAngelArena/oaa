LinkLuaModifier("modifier_item_creed_of_omniscience_passive", "items/neutral/creed_of_omniscience.lua", LUA_MODIFIER_MOTION_NONE)

item_creed_of_omniscience = class(ItemBaseClass)

function item_creed_of_omniscience:GetIntrinsicModifierName()
  return "modifier_item_creed_of_omniscience_passive"
end

---------------------------------------------------------------------------------------------------

modifier_item_creed_of_omniscience_passive = class(ModifierBaseClass)

function modifier_item_creed_of_omniscience_passive:IsHidden()
  return true
end
function modifier_item_creed_of_omniscience_passive:IsDebuff()
  return false
end
function modifier_item_creed_of_omniscience_passive:IsPurgable()
  return false
end

function modifier_item_creed_of_omniscience_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.attack_range_ranged = ability:GetSpecialValueFor("bonus_attack_range")
    self.attack_range_melee = ability:GetSpecialValueFor("bonus_attack_range_melee")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
    self.attack_projectile_speed = ability:GetSpecialValueFor("bonus_attack_projectile_speed")
  end
end

function modifier_item_creed_of_omniscience_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.attack_range_ranged = ability:GetSpecialValueFor("bonus_attack_range")
    self.attack_range_melee = ability:GetSpecialValueFor("bonus_attack_range_melee")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
    self.attack_projectile_speed = ability:GetSpecialValueFor("bonus_attack_projectile_speed")
  end
end

function modifier_item_creed_of_omniscience_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS,
    MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
  }
end

function modifier_item_creed_of_omniscience_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_creed_of_omniscience_passive:GetModifierAttackRangeBonus()
  if self:GetParent():IsRangedAttacker() then
    return self.attack_range_ranged or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
  end

  return self.attack_range_melee or self:GetAbility():GetSpecialValueFor("bonus_attack_range_melee")
end

function modifier_item_creed_of_omniscience_passive:GetModifierCastRangeBonus()
  return self.cast_range or self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end

function modifier_item_creed_of_omniscience_passive:GetModifierProjectileSpeedBonus()
  return self.attack_projectile_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_projectile_speed")
end
