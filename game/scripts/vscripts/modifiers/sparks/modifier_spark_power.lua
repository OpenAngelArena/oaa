modifier_spark_power = class(ModifierBaseClass)

function modifier_spark_power:IsHidden()
  return false
end

function modifier_spark_power:IsDebuff()
  return false
end

function modifier_spark_power:IsPurgable()
  return false
end

function modifier_spark_power:RemoveOnDeath()
  return false
end

function modifier_spark_power:AllowIllusionDuplicate()
  return true
end

function modifier_spark_power:GetTexture()
  return "custom/power_origin"
end

function modifier_spark_power:OnCreated()
  -- Power Spark variables
  self.creep_damage_melee = {40, 120, 200, 280, 360}
  self.creep_damage_ranged = {40, 120, 200, 280, 360}
  self.creep_damage_melee_illusion = {20, 60, 100, 140, 180}
  self.creep_damage_ranged_illusion = {20, 60, 100, 140, 180}
end

function modifier_spark_power:GetSparkLevel()
  local gameTime = GameRules:GetGameTime()

  if not INITIAL_CAPTURE_POINT_DELAY or not CAPTURE_INTERVAL then
    return 1
  end

  if gameTime > INITIAL_CAPTURE_POINT_DELAY + 3*CAPTURE_INTERVAL then
    -- after 4th cap
    return 5
  elseif gameTime > INITIAL_CAPTURE_POINT_DELAY + 2*CAPTURE_INTERVAL then
    -- after third cap
    return 4
  elseif gameTime > INITIAL_CAPTURE_POINT_DELAY + CAPTURE_INTERVAL then
    -- after second cap
    return 3
  elseif gameTime > INITIAL_CAPTURE_POINT_DELAY then
    -- after first cap
    return 2
  end

  return 1
end

function modifier_spark_power:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
  }
end

function modifier_spark_power:GetModifierProcAttack_BonusDamage_Pure(event)
  local parent = self:GetParent()
  local target = event.target

  -- To prevent crashes:
  if not target then
    return 0
  end

  if target:IsNull() then
    return 0
  end

  -- Check for existence of GetUnitName method to determine if target is a unit or an item
  -- items don't have that method -> nil; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return 0
  end

  -- Don't affect buildings and wards
  if target:IsTower() or target:IsBuilding() or target:IsOther() then
    return 0
  end

  if not IsServer() then
    return 0
  end

  -- don't damage non-neutrals
  if not target:IsNeutralCreep(false) then
    return 0
  end

  -- Power Spark variables
  local creep_damage_melee = self.creep_damage_melee
  local creep_damage_ranged = self.creep_damage_ranged
  local creep_damage_melee_illusion = self.creep_damage_melee_illusion
  local creep_damage_ranged_illusion = self.creep_damage_ranged_illusion

  local spark_level = self:GetSparkLevel()

  local damage = creep_damage_melee[spark_level]
  if parent:IsRangedAttacker() then
    damage = creep_damage_ranged[spark_level]
  end

  if parent:IsIllusion() then
    damage = creep_damage_melee_illusion[spark_level]
    if parent:IsRangedAttacker() then
      damage = creep_damage_ranged_illusion[spark_level]
    end
  end

  if damage > 0 then
    SendOverheadEventMessage(parent, OVERHEAD_ALERT_MAGICAL_BLOCK, target, damage, parent)
  end

  return damage
end

function modifier_spark_power:OnTooltip()
  local parent = self:GetParent()
  if parent:IsRangedAttacker() then
    return self.creep_damage_ranged[self:GetSparkLevel()]
  end
    return self.creep_damage_melee[self:GetSparkLevel()]
end
