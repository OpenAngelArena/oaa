modifier_dire_tower_boss_glyph = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:IsPurgable()
  return false
end

function modifier_dire_tower_boss_glyph:IsHidden() -- needs tooltip
  return false
end
--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:OnCreated()
  if IsServer() then
    self.count = self:GetAbility():GetSpecialValueFor( "splitshot_units" )
    self.bonus_range = self:GetAbility():GetSpecialValueFor( "splitshot_bonus_range" )
  end
end

--------------------------------------------------------------------------------

function modifier_dire_tower_boss_glyph:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
    MODIFIER_EVENT_ON_ATTACK,
  }
end

function modifier_dire_tower_boss_glyph:GetModifierIncomingDamage_Percentage(params)
  return -100 -- Set the incoming damage percentage to 0 (0% damage taken)
end

function modifier_dire_tower_boss_glyph:OnAttack(event)
  local parent = self:GetParent()
  local attacker = event.attacker

  -- Check if attacker exists
  if not attacker or attacker:IsNull() then
    return
  end

  -- Check if attacker has this modifier
  if attacker ~= parent then
    return
  end

  -- Prevent looping
  if event.no_attack_cooldown then
    return
  end

  self:SplitShot(event.target)
end

function modifier_dire_tower_boss_glyph:SplitShot(target)
  local parent = self:GetParent()
  local radius = parent:GetAttackRange() + self.bonus_range
  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetOrigin(),
    nil,
    radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  local useCastAttackOrb = false
  local processProcs = false
  local skipCooldown = true
  local ignoreInvis = true
  local useProjectile = true
  local fakeAttack = false
  local neverMiss = false

  local count = 0
  for _, enemy in pairs(enemies) do
    if enemy and enemy ~= target then

      --parent:PerformAttack(target, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)
      parent:PerformAttack(enemy, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)

      count = count + 1
      if count >= self.count then break end
    end
  end
end
