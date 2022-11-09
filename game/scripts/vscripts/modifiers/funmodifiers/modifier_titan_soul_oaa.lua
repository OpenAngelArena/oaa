modifier_titan_soul_oaa = class(ModifierBaseClass)

function modifier_titan_soul_oaa:IsHidden()
  return false
end

function modifier_titan_soul_oaa:IsDebuff()
  return false
end

function modifier_titan_soul_oaa:IsPurgable()
  return false
end

function modifier_titan_soul_oaa:RemoveOnDeath()
  return false
end

function modifier_titan_soul_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(1)
end

function modifier_titan_soul_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local multiplier = 1.75
  local radius = 180

  -- Check if parent has the stuff
  if parent.GetPrimaryAttribute == nil then
    return
  end

  local primary_attribute = parent:GetPrimaryAttribute()
  local primary_stat = 0
  if primary_attribute == DOTA_ATTRIBUTE_STRENGTH then
    primary_stat = parent:GetStrength()
  elseif primary_attribute == DOTA_ATTRIBUTE_AGILITY then
    primary_stat = parent:GetAgility()
  elseif primary_attribute == DOTA_ATTRIBUTE_INTELLECT then
    primary_stat = parent:GetIntellect()
  end

  local damage_per_interval = primary_stat * multiplier

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {}
  damage_table.attacker = parent
  damage_table.damage = damage_per_interval
  damage_table.damage_type = DAMAGE_TYPE_MAGICAL
  damage_table.damage_flags = DOTA_DAMAGE_FLAG_NONE

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

function modifier_titan_soul_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_SCALE,
  }
end

function modifier_titan_soul_oaa:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end

function modifier_titan_soul_oaa:GetModifierModelScale()
  return 50
end

function modifier_titan_soul_oaa:GetTexture()
  return "item_giants_ring"
end
