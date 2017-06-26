modifier_oaa_int_steal = class(ModifierBaseClass)

function modifier_oaa_int_steal:IsPurgable()
  return false
end

function modifier_oaa_int_steal:RemoveOnDeath()
  return false
end

function modifier_oaa_int_steal:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH
  }
end

function modifier_oaa_int_steal:OnDeath(keys)
  local parent = self:GetParent()
  local ability = self:GetAbility()
  local stealRange = ability:GetLevelSpecialValueFor("steal_range", math.max(1, ability:GetLevel()))
  local stealAmount = ability:GetLevelSpecialValueFor("steal_amount", math.max(1, ability:GetLevel()))
  Debug.EnabledModules["modifiers:modifier_oaa_int_steal"] = true
  local filterResult = UnitFilter(
    keys.unit,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO,
    bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_DEAD),
    parent:GetTeamNumber()
  )
  local isWithinRange = #(keys.unit:GetAbsOrigin() - parent:GetAbsOrigin()) <= stealRange
  if filterResult == UF_SUCCESS and (keys.attacker == parent or isWithinRange) then
    DebugPrint("Int Steal")
    local oldIntellect = keys.unit:GetBaseIntellect()
    keys.unit:SetBaseIntellect(math.max(1, oldIntellect - stealAmount))
    keys.unit:CalculateStatBonus()
    local intellectDifference = oldIntellect - keys.unit:GetBaseIntellect()
    parent:ModifyIntellect(intellectDifference)
    self:SetStackCount(self:GetStackCount() + intellectDifference)
    -- TODO: Add message number particles
  end
end
