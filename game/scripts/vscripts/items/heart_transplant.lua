LinkLuaModifier( "modifier_item_heart", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_debuff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_buff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )

item_heart_transplant = class({})

function item_heart_transplant:GetIntrinsicModifierName()
  return "modifier_item_heart"
end

function item_heart_transplant:OnSpellStart()
  local charges = self:GetCurrentCharges()
  if charges <= 0 then
    return false
  end

  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")
  local transplant_cooldown = self:GetSpecialValueFor("transplant_cooldown")

  self:SetCurrentCharges( 0 )

  target:AddNewModifier(caster, self, "modifier_item_heart", {
    duration = duration
  })
  target:AddNewModifier(caster, self, "modifier_item_heart_transplant_buff", {
    duration = duration
  })
  caster:AddNewModifier(caster, self, "modifier_item_heart_transplant_debuff", {
    duration = duration
  })

  Timers:CreateTimer(transplant_cooldown, function()
    self:SetCurrentCharges(1)
  end)

  return false
end

item_heart_transplant_2 = item_heart_transplant

------------------------------------------------------------------------------------------

modifier_item_heart_transplant_debuff = class({})
modifier_item_heart_transplant_buff = class({})

function modifier_item_heart_transplant_debuff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
  }
end

function modifier_item_heart_transplant_debuff:GetModifierBonusStats_Strength()
  return 0 - self:GetAbility():GetSpecialValueFor("bonus_strength")
end
function modifier_item_heart_transplant_debuff:GetModifierHealthBonus()
  return 0 - self:GetAbility():GetSpecialValueFor("bonus_health")
end
function modifier_item_heart_transplant_debuff:GetModifierHealthRegenPercentage()
  local caster = self:GetCaster()
  local heart = self:GetAbility()

  if heart:IsCooldownReady() then
    return 0 - heart:GetSpecialValueFor("health_regen_rate")
  else
    return 0
  end
end
