-- Azazel's Burst Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_burst_active", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_burst_trigger", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_burst_bonus", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_burst = class(ItemBaseClass)

function item_elixier_burst:OnSpellStart()
  local caster = self:GetCaster()

  caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

  caster:RemoveModifierByName("modifier_elixier_burst_active")
  caster:RemoveModifierByName("modifier_elixier_burst_trigger")
  caster:RemoveModifierByName("modifier_elixier_burst_bonus")

  caster:AddNewModifier(caster, self, "modifier_elixier_burst_active", {duration = self:GetSpecialValueFor("total_duration")})
  caster:AddNewModifier(caster, self, "modifier_elixier_burst_trigger", {bonus_as = self:GetSpecialValueFor("bonus_as"), bonus_attacks = self:GetSpecialValueFor("bonus_attacks"), bonus_duration = self:GetSpecialValueFor("bonus_duration"), duration = self:GetSpecialValueFor("total_duration")})

  self:SpendCharge()
end

--------------------------------------------------------------------------------

modifier_elixier_burst_active = class(ModifierBaseClass)

function modifier_elixier_burst_active:IsHidden()
  return false
end

function modifier_elixier_burst_active:IsPurgable()
  return false
end

function modifier_elixier_burst_active:IsDebuff()
  return false
end

function modifier_elixier_burst_active:RemoveOnDeath()
  return false
end

function modifier_elixier_burst_active:GetEffectName()
  return "particles/items/elixiers/elixier_burst_lesser.vpcf"
end

function modifier_elixier_burst_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_burst_active:GetTexture()
  return "custom/elixier_burst"
end

function modifier_elixier_burst_active:OnCreated(keys)
  if IsServer() then
    self:SetStackCount(self:GetAbility():GetSpecialValueFor("bonus_ms"))
  end
end

function modifier_elixier_burst_active:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
  }
end

function modifier_elixier_burst_active:GetModifierMoveSpeedBonus_Constant()
  return self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_elixier_burst_trigger = class(ModifierBaseClass)

function modifier_elixier_burst_trigger:IsHidden()
  return false
end

function modifier_elixier_burst_trigger:IsPurgable()
  return false
end

function modifier_elixier_burst_trigger:IsDebuff()
  return false
end

function modifier_elixier_burst_trigger:RemoveOnDeath()
  return false
end

function modifier_elixier_burst_trigger:GetTexture()
  return "custom/elixier_burst"
end

function modifier_elixier_burst_trigger:OnCreated(keys)
  if IsServer() then
    self.bonus_as = keys.bonus_as
    self.bonus_attacks = keys.bonus_attacks
    self.bonus_duration = keys.bonus_duration
  end
end

function modifier_elixier_burst_trigger:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK
  }
end

if IsServer() then
  function modifier_elixier_burst_trigger:OnAttack(keys)
    local attacker = keys.attacker
    if attacker == self:GetParent() and attacker:GetTeam() ~= keys.target:GetTeam() then
      attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_elixier_burst_bonus", {bonus_as = self.bonus_as, bonus_attacks = self.bonus_attacks, duration = self.bonus_duration})
      --attacker:RemoveModifierByName("modifier_elixier_burst_trigger")
      self:Destroy()
    end
  end
end

--------------------------------------------------------------------------------

modifier_elixier_burst_bonus = class(ModifierBaseClass)

function modifier_elixier_burst_bonus:IsHidden()
  return false
end

function modifier_elixier_burst_bonus:IsPurgable()
  return false
end

function modifier_elixier_burst_bonus:IsDebuff()
  return false
end

function modifier_elixier_burst_bonus:GetEffectName()
  return "particles/items/elixiers/elixier_burst.vpcf"
end

function modifier_elixier_burst_bonus:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_burst_bonus:GetTexture()
  return "custom/elixier_burst"
end

function modifier_elixier_burst_bonus:OnCreated(keys)
  if IsServer() then
    self.bonus_as = keys.bonus_as
    self.max_attacks = keys.bonus_attacks
    self:SetStackCount(keys.bonus_attacks)
  end
end

function modifier_elixier_burst_bonus:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
    MODIFIER_EVENT_ON_ATTACK_FAIL,
  }
end

if IsServer() then
  function modifier_elixier_burst_bonus:GetModifierAttackSpeedBonus_Constant()
    return self.bonus_as
  end

  function modifier_elixier_burst_bonus:OnAttack(event)
    if event.attacker == self:GetParent() then
      self:SetStackCount(self:GetStackCount() - 1)
      -- if self:GetStackCount() <= 0 then
        -- event.attacker:RemoveModifierByName("modifier_elixier_burst_bonus")
      -- end
    end
  end

  function modifier_elixier_burst_bonus:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return
    end

    self:CheckForDestroy()
  end

  function modifier_elixier_burst_bonus:OnAttackFail(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target
    local fail_cause = event.fail_type

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return self:CheckForDestroy()
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return self:CheckForDestroy()
    end

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return self:CheckForDestroy()
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return self:CheckForDestroy()
    end

    if fail_cause == DOTA_ATTACK_RECORD_FAIL_NO or fail_cause == DOTA_ATTACK_RECORD_FAIL_TARGET_OUT_OF_RANGE or fail_cause == DOTA_ATTACK_RECORD_CANNOT_FAIL then
      return self:CheckForDestroy()
    end

    local current_stack_count = self:GetStackCount()

    self:SetStackCount(math.min(self.max_attacks, current_stack_count + 1))
  end

  function modifier_elixier_burst_bonus:CheckForDestroy()
    if not self:IsNull() and self:GetStackCount() <= 0 then
      self:Destroy()
    end
  end
end
