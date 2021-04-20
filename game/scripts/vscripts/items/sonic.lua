item_sonic = class(ItemBaseClass)

LinkLuaModifier("modifier_sonic_fly", "items/sonic.lua", LUA_MODIFIER_MOTION_NONE)
--LinkLuaModifier("modifier_generic_bonus", "modifiers/modifier_generic_bonus.lua", LUA_MODIFIER_MOTION_NONE)

function item_sonic:GetIntrinsicModifierName()
  return "modifier_item_phase_boots"--"modifier_generic_bonus"
end

function item_sonic:OnSpellStart()
  local caster = self:GetCaster()

  -- Disable working on Meepo Clones
  if caster:IsClone() then
    self:RefundManaCost()
    self:EndCooldown()
    return
  end

  -- Apply Basic Dispel
  caster:Purge(false, true, false, false, false)

  -- Apply Sonic buff to caster
  caster:AddNewModifier(caster, self, "modifier_sonic_fly", {duration = self:GetSpecialValueFor("duration")})

  -- Emit Activation sound
  caster:EmitSound("Hero_Dark_Seer.Surge")
end

item_sonic_2 = item_sonic

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

function modifier_sonic_fly:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.vision = ability:GetSpecialValueFor("vision_bonus")
    self.speed = ability:GetSpecialValueFor("speed_bonus")
  end
end

modifier_sonic_fly.OnRefresh = modifier_sonic_fly.OnCreated

function modifier_sonic_fly:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
    MODIFIER_PROPERTY_BONUS_VISION_PERCENTAGE,
    MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
    MODIFIER_PROPERTY_ATTACKSPEED_REDUCTION_PERCENTAGE,
    --MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
  }
end

function modifier_sonic_fly:CheckState()
  local state = {
    [MODIFIER_STATE_FLYING] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSLOWABLE] = true,
  }
  return state
end

function modifier_sonic_fly:GetBonusVisionPercentage()
  return self.vision or self:GetAbility():GetSpecialValueFor("vision_bonus")
end

function modifier_sonic_fly:GetModifierMoveSpeedBonus_Percentage()
  return self.speed or self:GetAbility():GetSpecialValueFor("speed_bonus")
end

function modifier_sonic_fly:GetModifierIgnoreMovespeedLimit()
  return 1
end

function modifier_sonic_fly:GetModifierAttackSpeedReductionPercentage()
  return 0
end

--function modifier_sonic_fly:GetModifierStatusResistanceStacking()
  --return self:GetAbility():GetSpecialValueFor("status_resist")
--end

function modifier_sonic_fly:GetTexture()
  return "custom/sonic_3_active"
end
