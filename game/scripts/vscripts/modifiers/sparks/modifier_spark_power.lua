modifier_spark_power = class(ModifierBaseClass)

function modifier_spark_power:IsHidden()
  return true
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

function modifier_spark_power:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_spark_power:IsAura()
  return true
end

function modifier_spark_power:GetTexture()
  return "custom/spark_power"
end

function modifier_spark_power:GetModifierAura()
  return "modifier_spark_power_effect"
end

function modifier_spark_power:GetAuraRadius()
  return 50000
end

function modifier_spark_power:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_spark_power:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_OTHER)
end

function modifier_spark_power:GetAuraEntityReject(hEntity)
  local caster = self:GetCaster()
  -- Dont provide the aura effect to allies that you can't control
  if hEntity ~= caster then
    if IsServer() then
      if UnitVarToPlayerID(hEntity) ~= UnitVarToPlayerID(caster) then
        return true
      end
    else
      if hEntity.GetPlayerOwnerID then
        if hEntity:GetPlayerOwnerID() ~= caster:GetPlayerOwnerID() then
          return true
        end
      end
    end
  end

  return false
end

function modifier_spark_power:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

function modifier_spark_power:OnCreated()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  -- Initialize with 0
  parent.power_spark_bonus = 0
  self:SetStackCount(0)

  if IsServer() then
    -- Current damage values
    local base_damage_max = parent:GetBaseDamageMax()
    local base_damage_min = parent:GetBaseDamageMin()
    local current_primary_stat_value = parent:GetBonusDamageFromPrimaryStat()
    local current_average_base_damage = (base_damage_max + base_damage_min)/2

    -- Find primary attribute value at level 1 (starting_primary_stat_value)
    local primary_attribute = parent:GetPrimaryAttribute()
    local level = parent:GetLevel()
    local starting_primary_stat_value
    if primary_attribute == DOTA_ATTRIBUTE_STRENGTH then
      starting_primary_stat_value = parent:GetBaseStrength() - (level - 1) * parent:GetStrengthGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_AGILITY then
      starting_primary_stat_value = parent:GetBaseAgility() - (level - 1) * parent:GetAgilityGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_INTELLECT then
      starting_primary_stat_value = parent:GetBaseIntellect() - (level - 1) * parent:GetIntellectGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_ALL then
      starting_primary_stat_value = (parent:GetBaseStrength() - (level - 1) * parent:GetStrengthGain() + parent:GetBaseAgility() - (level - 1) * parent:GetAgilityGain() + parent:GetBaseIntellect() - (level - 1) * parent:GetIntellectGain())/3
    end

    -- Damage values at level 1 (starting base damage values)
    local base_damage_level_1_max = base_damage_max - current_primary_stat_value + starting_primary_stat_value
    local base_damage_level_1_min = base_damage_min - current_primary_stat_value + starting_primary_stat_value
    local starting_average_base_damage = (base_damage_level_1_max + base_damage_level_1_min)/2

    -- Bonus damage/block formula
    local bonus = math.ceil(3188/61 + (4166 * current_average_base_damage - 7312 * starting_average_base_damage)/8723)
    -- Change stack count
    self:SetStackCount(bonus)
  end

  self:StartIntervalThink(0.3)

  --[[
  -- Power Spark constants
  self.creep_damage_melee = {40, 120, 200, 280, 360}
  self.creep_damage_ranged = {40, 120, 200, 280, 360}
  self.creep_damage_melee_illusion = {20, 60, 100, 140, 180}
  self.creep_damage_ranged_illusion = {20, 60, 100, 140, 180}

  -- Stack count is for tooltip only
  if IsServer() then
    local spark_level = self:GetSparkLevel()
    if parent:IsRangedAttacker() then
      self:SetStackCount(self.creep_damage_ranged[spark_level])
    else
      self:SetStackCount(self.creep_damage_melee[spark_level])
    end
  end
  ]]
end

function modifier_spark_power:OnRefresh()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  --parent.power_spark_bonus = self:GetStackCount()
end

function modifier_spark_power:OnIntervalThink()
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  if IsServer() then
    -- Current damage values
    local base_damage_max = parent:GetBaseDamageMax()
    local base_damage_min = parent:GetBaseDamageMin()
    local current_primary_stat_value = parent:GetBonusDamageFromPrimaryStat()
    local current_average_base_damage = (base_damage_max + base_damage_min)/2

    -- Find primary attribute value at level 1 (starting_primary_stat_value)
    local primary_attribute = parent:GetPrimaryAttribute()
    local level = parent:GetLevel()
    local starting_primary_stat_value
    if primary_attribute == DOTA_ATTRIBUTE_STRENGTH then
      starting_primary_stat_value = parent:GetBaseStrength() - (level - 1) * parent:GetStrengthGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_AGILITY then
      starting_primary_stat_value = parent:GetBaseAgility() - (level - 1) * parent:GetAgilityGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_INTELLECT then
      starting_primary_stat_value = parent:GetBaseIntellect() - (level - 1) * parent:GetIntellectGain()
    elseif primary_attribute == DOTA_ATTRIBUTE_ALL then
      starting_primary_stat_value = (parent:GetBaseStrength() - (level - 1) * parent:GetStrengthGain() + parent:GetBaseAgility() - (level - 1) * parent:GetAgilityGain() + parent:GetBaseIntellect() - (level - 1) * parent:GetIntellectGain())/3
    end

    -- Damage values at level 1 (starting base damage values)
    local base_damage_level_1_max = base_damage_max - current_primary_stat_value + starting_primary_stat_value
    local base_damage_level_1_min = base_damage_min - current_primary_stat_value + starting_primary_stat_value
    local starting_average_base_damage = (base_damage_level_1_max + base_damage_level_1_min)/2

    local bonus = math.ceil(3188/61 + (4166 * current_average_base_damage - 7312 * starting_average_base_damage)/8723)
    self:SetStackCount(bonus)
  end

  --parent.power_spark_bonus = self:GetStackCount()
end

function modifier_spark_power:OnStackCountChanged(old_stacks)
  local parent = self:GetParent()

  if parent:IsIllusion() then
    return
  end

  if old_stacks == self:GetStackCount() then
    return
  end

  parent.power_spark_bonus = self:GetStackCount()

  -- This will refresh the stacks and maybe refresh the aura too
  self:ForceRefresh()
end

function modifier_spark_power:OnTooltip()
  return self:GetStackCount()
end

---------------------------------------------------------------------------------------------------

modifier_spark_power_effect = class(ModifierBaseClass)

function modifier_spark_power_effect:IsHidden()
  -- local caster = self:GetCaster() or self:GetAuraOwner()
  -- local parent = self:GetParent()
  -- if parent == caster then
    -- return true
  -- end
  return false
end

function modifier_spark_power_effect:IsDebuff()
  return false
end

function modifier_spark_power_effect:IsPurgable()
  return false
end

function modifier_spark_power_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
    MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK,
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_PROPERTY_TOOLTIP2,
  }
end

function modifier_spark_power_effect:OnCreated()
  local caster = self:GetCaster() or self:GetAuraOwner()

  self.bonus = self.bonus or 0

  if not caster or caster:IsNull() then
    return
  end

  if caster:IsIllusion() then
    return
  end

  self.bonus = caster.power_spark_bonus
end

function modifier_spark_power_effect:OnRefresh()
  local caster = self:GetCaster() or self:GetAuraOwner()

  self.bonus = self.bonus or 0

  if not caster or caster:IsNull() then
    return
  end

  if caster:IsIllusion() then
    return
  end

  self.bonus = caster.power_spark_bonus
end

function modifier_spark_power_effect:GetModifierProcAttack_BonusDamage_Pure(event)
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
  --[[
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
  ]]
  local damage = self.bonus
  if parent:IsIllusion() or not parent:IsHero() then
    damage = damage / 7
  end
  if damage > 0 then
    SendOverheadEventMessage(parent, OVERHEAD_ALERT_MAGICAL_BLOCK, target, damage, parent)
  end

  return damage
end

function modifier_spark_power_effect:GetModifierPhysical_ConstantBlock(keys)
  if not IsServer() then
    return 0
  end

  local attacker = keys.attacker
  if not attacker or attacker:IsNull() then
    return 0
  end

  if attacker:GetTeamNumber() == DOTA_TEAM_NEUTRALS and not attacker:IsOAABoss() then
    local block = self.bonus
    -- True Random chance
    --[[
    if RandomInt(1, 100) <= 50 then
      return block
    end
    ]]

    if not self.damage_block_failures then
      self.damage_block_failures = 0
    end

    -- Get number of failures
    local prngMult = self.damage_block_failures + 1

    -- 50% chance for damage block; Pseudo-Random chance
    if RandomFloat(0.0, 1.0) <= (PrdCFinder:GetCForP(0.75) * prngMult) then
      -- Reset failure count
      self.damage_block_failures = 0

      return block
    else
      -- Increment number of failures
      self.damage_block_failures = prngMult
    end
  end

  return 0
end

function modifier_spark_power_effect:OnTooltip()
  local parent = self:GetParent()
  local damage = self.bonus
  if parent:IsIllusion() or not parent:IsHero() then
    damage = damage / 7
  end
  return damage
end

function modifier_spark_power_effect:OnTooltip2()
  return self.bonus
end

function modifier_spark_power_effect:GetTexture()
  return "custom/spark_power"
end
