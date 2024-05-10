item_sonic = class(ItemBaseClass)

LinkLuaModifier("modifier_item_sonic_passives", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_sonic_fly", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)

function item_sonic:GetIntrinsicModifierName()
  return "modifier_item_sonic_passives"
end

function item_sonic:OnSpellStart()
  local caster = self:GetCaster()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  -- Apply Sonic buff to caster
  caster:AddNewModifier(caster, self, "modifier_sonic_fly", {duration = self:GetSpecialValueFor("duration")})

  -- Emit Activation sound
  caster:EmitSound("Hero_Dark_Seer.Surge")
end

item_sonic_2 = item_sonic

---------------------------------------------------------------------------------------------------

modifier_item_sonic_passives = class(ModifierBaseClass)

function modifier_item_sonic_passives:IsHidden()
  return true
end

function modifier_item_sonic_passives:IsDebuff()
  return false
end

function modifier_item_sonic_passives:IsPurgable()
  return false
end

-- We don't have this on purpose because we don't want people to buy multiple of these
--function modifier_item_sonic_passives:GetAttributes()
  --return MODIFIER_ATTRIBUTE_MULTIPLE
--end

function modifier_item_sonic_passives:OnCreated()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
  self.attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
  self.agi = ability:GetSpecialValueFor("bonus_agility")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
end

modifier_item_sonic_passives.OnRefresh = modifier_item_sonic_passives.OnCreated

function modifier_item_sonic_passives:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
  }
end

function modifier_item_sonic_passives:GetModifierMoveSpeedBonus_Special_Boots()
  return self.movement_speed
end

function modifier_item_sonic_passives:GetModifierAttackSpeedBonus_Constant()
  return self.attack_speed
end

function modifier_item_sonic_passives:GetModifierBonusStats_Agility()
  return self.agi
end

function modifier_item_sonic_passives:GetModifierPreAttack_BonusDamage()
  return self.bonus_damage or self:GetAbility():GetSpecialValueFor("bonus_damage")
end

---------------------------------------------------------------------------------------------------

modifier_sonic_fly = class(ModifierBaseClass)

function modifier_sonic_fly:IsHidden()
  return false
end

function modifier_sonic_fly:IsDebuff()
  return false
end

function modifier_sonic_fly:IsPurgable()
  return true
end

function modifier_sonic_fly:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
end

function modifier_sonic_fly:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.speed = ability:GetSpecialValueFor("active_speed_bonus")
    self.cast_speed = ability:GetSpecialValueFor("active_cast_speed")
  end
end

modifier_sonic_fly.OnRefresh = modifier_sonic_fly.OnCreated

function modifier_sonic_fly:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
    --MODIFIER_PROPERTY_IGNORE_ATTACKSPEED_LIMIT,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
  }
end

function modifier_sonic_fly:CheckState()
  return {
    [MODIFIER_STATE_FLYING] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSLOWABLE] = true,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_TETHERED] = false,
  }
end

function modifier_sonic_fly:GetModifierMoveSpeedBonus_Percentage()
  return self.speed or self:GetAbility():GetSpecialValueFor("active_speed_bonus")
end

function modifier_sonic_fly:GetModifierIgnoreMovespeedLimit()
  return 1
end

function modifier_sonic_fly:GetActivityTranslationModifiers()
  return "haste"
end

--function modifier_sonic_fly:GetModifierAttackSpeed_Limit()
  --return 1
--end

function modifier_sonic_fly:GetModifierAttackSpeedReductionPercentage()
  return 0
end

--function modifier_sonic_fly:GetModifierStatusResistanceStacking()
  --return self:GetAbility():GetSpecialValueFor("status_resist")
--end

function modifier_sonic_fly:GetModifierPercentageCasttime()
  local parent = self:GetParent()
  -- If parent has better cast time improvements return 0
  if parent:HasModifier("modifier_no_cast_points_oaa") or parent:HasModifier("modifier_speedster_oaa") then
    return 0
  end
  return self.cast_speed or self:GetAbility():GetSpecialValueFor("active_cast_speed")
end

function modifier_sonic_fly:GetEffectName()
  return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf"
end

function modifier_sonic_fly:GetTexture()
  return "custom/sonic_3_active"
end
