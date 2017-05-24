LinkLuaModifier( "modifier_octarine_vampirism_buff", "modifiers/modifier_octarine_vampirism_buff.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_satanic_core", "items/satanic_core.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_item_satanic_unholy", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------

item_satanic_core = class({})

function item_satanic_core:GetIntrinsicModifierName()
  return "modifier_item_satanic_core"
end

function item_satanic_core:OnSpellStart()
  local hCaster = self:GetCaster()
  local unholy_duration = self:GetSpecialValueFor( "unholy_duration" )

  EmitSoundOn( "DOTA_Item.Satanic.Activate", hCaster )
  hCaster:AddNewModifier( hCaster, self, "modifier_item_satanic_unholy", { duration = unholy_duration } )
end

--------------------------------------------------------------------------------

item_satanic_core_2 = item_satanic_core --luacheck: ignore item_satanic_core_2

--------------------------------------------------------------------------------

item_satanic_core_3 = item_satanic_core --luacheck: ignore item_satanic_core_3

--------------------------------------------------------------------------------

modifier_item_satanic_core = class({})

function modifier_item_satanic_core:IsHidden()
  return true
end

function modifier_item_satanic_core:OnCreated()
  self.lifesteal_percent = self:GetAbility():GetSpecialValueFor( "lifesteal_percent" )
  self.unholy_lifesteal_percent = self:GetAbility():GetSpecialValueFor( "unholy_lifesteal_percent" )
  self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
end

function modifier_item_satanic_core:OnRefresh()
  self.lifesteal_percent = self:GetAbility():GetSpecialValueFor( "lifesteal_percent" )
  self.unholy_lifesteal_percent = self:GetAbility():GetSpecialValueFor( "unholy_lifesteal_percent" )
  self.aura_radius = self:GetAbility():GetSpecialValueFor( "radius" )
end

function modifier_item_satanic_core:IsAura()
  return true
end

function modifier_item_satanic_core:GetModifierAura()
  return "modifier_octarine_vampirism_buff"
end

function modifier_item_satanic_core:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_satanic_core:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_item_satanic_core:GetAuraSearchFlags()
  return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_item_satanic_core:GetAuraRadius()
  return self.aura_radius
end

function modifier_item_satanic_core:IsPurgable()
  return false
end

function modifier_item_satanic_core:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_BONUS,
    MODIFIER_PROPERTY_MANA_BONUS,
    MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
  return funcs
end

function modifier_item_satanic_core:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor( "bonus_strength" )
end

function modifier_item_satanic_core:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor( "bonus_intelligence" )
end

function modifier_item_satanic_core:GetModifierHealthBonus()
  return self:GetAbility():GetSpecialValueFor( "bonus_health" )
end

function modifier_item_satanic_core:GetModifierManaBonus()
  return self:GetAbility():GetSpecialValueFor( "bonus_mana" )
end

function modifier_item_satanic_core:GetModifierPercentageCooldown()
  return self:GetAbility():GetSpecialValueFor( "bonus_cooldown" )
end

function modifier_item_satanic_core:OnAttackLanded( kv )
  if IsServer() then
    local hCaster = self:GetParent()
    if kv.attacker == hCaster then
      local heal_percent = self.lifesteal_percent;
      if hCaster:HasModifier("modifier_item_satanic_unholy") then
        heal_percent = self.unholy_lifesteal_percent
      end
      ParticleManager:CreateParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster )
      hCaster:Heal( kv.damage * heal_percent / 100, hCaster)
    end
  end
end

--------------------------------------------------------------------------------
