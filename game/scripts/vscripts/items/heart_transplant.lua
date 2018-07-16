LinkLuaModifier( "modifier_item_heart_transplant", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_debuff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_buff", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_heart_transplant_buff_break", "items/heart_transplant.lua", LUA_MODIFIER_MOTION_NONE )

local heartTransplantDebuffName = "modifier_item_heart_transplant_debuff"

item_heart_transplant = class(ItemBaseClass)

function item_heart_transplant:GetIntrinsicModifierName()
  return "modifier_item_heart_transplant"
end

function item_heart_transplant:CastFilterResultTarget(target)
  local caster = self:GetCaster()
  local defaultFilterResult = self.BaseClass.CastFilterResultTarget(self, target)
  if defaultFilterResult ~= UF_SUCCESS then
    return defaultFilterResult
  elseif target == caster or (IsServer() and caster:FindModifierByName(heartTransplantDebuffName) and caster:FindModifierByName(heartTransplantDebuffName) ~= self.transplanted_modifier) then
    return UF_FAIL_CUSTOM
  end
end

function item_heart_transplant:GetCustomCastErrorTarget(target)
  local caster = self:GetCaster()
  if target == caster then
    return "#dota_hud_error_cant_cast_on_self"
  elseif IsServer() and caster:FindModifierByName(heartTransplantDebuffName) and caster:FindModifierByName(heartTransplantDebuffName) ~= self.transplanted_modifier then
    return "#oaa_hud_error_only_one_transplant"
  end
end

function item_heart_transplant:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()
  local duration = self:GetSpecialValueFor("duration")
  local transplant_cooldown = self:GetSpecialValueFor("transplant_cooldown")

  self:StartCooldown(transplant_cooldown)

  -- Only allow one active transfer
  if self.transferred_buff and not self.transferred_buff:IsNull() then
    self.transferred_buff:Destroy()
  end

  self.transferred_buff = target:AddNewModifier(caster, self, "modifier_item_heart_transplant_buff", {
    duration = duration
  })
  self.transplanted_modifier = caster:AddNewModifier(caster, self, heartTransplantDebuffName, {
    duration = duration
  })

  -- Store target so that the regen can be disabled when taking damage
  self.target = target
end

item_heart_transplant_2 = item_heart_transplant

------------------------------------------------------------------------------------------

modifier_item_heart_transplant = class(ModifierBaseClass)

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

function modifier_item_heart_transplant:OnCreated()
  self:GetAbility().intrinsic_modifier = self
end

function modifier_item_heart_transplant:GetModifierBonusStats_Strength()
  local parent = self:GetParent()

  if self.disabled then
    return 0
  else
    return self:GetAbility():GetSpecialValueFor("bonus_strength")
  end
end

function modifier_item_heart_transplant:GetModifierHealthBonus()
  local parent = self:GetParent()

  if self.disabled then
    return 0
  else
    return self:GetAbility():GetSpecialValueFor("bonus_health")
  end
end

if IsServer() then
  function modifier_item_heart_transplant:GetModifierHealthRegenPercentage()
    local parent = self:GetParent()
    local heart = self:GetAbility()
    local parentHasHeart = parent:HasModifier("modifier_item_heart")
    local parentHasGivenHeartAway = self.disabled
    local isFirstHeartTransplantModifier = parent:FindModifierByName(self:GetName()) == self

    if heart:IsCooldownReady() and not parent:IsIllusion() and not parentHasGivenHeartAway and not parentHasHeart and isFirstHeartTransplantModifier then
      return heart:GetSpecialValueFor("health_regen_rate")
    else
      return 0
    end
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
    -- Disable regen on transplanted target
    if heart.target then
      local targetBreakDuration = heart:GetSpecialValueFor("transplant_break_cooldown")
      heart.target:AddNewModifier(parent, heart, "modifier_item_heart_transplant_buff_break", {duration = targetBreakDuration})
    end
  end
end

------------------------------------------------------------------------------------------

modifier_item_heart_transplant_debuff = class(ModifierBaseClass)

function modifier_item_heart_transplant_debuff:IsDebuff()
  return true
end

function modifier_item_heart_transplant_debuff:IsPurgable()
  return false
end

function modifier_item_heart_transplant_debuff:IsPurgeException()
  return false
end

function modifier_item_heart_transplant_debuff:OnCreated()
  local intrinsic_modifier = self:GetAbility().intrinsic_modifier
  if intrinsic_modifier and not intrinsic_modifier:IsNull() then
    intrinsic_modifier.disabled = true
    self:GetParent():CalculateStatBonus()
  end
end

function modifier_item_heart_transplant_debuff:OnDestroy()
  local intrinsic_modifier = self:GetAbility().intrinsic_modifier
  if intrinsic_modifier and not intrinsic_modifier:IsNull() then
    intrinsic_modifier.disabled = false
    self:GetParent():CalculateStatBonus()
  end
  self:GetAbility().transplanted_modifier = nil
end

------------------------------------------------------------------------------------------

modifier_item_heart_transplant_buff = class(ModifierBaseClass)

function modifier_item_heart_transplant_buff:IsPurgable()
  return false
end

function modifier_item_heart_transplant_buff:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_transplant_buff:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE
  }
end

function modifier_item_heart_transplant_buff:OnCreated( table )
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if IsServer() then
    self.nPreviewFX = ParticleManager:CreateParticle("particles/items/heart_transplant/heart_transplant.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(self.nPreviewFX, 0, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.nPreviewFX, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
  end
end

function modifier_item_heart_transplant_buff:OnDestroy(  )
  if IsServer() then
    local parent_item = self:GetAbility()
    -- Remove stored target handle on item
    parent_item.target = nil
    -- Remove stored modifier handle on item
    parent_item.transferred_buff = nil

    ParticleManager:DestroyParticle( self.nPreviewFX, true )
    ParticleManager:ReleaseParticleIndex(self.nPreviewFX)
    self.nPreviewFX = nil
  end
end

function modifier_item_heart_transplant_buff:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_heart_transplant_buff:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_heart_transplant_buff:GetModifierHealthRegenPercentage()
  if self.disabled then
    return 0
  else
    return self:GetAbility():GetSpecialValueFor("health_regen_rate")
  end
end

------------------------------------------------------------------------------------------

-- Flag modifier to disable regen on transplanted target
modifier_item_heart_transplant_buff_break = class(ModifierBaseClass)

function modifier_item_heart_transplant_buff_break:IsHidden()
  return true
end

function modifier_item_heart_transplant_buff_break:IsDebuff()
  return true
end

function modifier_item_heart_transplant_buff_break:IsPurgable()
  return false
end

function modifier_item_heart_transplant_buff_break:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_heart_transplant_buff_break:OnCreated()
  self.transplant_buff = self:GetAbility().transferred_buff
  if self.transplant_buff and not self.transplant_buff:IsNull() then
    self.transplant_buff.disabled = true
  end
end

function modifier_item_heart_transplant_buff_break:OnDestroy()
  if self.transplant_buff and not self.transplant_buff:IsNull() then
    self.transplant_buff.disabled = false
  end
end
