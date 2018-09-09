--[[ ============================================================================================================
	Charge BKB: Combines magic_wand functionality with BKB functionality, and charges decay with time.
	Written by RamonNZ
	Version 1.05
	Credit: Some original code from Rook
	RamonNZ: The code below starts when you activate the BKB:
	RamonNZ: Added basic purge on BKB start.
  Trildar: Reworked as Lua item and refactored some code
================================================================================================================= ]]
LinkLuaModifier("modifier_item_charge_bkb", "items/charge_bkb.lua", LUA_MODIFIER_MOTION_NONE)

item_charge_bkb = class(ItemBaseClass)

function item_charge_bkb:GetIntrinsicModifierName()
  return "modifier_item_charge_bkb"
end

function item_charge_bkb:OnSpellStart()
  local caster = self:GetCaster()
  --RamonNZ: Wand Effect: Idea: May as well keep the small wand heal effect in addition to the BKB effect. Can be commented out if not wanted or just set to 0 in the kv.
  local amount_to_restore = self:GetCurrentCharges() * self:GetSpecialValueFor("restore_per_charge")
  caster:Heal(amount_to_restore, caster)
  caster:GiveMana(amount_to_restore)
  --RamonNZ: BKB Effect:
  local modifier_duration = self:GetSpecialValueFor("immunity_time_per_charge") * self:GetCurrentCharges()
  -- Basic Purge:
  local RemovePositiveBuffs = false
  local RemoveDebuffs = true
  local BuffsCreatedThisFrameOnly = false
  local RemoveStuns = false
  local RemoveExceptions = false
  caster:Purge(RemovePositiveBuffs, RemoveDebuffs, BuffsCreatedThisFrameOnly, RemoveStuns, RemoveExceptions)

  caster:AddNewModifier(caster, self, "modifier_black_king_bar_immune", {duration = modifier_duration})
  caster:EmitSound("DOTA_Item.BlackKingBar.Activate")

  local modified_cooldown = self:GetSpecialValueFor("cooldown_time_per_charge") * self:GetCurrentCharges() + self:GetCooldown(self:GetLevel())
  self:SetCurrentCharges(0)
  self:StartCooldown( modified_cooldown )
end

function item_charge_bkb:StartChargeResetTimer()
  Timers:CreateTimer(
    "CBKB_" .. self:entindex(),
    {
      endTime = self:GetSpecialValueFor("charge_decay_time"),
      callback = self.ResetCharges
    },
    self
  )
end

function item_charge_bkb:ResetCharges()
  self:SetCurrentCharges(0)
end

item_charge_bkb_2 = class(item_charge_bkb)
item_charge_bkb_3 = class(item_charge_bkb)
item_charge_bkb_4 = class(item_charge_bkb)

------------------------------------------------------------------------

modifier_item_charge_bkb = class(ModifierBaseClass)

function modifier_item_charge_bkb:IsPurgable()
  return false
end

function modifier_item_charge_bkb:IsHidden()
  return true
end

function modifier_item_charge_bkb:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_charge_bkb:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED
  }
end

function modifier_item_charge_bkb:GetModifierPreAttack_BonusDamage()
  return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_charge_bkb:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_strength")
end

function modifier_item_charge_bkb:GetModifierBonusStats_Agility()
  return self:GetAbility():GetSpecialValueFor("bonus_agility")
end

function modifier_item_charge_bkb:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_intellect")
end

-- Add charges when abilities are cast by nearby visible enemies
function modifier_item_charge_bkb:OnAbilityExecuted(keys)
  local parent = self:GetParent()
  local chargeBkb = self:GetAbility()
  -- Only add charges for abilities cast by visible enemies
  local filterResult = UnitFilter(keys.unit,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER),
    bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
    parent:GetTeamNumber()
  )

  -- Only allow 1 Charge BKB to gain charges
  local isFirstCBKBModifier = parent:FindModifierByName("modifier_item_charge_bkb") == self

  local distanceToUnit = #(parent:GetAbsOrigin() - keys.unit:GetAbsOrigin())
  local unitIsInRange = distanceToUnit <= chargeBkb:GetSpecialValueFor("charge_radius")

  -- don't gain charges from neutrals (namely, bosses)
  if keys.unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  if filterResult == UF_SUCCESS and isFirstCBKBModifier and keys.ability:ProcsMagicStick() and unitIsInRange then
    chargeBkb:SetCurrentCharges(chargeBkb:GetCurrentCharges() + 1)
    chargeBkb:StartChargeResetTimer()
  end
end
