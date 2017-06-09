require( "libraries/Timers" )	--needed for the timers.
LinkLuaModifier("modifier_item_stoneskin", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_stoneskin_stone_armor", "items/stoneskin.lua", LUA_MODIFIER_MOTION_NONE)

item_stoneskin = class({})

function item_stoneskin:GetIntrinsicModifierName()
  return "modifier_item_stoneskin"
end

function item_stoneskin:GetAbilityTextureName()
  local baseIconName = self.BaseClass.GetAbilityTextureName(self)

  -- Update state based on stacks of the intrinsic modifier
  if self.intrinsicModifier and not self.intrinsicModifier:IsNull() then
    self.stoneskinState = self.intrinsicModifier:GetStackCount()
  end

  if self.stoneskinState == 2 then
    return baseIconName .. "_active"
  else
    return baseIconName
  end
end

function item_stoneskin:OnSpellStart()
  local activationDelay = self:GetSpecialValueFor("start_delay")
  local cooldownAfterDelay = self:GetSpecialValueFor("cooldown_after_delay")
  local caster = self:GetCaster()

  -- Toggle state
  self.serverStoneskinState = not self.serverStoneskinState

  if self:GetToggleState() then
    self:StartCooldown(activationDelay + cooldownAfterDelay)
    self.intrinsicModifier:SetStackCount(2)

    EmitSoundOn("Hero_EarthSpirit.RollingBoulder.Loop", caster)
    Timers:CreateTimer(activationDelay, function()
      self:ApplyStoneskin()
    end)
  else
    self:RemoveStoneskin()
  end
end

function item_stoneskin:GetToggleState()
  if self.serverStoneskinState == nil then
    self.serverStoneskinState = false
  end
  return self.serverStoneskinState
end

-- Set no mana cost for toggle off
function item_stoneskin:GetManaCost(level)
  local baseManaCost = self.BaseClass.GetManaCost(self, level)
  if IsServer() then
    if self:GetToggleState() then
      return 0
    else
      return baseManaCost
    end
  elseif IsClient() then
    -- Update state based on stacks of the intrinsic modifier
    if self.intrinsicModifier and not self.intrinsicModifier:IsNull() then
      self.stoneskinState = self.intrinsicModifier:GetStackCount()
    end

    if self.stoneskinState == 2 then
      return 0
    else
      return baseManaCost
    end
  end
end

function item_stoneskin:ApplyStoneskin()
  local caster = self:GetCaster()
  caster:AddNewModifier(caster, self, "modifier_item_stoneskin_stone_armor", {})
  StopSoundOn("Hero_EarthSpirit.RollingBoulder.Loop", caster)
  EmitSoundOn("Hero_EarthSpirit.Petrify", caster)
  self.intrinsicModifier:SetStackCount(2)
end

function item_stoneskin:RemoveStoneskin()
  local caster = self:GetCaster()
  caster:RemoveModifierByName("modifier_item_stoneskin_stone_armor")
  self.intrinsicModifier:SetStackCount(1)
end

item_stoneskin_2 = class(item_stoneskin)
------------------------------------------------------------------------
modifier_item_stoneskin = class({})

function modifier_item_stoneskin:OnCreated()
  local ability = self:GetAbility()
  ability.intrinsicModifier = self
  if IsServer() then

    if ability:GetToggleState() then
      ability:ApplyStoneskin()
    else
      self:SetStackCount(1)
    end
  end
end

modifier_item_stoneskin.OnRefresh = modifier_item_stoneskin.OnCreated

function modifier_item_stoneskin:OnDestroy()
  if IsServer() then
    local ability = self:GetAbility()
    ability:RemoveStoneskin()
  end
end

-- function modifier_item_stoneskin:OnStackCountChanged(numOldStacks)
--   -- Echo stack count to a property on the item so that it can be checked for
--   -- item icon purposes
--   if IsClient() then
--     local ability = self:GetAbility()
--     ability.stoneskinState = self:GetStackCount()
--   end
-- end

function modifier_item_stoneskin:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
  }
end

function modifier_item_stoneskin:IsHidden()
  return true
end

function modifier_item_stoneskin:IsPurgable()
  return false
end

function modifier_item_stoneskin:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_stoneskin:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_stoneskin:GetModifierAttackSpeedBonus_Constant()
  return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_item_stoneskin:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_stoneskin:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_item_stoneskin:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_int")
end
------------------------------------------------------------------------
modifier_item_stoneskin_stone_armor = class({})

function modifier_item_stoneskin_stone_armor:GetTexture()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    local baseIconName = ability.BaseClass.GetAbilityTextureName(ability)
    return baseIconName
  end
end

function modifier_item_stoneskin_stone_armor:IsPurgable()
  return false
end

function modifier_item_stoneskin_stone_armor:GetStatusEffectName()
  return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_stoneskin_stone_armor:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE
  }
end

function modifier_item_stoneskin_stone_armor:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("stone_armor")
end

function modifier_item_stoneskin_stone_armor:GetModifierMagicalResistanceBonus()
  return self:GetAbility():GetSpecialValueFor("stone_resist")
end

function modifier_item_stoneskin_stone_armor:GetModifierMoveSpeed_Absolute()
  return self:GetAbility():GetSpecialValueFor("stone_move_speed")
end
