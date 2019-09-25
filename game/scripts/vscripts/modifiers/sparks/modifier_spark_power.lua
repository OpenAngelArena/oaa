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

function modifier_spark_power:GetTexture()
  return "custom/power_origin"
end

function modifier_spark_power:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
  }
end


if IsServer() then
  function modifier_spark_power:GetModifierProcAttack_BonusDamage_Pure(event)
    local parent = self:GetParent()
    local target = event.target

    -- To prevent crashes:
    if not target then
      return
    end

    if target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings and wards
    if target:IsTower() or target:IsBuilding() or target:IsOther() then
      return
    end

    if not IsServer() then
      return
    end

    -- don't damage non-neutrals
    if not target:IsNeutralCreep(false) then
      return 0
    end

    -- Cleave Spark variables
    local creep_damage_melee = {40, 120, 200, 280, 360}
    local creep_damage_ranged = {40, 120, 200, 280, 360}
    local creep_damage_melee_illusion = {20, 60, 100, 140, 180}
    local creep_damage_ranged_illusion = {20, 60, 100, 140, 180}

    local function getSparkLevel ()
      local gameTime = GameRules:GetGameTime()

      if gameTime > INITIAL_CAPTURE_POINT_DELAY + CAPTURE_INTERVAL + CAPTURE_INTERVAL + CAPTURE_INTERVAL then
        -- after second cap
        return 5
      elseif gameTime > INITIAL_CAPTURE_POINT_DELAY + CAPTURE_INTERVAL + CAPTURE_INTERVAL then
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

    local damage = creep_damage_melee[getSparkLevel()]
    if parent:IsRangedAttacker() then
      damage = creep_damage_ranged[getSparkLevel()]
    end

    if parent:IsIllusion() then
      damage = creep_damage_melee_illusion[getSparkLevel()]
      if parent:IsRangedAttacker() then
        damage = creep_damage_ranged_illusion[getSparkLevel()]
      end
    end

    if damage > 0 then
      SendOverheadEventMessage(parent, OVERHEAD_ALERT_MAGICAL_BLOCK, target, damage, parent)
    end

    return damage
  end
end
