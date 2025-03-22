-- Splasher

modifier_any_damage_splash_oaa = class(ModifierBaseClass)

function modifier_any_damage_splash_oaa:IsHidden()
  return false
end

function modifier_any_damage_splash_oaa:IsDebuff()
  return false
end

function modifier_any_damage_splash_oaa:IsPurgable()
  return false
end

function modifier_any_damage_splash_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_any_damage_splash_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
    MODIFIER_PROPERTY_PROCATTACK_FEEDBACK,
  }
end

function modifier_any_damage_splash_oaa:OnCreated()
  self.splash_percent = 75
  self.splash_radius = 275
end

if IsServer() then
  function modifier_any_damage_splash_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage
    local inflictor = event.inflictor

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Ignore self damage
    if damaged_unit == attacker then
      return
    end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards and invulnerable units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() then
      return
    end

    -- Ignore damage with no-reflect flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) > 0 then
      return
    end

    -- Ignore damage with HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) > 0 then
      return
    end

    -- Ignore damage with no-spell-lifesteal flag (it also ignores damage dealt with Splasher)
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) > 0 then
      return
    end

    -- Check damage if 0 or negative
    if damage <= 0 then
      return
    end

    -- Ignore attacks
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    self:Splash(damage, dmg_flags, event.damage_type, damaged_unit, inflictor)
  end

  function modifier_any_damage_splash_oaa:Splash(damage, dmg_flags, dmg_type, damaged_unit, inflictor)
    local parent = self:GetParent()

    local damage_table = {
      attacker = parent,
      damage = damage * self.splash_percent / 100,
      damage_type = dmg_type,
      damage_flags = bit.bor(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL),
    }

    local targetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
    local targetType = bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
    local targetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
    if damaged_unit:GetTeamNumber() == parent:GetTeamNumber() then
      targetTeam = DOTA_UNIT_TARGET_TEAM_BOTH
    end
    if inflictor and not inflictor:IsNull() then
      damage_table.ability = inflictor
    end

    local targets = FindUnitsInRadius(
      parent:GetTeamNumber(),
      damaged_unit:GetAbsOrigin(),
      nil,
      self.splash_radius,
      targetTeam,
      targetType,
      targetFlags,
      FIND_ANY_ORDER,
      false
    )

    if damage > 0 and #targets > 1 then
      local particle = ParticleManager:CreateParticle("particles/items/powertreads_splash.vpcf", PATTACH_POINT, damaged_unit)
      ParticleManager:SetParticleControl(particle, 5, Vector(1, 0, self.splash_radius))
      ParticleManager:ReleaseParticleIndex(particle)
    end

    -- Splash on targets that are not the attacker or damaged unit
    for _, unit in pairs(targets) do
      if unit and not unit:IsNull() and unit ~= damaged_unit and unit ~= parent then
        damage_table.victim = unit
        ApplyDamage(damage_table)
      end
    end
  end

  function modifier_any_damage_splash_oaa:GetModifierProcAttack_Feedback(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if attacker has this modifier
    if attacker ~= parent then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item (or rune)
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- No need to proc if target is a building, ward, invulnerable or dead
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or target:IsOutOfGame() or not target:IsAlive() then
      return
    end

    self:Splash(event.damage, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL, DAMAGE_TYPE_PHYSICAL, target, nil)
  end
end

function modifier_any_damage_splash_oaa:GetTexture()
  return "magnataur_empower"
end
