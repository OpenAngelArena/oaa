-- Azazel's Burst Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_burst_active", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_burst_trigger", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_burst_bonus", "items/elixier_burst.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_burst_1 = class(ItemBaseClass)

function item_elixier_burst_1:OnSpellStart()
  if IsServer() then
    local caster = self:GetCaster()

    caster:EmitSound("DOTA_Item.FaerieSpark.Activate")

    caster:RemoveModifierByName("modifier_elixier_burst_active")
    caster:RemoveModifierByName("modifier_elixier_burst_trigger")
    caster:RemoveModifierByName("modifier_elixier_burst_bonus")
    caster:RemoveModifierByName("modifier_elixier_sustain_active")
    caster:RemoveModifierByName("modifier_elixier_sustain_trigger")
    caster:RemoveModifierByName("modifier_elixier_hybrid_active")
    caster:RemoveModifierByName("modifier_elixier_hybrid_trigger")

    caster:AddNewModifier(caster, self, "modifier_elixier_burst_active", {duration = self:GetSpecialValueFor("total_duration")})
    caster:AddNewModifier(caster, self, "modifier_elixier_burst_trigger", {bonus_as = self:GetSpecialValueFor("bonus_as"), bonus_attacks = self:GetSpecialValueFor("bonus_attacks"), bonus_duration = self:GetSpecialValueFor("bonus_duration"), duration = self:GetSpecialValueFor("total_duration")})

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

item_elixier_burst_2 = item_elixier_burst_1
item_elixier_burst_3 = item_elixier_burst_1
item_elixier_burst_4 = item_elixier_burst_1

--------------------------------------------------------------------------------

modifier_elixier_burst_active = class(ModifierBaseClass)

function modifier_elixier_burst_active:IsHidden() return false end
function modifier_elixier_burst_active:IsPurgable() return false end
function modifier_elixier_burst_active:IsDebuff() return false end

function modifier_elixier_burst_active:GetEffectName()
  return "particles/items/elixiers/elixier_burst_lesser.vpcf"
end

function modifier_elixier_burst_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_burst_active:GetAbilityTextureName()
  return "custom/elixier_burst_1"
end

function modifier_elixier_burst_active:OnCreated(keys)
  if IsServer() then
    self:SetStackCount(self:GetAbility():GetSpecialValueFor("bonus_ms"))
  end
end

function modifier_elixier_burst_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT
  }
  return funcs
end

function modifier_elixier_burst_active:GetModifierMoveSpeedBonus_Constant()
  return self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_elixier_burst_trigger = class(ModifierBaseClass)

function modifier_elixier_burst_trigger:IsHidden() return false end
function modifier_elixier_burst_trigger:IsPurgable() return false end
function modifier_elixier_burst_trigger:IsDebuff() return false end

function modifier_elixier_burst_trigger:GetAbilityTextureName()
  return "custom/elixier_burst_1"
end

function modifier_elixier_burst_trigger:OnCreated(keys)
  if IsServer() then
    self.bonus_as = keys.bonus_as
    self.bonus_attacks = keys.bonus_attacks
    self.bonus_duration = keys.bonus_duration
  end
end

function modifier_elixier_burst_trigger:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK
  }
  return funcs
end

function modifier_elixier_burst_trigger:OnAttack(keys)
  if IsServer() then
    if keys.attacker == self:GetParent() and keys.attacker:GetTeam() ~= keys.target:GetTeam() then
      local attacker = self:GetParent()
      attacker:AddNewModifier(attacker, self:GetAbility(), "modifier_elixier_burst_bonus", {bonus_as = self.bonus_as, bonus_attacks = self.bonus_attacks, duration = self.bonus_duration})
      attacker:RemoveModifierByName("modifier_elixier_burst_trigger")
    end
  end
end

--------------------------------------------------------------------------------

modifier_elixier_burst_bonus = class(ModifierBaseClass)

function modifier_elixier_burst_bonus:IsHidden() return false end
function modifier_elixier_burst_bonus:IsPurgable() return false end
function modifier_elixier_burst_bonus:IsDebuff() return false end

function modifier_elixier_burst_bonus:GetEffectName()
  return "particles/items/elixiers/elixier_burst.vpcf"
end

function modifier_elixier_burst_bonus:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_burst_bonus:GetAbilityTextureName()
  return "custom/elixier_burst_1"
end

function modifier_elixier_burst_bonus:OnCreated(keys)
  if IsServer() then
    self.bonus_as = keys.bonus_as
    self:SetStackCount(keys.bonus_attacks)
  end
end

function modifier_elixier_burst_bonus:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
  }
  return funcs
end

function modifier_elixier_burst_bonus:GetModifierAttackSpeedBonus_Constant()
  if IsServer() then
    return self.bonus_as
  end
end

function modifier_elixier_burst_bonus:OnAttack(keys)
  if IsServer() then
    if keys.attacker == self:GetParent() then
      self:SetStackCount(self:GetStackCount() - 1)
      if self:GetStackCount() <= 0 then
        keys.attacker:RemoveModifierByName("modifier_elixier_burst_bonus")
      end
    end
  end
end