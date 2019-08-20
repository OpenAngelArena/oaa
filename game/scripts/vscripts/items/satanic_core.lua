LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_octarine_vampirism_buff", "modifiers/modifier_octarine_vampirism_buff.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_satanic_core", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_satanic_core_unholy", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_satanic_core = class(ItemBaseClass)

function item_satanic_core:GetIntrinsicModifierName()
  return "modifier_intrinsic_multiplexer"
end

function item_satanic_core:GetIntrinsicModifierNames()
  return {
    "modifier_item_satanic_core",
    "modifier_octarine_vampirism_buff"
  }
end

function item_satanic_core:OnSpellStart()
  local hCaster = self:GetCaster()
  local unholy_duration = self:GetSpecialValueFor("duration")

  hCaster:EmitSound( "DOTA_Item.Satanic.Activate" )
  hCaster:AddNewModifier( hCaster, self, "modifier_satanic_core_unholy", { duration = unholy_duration } )
end

--------------------------------------------------------------------------------

item_satanic_core_2 = item_satanic_core --luacheck: ignore item_satanic_core_2

--------------------------------------------------------------------------------

item_satanic_core_3 = item_satanic_core --luacheck: ignore item_satanic_core_3

--------------------------------------------------------------------------------

modifier_item_satanic_core = class(ModifierBaseClass)

function modifier_item_satanic_core:IsHidden()
  return true
end
--[[
function modifier_item_satanic_core:OnCreated()
  self.lifesteal_percent = self:GetAbility():GetSpecialValueFor("hero_lifesteal")
  self.unholy_lifesteal_percent = self:GetAbility():GetSpecialValueFor("unholy_hero_spell_lifesteal")
end

function modifier_item_satanic_core:OnRefresh()
  self.lifesteal_percent = self:GetAbility():GetSpecialValueFor("hero_lifesteal")
  self.unholy_lifesteal_percent = self:GetAbility():GetSpecialValueFor("unholy_hero_spell_lifesteal")
end
]]
function modifier_item_satanic_core:IsPurgable()
  return false
end

function modifier_item_satanic_core:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    --MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
  return funcs
end

function modifier_item_satanic_core:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_satanic_core:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_intelligence")
end

function modifier_item_satanic_core:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_satanic_core:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_mana")
end

--[[
function modifier_item_satanic_core:OnTakeDamage( kv )
  if IsServer() then
    local hCaster = self:GetParent()
    -- If there is no inflictor that means damage was dealt from an attack
    -- So this is normal lifesteal; spell lifesteal is handled in modifier_octarine_vampirism_buff
    if not kv.inflictor and kv.attacker == hCaster then
      local heal_percent = self.lifesteal_percent;
      if hCaster:HasModifier("modifier_satanic_core_unholy") then
        heal_percent = self.unholy_lifesteal_percent
      end
      local particle = ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster )
      ParticleManager:ReleaseParticleIndex(particle)
      local healAmount = kv.damage * heal_percent / 100
      if healAmount > 0 then
        hCaster:Heal( healAmount, hCaster)
      end
    end
  end
end
]]
--------------------------------------------------------------------------------

modifier_satanic_core_unholy = class(ModifierBaseClass)

function modifier_satanic_core_unholy:IsPurgable()
  return true
end

function modifier_satanic_core_unholy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_satanic_core_unholy:OnTooltip()
  return self:GetAbility():GetSpecialValueFor("unholy_hero_spell_lifesteal")
end

function modifier_satanic_core_unholy:GetEffectName()
  return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_satanic_core_unholy:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
