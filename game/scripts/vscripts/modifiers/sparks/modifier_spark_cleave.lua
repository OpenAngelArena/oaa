modifier_spark_cleave = class(ModifierBaseClass)

function modifier_spark_cleave:IsHidden()
  return false
end

function modifier_spark_cleave:IsDebuff()
  return false
end

function modifier_spark_cleave:IsPurgable()
  return false
end

function modifier_spark_cleave:RemoveOnDeath()
  return false
end

function modifier_spark_cleave:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_spark_cleave:OnCreated()
  local parent = self:GetParent()

  -- This modifier is not supposed to exist on illusions, Tempest Doubles, Meepo clones or Spirit Bears
  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
    self:Destroy()
  end
end

function modifier_spark_cleave:GetTexture()
  return "custom/spark_cleave"
end

function modifier_spark_cleave:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

if IsServer() then
  function modifier_spark_cleave:OnAttackLanded(keys)
    local parent = self:GetParent()
    local attacker = keys.attacker
    local target = keys.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- Prevent instant attacks proccing the cleave
    if keys.no_attack_cooldown then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
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

    -- Cleave Spark variables
    local splinter_radius = 400
    local splinter_count = 4
    local splinter_damage_percent = 30

    local originTarget = target:GetOrigin()

    local units = FindUnitsInRadius(
      parent:GetTeamNumber(),
      originTarget,
      nil,
      splinter_radius,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_BASIC,
      bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_NO_INVIS),
      FIND_ANY_ORDER,
      false
    )

    -- Exclude the original attack target from list of units to splinter to
    table.remove(units, index(target, units))
    -- Take only neutral unit types to avoid targeting summons
    local function IsNeutralUnitType(unit)
      return unit:IsNeutralCreep( false )
    end
    local neutralUnits = filter(IsNeutralUnitType, units)
    -- Take the first splinter_number units to split to
    local nUnits = take_n(splinter_count, neutralUnits)

    -- generate damage stuff
    local damage = keys.original_damage
    local damageType = DAMAGE_TYPE_PHYSICAL
    local damageFlags = bit.bor(DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
    local damageMod = splinter_damage_percent * 0.01
    damage = damage * damageMod

    local function ApplySplinterDamage(unit)
      ApplyDamage({
        victim = unit,
        attacker = parent,
        damage = damage,
        damage_type = damageType,
        damage_flags = damageFlags,
      })

      local origin = unit:GetOrigin()
      local part = ParticleManager:CreateParticle("particles/items/phase_splinter_impact_model.vpcf", PATTACH_ABSORIGIN, unit)
      ParticleManager:SetParticleControl(part, 1, origin)
      ParticleManager:SetParticleControlForward(part, 1, (originTarget - origin):Normalized())
      local facing = unit:GetForwardVector()
      facing.y = facing.y * -1.0
      ParticleManager:SetParticleControlForward(part, 10, facing)
      ParticleManager:ReleaseParticleIndex(part)
    end

    foreach(ApplySplinterDamage, nUnits)
  end
end
