item_bfury_oaa = class(ItemBaseClass)

LinkLuaModifier("modifier_bfury_oaa_passive", "items/bfury_oaa.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

--[[
function item_bfury_oaa:GetCastRange(location, target)
  -- Tree --TODO verify
  if target == nil then
    return self.BaseClass.GetCastRange(self, location, target)
  end
  -- Ward
  if target:GetUnitName() == "npc_dota_sentry_wards" or target:GetUnitName() == "npc_dota_observer_wards" then
    return self:GetAbility():GetSpecialValueFor("cast_range_ward")
  end
  -- Techies mine
  if target:GetUnitName() == "npc_dota_techies_land_mine" or target:GetUnitName() == "npc_dota_techies_stasis_trap" then
    return self:GetAbility():GetSpecialValueFor("cast_range_ward")
  end
  --TODO check tree
  return 0 -- Invalid target
end

function item_bfury_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local target = self:GetCursorTarget()

  --TODO destroy target
end
]]

--------------------------------------------------------------------------------

function item_bfury_oaa:GetIntrinsicModifierName()
  return "modifier_bfury_oaa_passive"
end

--------------------------------------------------------------------------------


item_bfury_oaa_1 = item_bfury_oaa
item_bfury_oaa_2 = item_bfury_oaa
item_bfury_oaa_3 = item_bfury_oaa
item_bfury_oaa_4 = item_bfury_oaa
item_bfury_oaa_5 = item_bfury_oaa

--[[
item_bfury_oaa_2 = item_bfury_oaa_1
item_bfury_oaa_3 = item_bfury_oaa_1
item_bfury_oaa_4 = item_bfury_oaa_1
item_bfury_oaa_5 = item_bfury_oaa_1
]]

--------------------------------------------------------------------------------

modifier_bfury_oaa_passive = class( ModifierBaseClass )

--------------------------------------------------------------------------------

function modifier_bfury_oaa_passive:IsHidden()
  return true
end

function modifier_bfury_oaa_passive:IsPurgable()
  return false
end

function modifier_bfury_oaa_passive:IsDebuff()
  return false
end

function modifier_bfury_oaa_passive:GetAttributes()
  return bit.bor(MODIFIER_ATTRIBUTE_PERMANENT, MODIFIER_ATTRIBUTE_MULTIPLE, MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE)
end

--------------------------------------------------------------------------------

function modifier_bfury_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }
end

if IsServer() then
  function modifier_bfury_oaa_passive:GetModifierPreAttack_BonusDamage()
    return self:GetAbility():GetSpecialValueFor("bonus_damage")
  end

  function modifier_bfury_oaa_passive:GetModifierConstantManaRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
  end

  function modifier_bfury_oaa_passive:GetModifierConstantHealthRegen()
    return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
  end

  function modifier_bfury_oaa_passive:OnAttackLanded( event )
    if self:GetParent() ~= event.attacker then
      return
    end

    if self:GetParent():IsRangedAttacker() then
      return
    end

    local activeAbility = self:GetParent():GetCurrentActiveAbility();
    if activeAbility ~= nil and activeAbility:GetAbilityName() == "monkey_king_boundless_strike" then
      return
    end

    local ability = self:GetAbility()
    local cleaveInfo = {
      startRadius = ability:GetSpecialValueFor("cleave_starting_width"),
      endRadius = ability:GetSpecialValueFor("cleave_ending_width"),
      length = ability:GetSpecialValueFor("cleave_distance")
    }

    ability:PerformCleaveOnAttack(
      event,
      cleaveInfo,
      ability:GetSpecialValueFor("cleave_damage_percent") / 100.0,
      nil,
      nil,
      "particles/items_fx/battlefury_cleave.vpcf"
    )
  end
end
