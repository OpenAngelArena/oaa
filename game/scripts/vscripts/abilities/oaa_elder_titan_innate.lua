-- World Builder

LinkLuaModifier("modifier_elder_titan_innate_oaa", "abilities/oaa_elder_titan_innate.lua", LUA_MODIFIER_MOTION_NONE)

elder_titan_innate_oaa = class(AbilityBaseClass)

function elder_titan_innate_oaa:GetIntrinsicModifierName()
  return "modifier_elder_titan_innate_oaa"
end

---------------------------------------------------------------------------------------------------

modifier_elder_titan_innate_oaa = class(ModifierBaseClass)

function modifier_elder_titan_innate_oaa:IsHidden()
  return true
end

function modifier_elder_titan_innate_oaa:IsDebuff()
  return false
end

function modifier_elder_titan_innate_oaa:IsPurgable()
  return false
end

function modifier_elder_titan_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_elder_titan_innate_oaa:OnCreated()
  local ability = self:GetAbility()
  self.multiplier = ability:GetSpecialValueFor("starting_dmg_per_strength")
  self.dmg_increase = ability:GetSpecialValueFor("dmg_increase_per_second")
  self.radius = ability:GetSpecialValueFor("radius")
  self.last_location = self:GetParent():GetAbsOrigin()
  self.counter = 0
  self.interval = 0.2

  if IsServer() then
    self:StartIntervalThink(self.interval)
  end
end

function IsSleeping(unit)
  return unit:HasModifier("modifier_bane_nightmare") or unit:HasModifier("modifier_elder_titan_echo_stomp") or unit:HasModifier("modifier_naga_siren_song_of_the_siren")
end

function modifier_elder_titan_innate_oaa:OnIntervalThink()
  local parent = self:GetParent()

  -- Don't do anything if broken or if an illusion
  if parent:PassivesDisabled() or parent:IsIllusion() then
    return
  end

  -- Don't do anything while dead (don't do damage on the corpse)
  if not parent:IsAlive() then
    return
  end

  -- Check if parent moved recently
  if (self.last_location - parent:GetAbsOrigin()):Length2D() > 10 then
    self.last_location = parent:GetAbsOrigin()
    self.counter = 0
    return
  end

  local multiplier = self.multiplier
  local radius = self.radius
  local dmg_increase = self.dmg_increase
  local strength = parent:GetStrength()
  local starting_dmg = strength * multiplier

  local damage_table = {
    attacker = parent,
    damage_type = DAMAGE_TYPE_MAGICAL,
    damage_flags = DOTA_DAMAGE_FLAG_NONE,
  }

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

  local second = math.ceil(1 / self.interval)

  if self.counter >= second then
    damage_table.damage = (starting_dmg  + (self.counter - second) * dmg_increase) * self.interval
  else
    self.counter = self.counter + 1
    return
  end

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not IsSleeping(enemy) then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end

  self.counter = self.counter + 1
end

function modifier_elder_titan_innate_oaa:CheckState()
  return {
    [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true,
  }
end
