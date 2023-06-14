-- Max Power

modifier_any_damage_crit_oaa = class(ModifierBaseClass)

function modifier_any_damage_crit_oaa:IsHidden()
  return false
end

function modifier_any_damage_crit_oaa:IsDebuff()
  return false
end

function modifier_any_damage_crit_oaa:IsPurgable()
  return false
end

function modifier_any_damage_crit_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_any_damage_crit_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_any_damage_crit_oaa:OnCreated()
  self.attack_crit_chance = 25
  self.spell_crit_chance = 25
  self.crit_multiplier = 2.5
end

if IsServer() then
  function modifier_any_damage_crit_oaa:GetModifierPreAttack_CriticalStrike(event)
    local target = event.target

    -- Check if attacked entity exists
    if not target or target:IsNull() then
      return 0
    end

    -- Check if attacked entity is an item, rune or something weird
    if target.GetUnitName == nil then
      return 0
    end

    -- Don't affect buildings, wards, invulnerable and dead units.
    if target:IsTower() or target:IsBarracks() or target:IsBuilding() or target:IsOther() or target:IsInvulnerable() or not target:IsAlive() then
      return 0
    end

    if RandomInt(1, 100) <= self.attack_crit_chance then
      return self.crit_multiplier * 100
    end
  end

  function modifier_any_damage_crit_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.original_damage

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
    --if damaged_unit == parent then
      --return
    --end

    -- Check if entity is an item, rune or something weird
    if damaged_unit.GetUnitName == nil then
      return
    end

    -- Don't affect buildings, wards, invulnerable and dead units.
    if damaged_unit:IsTower() or damaged_unit:IsBarracks() or damaged_unit:IsBuilding() or damaged_unit:IsOther() or damaged_unit:IsInvulnerable() or not damaged_unit:IsAlive() then
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

    -- Ignore damage with no-spell-amplification flag (it also ignores damage dealt with Max Power)
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION) > 0 then
      return
    end

    -- Can't crit on 0 or negative damage
    if damage <= 0 then
      return
    end

    -- Ignore attacks
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    if RandomInt(1, 100) <= self.spell_crit_chance then
      local damage_table = {
        victim = damaged_unit,
        attacker = parent,
        damage = (self.crit_multiplier - 1) * damage,
        damage_type = event.damage_type,
        damage_flags = bit.bor(dmg_flags, DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION),
        ability = event.inflictor,
      }

      ApplyDamage(damage_table)

      SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, damaged_unit, damage_table.damage, nil)
    end
  end
end

function modifier_any_damage_crit_oaa:GetTexture()
  return "item_greater_crit"
end
