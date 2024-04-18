LinkLuaModifier("modifier_battlemage_cooldown_oaa", "modifiers/funmodifiers/modifier_battlemage_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_battlemage_oaa = class(ModifierBaseClass)

function modifier_battlemage_oaa:IsHidden()
  return false
end

function modifier_battlemage_oaa:IsDebuff()
  return false
end

function modifier_battlemage_oaa:IsPurgable()
  return false
end

function modifier_battlemage_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_battlemage_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_TAKEDAMAGE,
  }
end

function modifier_battlemage_oaa:OnCreated()
  self.cooldown = 1
end

if IsServer() then
  function modifier_battlemage_oaa:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit
    local dmg_flags = event.damage_flags
    local damage = event.damage

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

    -- Check damage if 0 or negative
    if damage <= 0 then
      return
    end

    -- Don't proc on attacks
    if event.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
      return
    end

    -- Don't continue if damage has HP removal flag
    if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_HPLOSS) == DOTA_DAMAGE_FLAG_HPLOSS then
      return
    end

    -- Don't continue if damage has Reflection flag
    -- if bit.band(dmg_flags, DOTA_DAMAGE_FLAG_REFLECTION) == DOTA_DAMAGE_FLAG_REFLECTION then
      -- return
    -- end

    -- Don't proc if dead
    if not attacker:IsAlive() then
      return
    end

    -- Don't proc if damaged unit isn't visible to attacker's team (fog of war or invisible)
    if not attacker:CanEntityBeSeenByMyTeam(damaged_unit) then
      return
    end

    -- Don't proc if Battle Mage is on cooldown
    if attacker:HasModifier("modifier_battlemage_cooldown_oaa") then
      return
    end

    -- Start cooldown by adding a modifier
    attacker:AddNewModifier(attacker, nil, "modifier_battlemage_cooldown_oaa", {duration = self.cooldown})

    local useCastAttackOrb = false
    local processProcs = true
    local skipCooldown = true
    local ignoreInvis = false
    local useProjectile = attacker:IsRangedAttacker() -- only ranged units need a projectile
    local fakeAttack = false
    local neverMiss = not attacker:IsRangedAttacker() -- only ranged units can miss

    -- Instant attack (can trigger attack modifiers)
    attacker:PerformAttack(damaged_unit, useCastAttackOrb, processProcs, skipCooldown, ignoreInvis, useProjectile, fakeAttack, neverMiss)
  end
end

function modifier_battlemage_oaa:GetTexture()
  return "pangolier_swashbuckle"
end

---------------------------------------------------------------------------------------------------

modifier_battlemage_cooldown_oaa = class(ModifierBaseClass)

function modifier_battlemage_cooldown_oaa:IsHidden()
  return true
end

function modifier_battlemage_cooldown_oaa:IsDebuff()
  return false
end

function modifier_battlemage_cooldown_oaa:IsPurgable()
  return false
end
