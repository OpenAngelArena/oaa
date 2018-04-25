-- Azazel's Hybrid Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_hybrid_active", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_hybrid_trigger", "items/elixier_hybrid.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_hybrid_1 = class(ItemBaseClass)

function item_elixier_hybrid_1:OnSpellStart()
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

    caster:AddNewModifier(caster, self, "modifier_elixier_hybrid_active", {duration = self:GetSpecialValueFor("bonus_duration")})

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

item_elixier_hybrid_2 = item_elixier_hybrid_1
item_elixier_hybrid_3 = item_elixier_hybrid_1
item_elixier_hybrid_4 = item_elixier_hybrid_1

--------------------------------------------------------------------------------

modifier_elixier_hybrid_active = class(ModifierBaseClass)

function modifier_elixier_hybrid_active:IsHidden() return false end
function modifier_elixier_hybrid_active:IsPurgable() return false end
function modifier_elixier_hybrid_active:IsDebuff() return false end

function modifier_elixier_hybrid_active:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid_lesser.vpcf"
end

function modifier_elixier_hybrid_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_active:GetAbilityTextureName()
  return "custom/elixier_hybrid_1"
end

function modifier_elixier_hybrid_active:OnCreated()
  if IsServer() then
    self.regen = self:GetAbility():GetSpecialValueFor("bonus_regen")
    self.damage = self:GetAbility():GetSpecialValueFor("bonus_damage")
    self:SetStackCount(self.regen)
  end
end

function modifier_elixier_hybrid_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_ABILITY_FULLY_CAST
  }
  return funcs
end

function modifier_elixier_hybrid_active:GetModifierConstantManaRegen()
  return self:GetStackCount()
end

function modifier_elixier_hybrid_active:OnAbilityFullyCast(keys)
  if IsServer() then
    if keys.unit == self:GetParent() and not keys.ability:IsItem() then
      self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_elixier_hybrid_trigger", {damage = self.damage, duration = self:GetRemainingTime()})
    end
  end
end

--------------------------------------------------------------------------------

modifier_elixier_hybrid_trigger = class(ModifierBaseClass)

function modifier_elixier_hybrid_trigger:IsHidden() return false end
function modifier_elixier_hybrid_trigger:IsPurgable() return false end
function modifier_elixier_hybrid_trigger:IsDebuff() return false end

function modifier_elixier_hybrid_trigger:GetEffectName()
  return "particles/items/elixiers/elixier_hybrid.vpcf"
end

function modifier_elixier_hybrid_trigger:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_hybrid_trigger:GetAbilityTextureName()
  return "custom/elixier_hybrid_1"
end

function modifier_elixier_hybrid_trigger:OnCreated(keys)
  if IsServer() then
    self.damage = keys.damage
  end
end

function modifier_elixier_hybrid_trigger:DeclareFunctions()
  local funcs = {
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
  return funcs
end

function modifier_elixier_hybrid_trigger:OnAttackLanded(keys)
  if IsServer() then
    if self:GetParent() == keys.attacker then
      local damage_dealt = ApplyDamage({attacker = self:GetParent(), victim = keys.target, damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, keys.target, damage_dealt, nil)
      self:GetParent():RemoveModifierByName("modifier_elixier_hybrid_trigger")
    end
  end
end