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
    self.bonus_ms = ability:GetSpecialValueFor("bonus_move_speed")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intelligence")
    self.hp_regen = ability:GetSpecialValueFor("bonus_hp_regen")
    self.mana = ability:GetSpecialValueFor("bonus_mana")
    --self.attack_range_ranged = ability:GetSpecialValueFor("bonus_attack_range")
    --self.attack_range_melee = ability:GetSpecialValueFor("bonus_attack_range_melee")
    self.cast_range = ability:GetSpecialValueFor("bonus_cast_range")
    --self.attack_projectile_speed = ability:GetSpecialValueFor("bonus_attack_projectile_speed")
    self.turn_rate = ability:GetSpecialValueFor("bonus_turn_rate")
  end
end

modifier_item_creed_of_omniscience_passive.OnRefresh = modifier_item_creed_of_omniscience_passive.OnCreated

function modifier_item_creed_of_omniscience_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
    MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
    --MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    --MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
  }
end

function modifier_item_creed_of_omniscience_passive:GetModifierMoveSpeedBonus_Constant()
  return self.bonus_ms or self:GetAbility():GetSpecialValueFor("bonus_move_speed")
end

function modifier_item_creed_of_omniscience_passive:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_creed_of_omniscience_passive:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intelligence")
end

function modifier_item_creed_of_omniscience_passive:GetModifierConstantHealthRegen()
  return self.hp_regen or self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end

function modifier_item_creed_of_omniscience_passive:GetModifierManaBonus()
  return self.mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

-- function modifier_item_creed_of_omniscience_passive:GetModifierAttackRangeBonus()
  -- if self:GetParent():IsRangedAttacker() then
    -- return self.attack_range_ranged or self:GetAbility():GetSpecialValueFor("bonus_attack_range")
  -- end

  -- return self.attack_range_melee or self:GetAbility():GetSpecialValueFor("bonus_attack_range_melee")
-- end

function modifier_item_creed_of_omniscience_passive:GetModifierCastRangeBonusStacking()
  return self.cast_range or self:GetAbility():GetSpecialValueFor("bonus_cast_range")
end

-- function modifier_item_creed_of_omniscience_passive:GetModifierProjectileSpeedBonus()
  -- return self.attack_projectile_speed or self:GetAbility():GetSpecialValueFor("bonus_attack_projectile_speed")
-- end

function modifier_item_creed_of_omniscience_passive:GetModifierTurnRate_Percentage()
  return self.turn_rate or self:GetAbility():GetSpecialValueFor("bonus_turn_rate")
end
