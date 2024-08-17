LinkLuaModifier("modifier_tormentor_radiance_oaa", "abilities/boss/tormentor_boss/tormentor_radiance.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tormentor_radiance_debuff_oaa", "abilities/boss/tormentor_boss/tormentor_radiance.lua", LUA_MODIFIER_MOTION_NONE)

tormentor_boss_radiance_oaa = class(AbilityBaseClass)

function tormentor_boss_radiance_oaa:GetIntrinsicModifierName()
  return "modifier_tormentor_radiance_oaa"
end

function tormentor_boss_radiance_oaa:IsStealable()
  return false
end

function tormentor_boss_radiance_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_tormentor_radiance_oaa = class(ModifierBaseClass)

function modifier_tormentor_radiance_oaa:IsHidden() -- needs tooltip
  return false
end

function modifier_tormentor_radiance_oaa:IsDebuff()
  return false
end

function modifier_tormentor_radiance_oaa:IsPurgable()
  return false
end

function modifier_tormentor_radiance_oaa:OnCreated()
  if not IsServer() then return end

  local ability = self:GetAbility()

  local dmg_per_second = ability:GetSpecialValueFor("aura_damage")
  local dmg_interval = ability:GetSpecialValueFor("aura_interval")

  self.radius = ability:GetSpecialValueFor("aura_radius")
  self.dmg_per_interval = dmg_per_second * dmg_interval

  self:StartIntervalThink(dmg_interval)
end

function modifier_tormentor_radiance_oaa:OnIntervalThink()
  local parent = self:GetParent()

  -- Don't do anything if parent doesnt exist or it's dead (don't do damage on the corpse)
  if not parent or parent:IsNull() or not parent:IsAlive() then
    return
  end

  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    parent:GetAbsOrigin(),
    nil,
    self.radius,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO),
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false
  )

  local damage_table = {
    attacker = parent,
    damage = self.dmg_per_interval,
    damage_type = DAMAGE_TYPE_MAGICAL,
    ability = self:GetAbility(),
    damage_flags = DOTA_DAMAGE_FLAG_HPLOSS,
  }

  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() and not enemy:IsMagicImmune() then
      damage_table.victim = enemy
      ApplyDamage(damage_table)
    end
  end
end

-- aura stuff

function modifier_tormentor_radiance_oaa:IsAura()
  return true
end

function modifier_tormentor_radiance_oaa:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO)
end

function modifier_tormentor_radiance_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_tormentor_radiance_oaa:GetAuraRadius()
  return self.radius
end

function modifier_tormentor_radiance_oaa:GetModifierAura()
  return "modifier_tormentor_radiance_debuff_oaa"
end

function modifier_tormentor_radiance_oaa:GetTexture()
  return "dawnbreaker_luminosity"
end

---------------------------------------------------------------------------------------------------
-- Visual effect, dmg is on aura applier
modifier_tormentor_radiance_debuff_oaa = class(ModifierBaseClass)

function modifier_tormentor_radiance_debuff_oaa:IsHidden() -- needs tooltip
  return false
end

function modifier_tormentor_radiance_debuff_oaa:IsPurgable()
  return false
end

function modifier_tormentor_radiance_debuff_oaa:IsDebuff()
  return true
end

function modifier_tormentor_radiance_debuff_oaa:GetTexture()
  return "dawnbreaker_luminosity"
end
