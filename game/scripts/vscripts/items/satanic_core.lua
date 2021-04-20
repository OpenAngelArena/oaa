LinkLuaModifier( "modifier_intrinsic_multiplexer", "modifiers/modifier_intrinsic_multiplexer.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_spell_lifesteal_oaa", "modifiers/modifier_item_spell_lifesteal_oaa.lua", LUA_MODIFIER_MOTION_NONE )
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
    "modifier_item_spell_lifesteal_oaa"
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

function modifier_item_satanic_core:IsDebuff()
  return false
end

function modifier_item_satanic_core:IsPurgable()
  return false
end

function modifier_item_satanic_core:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_satanic_core:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    --self.lifesteal_percent = ability:GetSpecialValueFor("hero_lifesteal")
    --self.unholy_lifesteal_percent = ability:GetSpecialValueFor("unholy_hero_spell_lifesteal")
    self.bonus_str = ability:GetSpecialValueFor("bonus_strength")
    self.bonus_int = ability:GetSpecialValueFor("bonus_intelligence")
    self.bonus_hp = ability:GetSpecialValueFor("bonus_health")
    self.bonus_mana = ability:GetSpecialValueFor("bonus_mana")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
    self.bonus_magic_resist = ability:GetSpecialValueFor("bonus_magic_resist")
  end
end

modifier_item_satanic_core.OnRefresh = modifier_item_satanic_core.OnCreated

function modifier_item_satanic_core:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
    MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
    --MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
  return funcs
end

function modifier_item_satanic_core:GetModifierBonusStats_Strength()
  return self.bonus_str or self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_satanic_core:GetModifierBonusStats_Intellect()
  return self.bonus_int or self:GetAbility():GetSpecialValueFor("bonus_intelligence")
end

function modifier_item_satanic_core:GetModifierHealthBonus()
  return self.bonus_hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end

function modifier_item_satanic_core:GetModifierManaBonus()
  return self.bonus_mana or self:GetAbility():GetSpecialValueFor("bonus_mana")
end

function modifier_item_satanic_core:GetModifierStatusResistanceStacking()
  return self.bonus_status_resist or self:GetAbility():GetSpecialValueFor("bonus_status_resist")
end

function modifier_item_satanic_core:GetModifierMagicalResistanceBonus()
  return self.bonus_magic_resist or self:GetAbility():GetSpecialValueFor("bonus_magic_resist")
end

--[[
function modifier_item_satanic_core:OnTakeDamage( kv )
  if IsServer() then
    local hCaster = self:GetParent()
    -- If there is no inflictor that means damage was dealt from an attack
    -- So this is normal lifesteal; spell lifesteal is handled in modifier_item_spell_lifesteal_oaa
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

function modifier_satanic_core_unholy:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.tooltip = ability:GetSpecialValueFor("unholy_hero_spell_lifesteal")
  end
end

modifier_satanic_core_unholy.OnRefresh = modifier_satanic_core_unholy.OnCreated

function modifier_satanic_core_unholy:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_satanic_core_unholy:OnTooltip()
  return self.tooltip
end

function modifier_satanic_core_unholy:GetEffectName()
  return "particles/items2_fx/satanic_buff.vpcf"
end

function modifier_satanic_core_unholy:GetEffectAttachType()
  return PATTACH_ABSORIGIN_FOLLOW
end
