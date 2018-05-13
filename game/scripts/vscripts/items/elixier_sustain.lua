-- Azazel's Sustainability Elixiers
-- by Firetoad, April 1st, 2018

--------------------------------------------------------------------------------

LinkLuaModifier("modifier_elixier_sustain_active", "items/elixier_sustain.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_elixier_sustain_trigger", "items/elixier_sustain.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

item_elixier_sustain_1 = class(ItemBaseClass)

function item_elixier_sustain_1:OnSpellStart()
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

    caster:AddNewModifier(caster, self, "modifier_elixier_sustain_active", {duration = self:GetSpecialValueFor("bonus_duration")})

    self:SpendCharge()
  end
end

--------------------------------------------------------------------------------

item_elixier_sustain_2 = item_elixier_sustain_1
item_elixier_sustain_3 = item_elixier_sustain_1
item_elixier_sustain_4 = item_elixier_sustain_1

--------------------------------------------------------------------------------

modifier_elixier_sustain_active = class(ModifierBaseClass)

function modifier_elixier_sustain_active:IsHidden() return false end
function modifier_elixier_sustain_active:IsPurgable() return false end
function modifier_elixier_sustain_active:IsDebuff() return false end

function modifier_elixier_sustain_active:GetEffectName()
  return "particles/generic_gameplay/rune_regeneration_sparks.vpcf"
end

function modifier_elixier_sustain_active:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_sustain_active:GetAbilityTextureName()
  return "custom/elixier_sustain_1"
end

function modifier_elixier_sustain_active:OnCreated()
  if IsServer() then
    self.regen = self:GetAbility():GetSpecialValueFor("bonus_regen")
    self.dmg_reduction = self:GetAbility():GetSpecialValueFor("bonus_dmg_reduction")
    self:SetStackCount(self.regen)
    self:StartIntervalThink(0.03)
  end
end

function modifier_elixier_sustain_active:OnIntervalThink()
  if IsServer() then
    local caster = self:GetParent()
    if caster:IsStunned() then
      if not caster:HasModifier("modifier_elixier_sustain_trigger") then
        caster:AddNewModifier(caster, self:GetAbility(), "modifier_elixier_sustain_trigger", {dmg_reduction = self.dmg_reduction})
      end
    else
      caster:RemoveModifierByName("modifier_elixier_sustain_trigger")
    end
  end
end

function modifier_elixier_sustain_active:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
  return funcs
end

function modifier_elixier_sustain_active:GetModifierConstantHealthRegen()
  return self:GetStackCount()
end

--------------------------------------------------------------------------------

modifier_elixier_sustain_trigger = class(ModifierBaseClass)

function modifier_elixier_sustain_trigger:IsHidden() return false end
function modifier_elixier_sustain_trigger:IsPurgable() return false end
function modifier_elixier_sustain_trigger:IsDebuff() return false end

function modifier_elixier_sustain_trigger:GetEffectName()
  return "particles/generic_gameplay/rune_regeneration.vpcf"
end

function modifier_elixier_sustain_trigger:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_elixier_sustain_trigger:GetAbilityTextureName()
  return "custom/elixier_sustain_1"
end

function modifier_elixier_sustain_trigger:OnCreated(keys)
  if IsServer() then
    self.dmg_reduction = keys.dmg_reduction
  end
end

function modifier_elixier_sustain_trigger:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
  }
  return funcs
end

function modifier_elixier_sustain_trigger:GetModifierIncomingDamage_Percentage()
  if IsServer() then
    return (-1) * self.dmg_reduction
  end
end