item_greater_travel_boots = class({})
modifier_item_greater_travel_boots = class({})

LinkLuaModifier( "modifier_item_greater_travel_boots", "items/farming/item_greater_travel_boots.lua", LUA_MODIFIER_MOTION_NONE )

function item_greater_travel_boots:GetIntrinsicModifierName()
  return "modifier_item_greater_travel_boots"
end

function item_greater_travel_boots:IsHidden()
  return false
end

function item_greater_travel_boots:IsDebuff()
  return false
end

function item_greater_travel_boots:IsPurgable()
  return false
end

function item_greater_travel_boots:OnSpellStart()
  local hCaster = self:GetCaster()
  local hTarget = self:GetCursorTarget()

  if not hTarget then
    -- FindUnitsInRadius(int teamNumber, Vector position, handle cacheUnit, float radius, int teamFilter, int typeFilter, int flagFilter, int order, bool canGrowCache)
    local units = FindUnitsInRadius(hCaster:GetTeamNumber(), self:GetCursorPosition(), nil, 2000, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), FIND_CLOSEST, false)
    hTarget = units[1]
  end
  if not hTarget or hTarget == hCaster then
    return false
  end

  self.targetEntity = hTarget
end

function item_greater_travel_boots:OnChannelThink (delta)
  if not self.targetEntity:IsAlive() then
    self:EndChannel(true)
  end
end
-- IsAlive
function item_greater_travel_boots:OnChannelFinish(wasInterupted)
  if wasInterupted then
    return -- do nothing
  end

  FindClearSpaceForUnit(self:GetCaster(), self.targetEntity:GetAbsOrigin(), true)
end

function modifier_item_greater_travel_boots:OnCreated()
  self:StartIntervalThink(1)
end

function modifier_item_greater_travel_boots:OnIntervalThink ()
  if not PlayerResource then
    -- sometimes for no reason the player resource isn't there, usually only at the start of games in tools mode
    return
  end
  local caster = self:GetCaster()
  local gpm = self:GetAbility():GetSpecialValueFor('bonus_gold_per_minute')
  PlayerResource:ModifyGold(caster:GetPlayerID(), gpm / 60, true, DOTA_ModifyGold_GameTick)
end

--------------------------------------------------------------------------------
-- All the upgrades are exactly the same
--------------------------------------------------------------------------------
item_greater_travel_boots_2 = item_greater_travel_boots
item_greater_travel_boots_3 = item_greater_travel_boots
item_greater_travel_boots_4 = item_greater_travel_boots
item_greater_travel_boots_5 = item_greater_travel_boots
