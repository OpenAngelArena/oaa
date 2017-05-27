LinkLuaModifier( "modifier_item_heart_transplant", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_debuff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_buff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )

local heartTransplantDebuffName = "modifier_item_heart_transplant_debuff"

item_heart_transplant = class({})

function item_heart_transplant:GetIntrinsicModifierName()
  return "modifier_item_heart_transplant"
end

function item_heart_transplant:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  if defaultFilterResult ~= UF_SUCCESS then
    return defaultFilterResult
  elseif target == caster then
    return UF_FAIL_CUSTOM
  end
end

function item_heart_transplant:GetCustomCastErrorTarget(target)
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  end
end

function item_heart_transplant:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")
  local transplant_cooldown = self:GetSpecialValueFor("transplant_cooldown")

  self:StartCooldown(transplant_cooldown)

  target:AddNewModifier(caster, self, "modifier_item_heart_transplant_buff", {
    duration = duration
  })
  caster:AddNewModifier(caster, self, "modifier_item_heart_transplant_debuff", {
    duration = duration
  })
end

item_heart_transplant_2 = item_heart_transplant

------------------------------------------------------------------------------------------

modifier_item_heart_transplant = class({})

function modifier_item_heart_transplant:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

function modifier_item_heart_transplant:IsHidden()
  return true
end

function modifier_item_heart_transplant:IsPurgable()
  return false
end

function modifier_item_heart_transplant:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_transplant:GetModifierBonusStats_Strength()
  local parent = self:GetParent()

  if parent:HasModifier(heartTransplantDebuffName) then
    return 0
  else
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
  end
end

function modifier_item_heart_transplant:GetModifierHealthBonus()
  local parent = self:GetParent()

  if parent:HasModifier(heartTransplantDebuffName) then
    return 0
  else
    return self:GetAbility():GetSpecialValueFor("bonus_health")
  end
end

function modifier_item_heart_transplant:GetModifierHealthRegenPercentage()
  local parent = self:GetParent()
  local heart = self:GetAbility()

  if heart:IsCooldownReady() and not parent:IsIllusion() and not parent:HasModifier("modifier_item_heart_transplant_debuff") then
    return heart:GetSpecialValueFor("health_regen_rate")
  else
    return 0
  end
end

function modifier_item_heart_transplant:OnTakeDamage(keys)
  local parent = self:GetParent()
  local heart = self:GetAbility()
  local breakDuration = heart:GetSpecialValueFor("cooldown_melee")
  if parent:IsRangedAttacker() then
    breakDuration = heart:GetSpecialValueFor("cooldown_ranged_tooltip")
  end

  if keys.damage > 0 and keys.unit == parent and keys.attacker ~= parent and not keys.attacker:IsNeutralUnitType() and not keys.attacker:IsCreature() then
    heart:StartCooldown(breakDuration)
  end
end

------------------------------------------------------------------------------------------

modifier_item_heart_transplant_debuff = class({})

function modifier_item_heart_transplant_debuff:IsDebuff()
  return true
end

function modifier_item_heart_transplant_debuff:IsPurgable()
  return false
end

function modifier_item_heart_transplant_debuff:IsPurgeException()
  return false
end

-- function modifier_item_heart_transplant_debuff:DeclareFunctions()
--   return {
--     MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
--     MODIFIER_PROPERTY_HEALTH_BONUS
--   }
-- end

-- function modifier_item_heart_transplant_debuff:GetModifierBonusStats_Strength()
--   return 0 - self:GetAbility():GetSpecialValueFor("bonus_strength")
-- end

-- function modifier_item_heart_transplant_debuff:GetModifierHealthBonus()
--   return 0 - self:GetAbility():GetSpecialValueFor("bonus_health")
-- end

------------------------------------------------------------------------------------------

modifier_item_heart_transplant_buff = class({})

function modifier_item_heart_transplant_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
  }
end

function modifier_item_heart_transplant_buff:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heart_transplant_buff:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_heart_transplant_buff:GetModifierHealthRegenPercentage()
  local heart = self:GetAbility()

  return heart:GetSpecialValueFor("health_regen_rate")
end
