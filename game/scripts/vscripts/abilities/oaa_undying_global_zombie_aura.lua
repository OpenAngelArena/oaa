undying_global_zombie_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_zombie_global_aura_emitter", "abilities/oaa_undying_global_zombie_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_zombie_global_aura_effect", "abilities/oaa_undying_global_zombie_aura.lua", LUA_MODIFIER_MOTION_NONE)

function undying_global_zombie_aura_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function undying_global_zombie_aura_oaa:GetIntrinsicModifierName()
  return "modifier_zombie_global_aura_emitter"
end

function undying_global_zombie_aura_oaa:IsStealable()
  return false
end

function undying_global_zombie_aura_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_zombie_global_aura_emitter = class(ModifierBaseClass)

function modifier_zombie_global_aura_emitter:IsHidden()
  return true
end

function modifier_zombie_global_aura_emitter:IsDebuff()
  return false
end

function modifier_zombie_global_aura_emitter:IsPurgable()
  return false
end

function modifier_zombie_global_aura_emitter:RemoveOnDeath()
  return false
end

function modifier_zombie_global_aura_emitter:IsAura()
  return true
end

function modifier_zombie_global_aura_emitter:GetModifierAura()
  return "modifier_zombie_global_aura_effect"
end

function modifier_zombie_global_aura_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_zombie_global_aura_emitter:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_zombie_global_aura_emitter:GetAuraRadius()
  return 20000
end

function modifier_zombie_global_aura_emitter:GetAuraEntityReject(hEntity)
  if not hEntity:IsZombie() then
    return true
  end
  return false
end

---------------------------------------------------------------------------------------------------

modifier_zombie_global_aura_effect = class(ModifierBaseClass)

function modifier_zombie_global_aura_effect:IsHidden()
  return true
end

function modifier_zombie_global_aura_effect:IsDebuff()
  return false
end

function modifier_zombie_global_aura_effect:IsPurgable()
  return false
end

function modifier_zombie_global_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_per_level = ability:GetSpecialValueFor("zombie_attack_damage_per_level")
    self.as_per_level = ability:GetSpecialValueFor("zombie_attack_speed_per_level")
    self.bonus_dmg_creeps = ability:GetSpecialValueFor("zombie_bonus_damage_against_creeps")
    self.bonus_dmg_bosses = ability:GetSpecialValueFor("zombie_bonus_damage_against_bosses")
  end
end

function modifier_zombie_global_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_per_level = ability:GetSpecialValueFor("zombie_attack_damage_per_level")
    self.as_per_level = ability:GetSpecialValueFor("zombie_attack_speed_per_level")
    self.bonus_dmg_creeps = ability:GetSpecialValueFor("zombie_bonus_damage_against_creeps")
    self.bonus_dmg_bosses = ability:GetSpecialValueFor("zombie_bonus_damage_against_bosses")
  end
end

function modifier_zombie_global_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

function modifier_zombie_global_aura_effect:GetModifierPreAttack_BonusDamage()
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    local level = caster:GetLevel()
    return (level - 1) * self.dmg_per_level
  end
  return 0
end

if IsServer() then
  function modifier_zombie_global_aura_effect:GetModifierAttackSpeedBonus_Constant()
    local caster = self:GetCaster()
    if caster and not caster:IsNull() then
      local level = caster:GetLevel()
      return (level - 1) * self.as_per_level
    end
    return 0
  end

  function modifier_zombie_global_aura_effect:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Doesn't work on units that dont have this modifier
    if parent ~= event.attacker then
      return
    end

    -- To prevent crashes:
    if not target or target:IsNull() then
      return
    end

    -- If the unit is not actually a unit but its some weird entity
    if target.HasModifier == nil then
      return
    end

    if not ability or ability:IsNull() then
      return
    end

    local damage_table = {
      attacker = parent,
      victim = target,
      ability = ability,
    }

    if target:IsOAABoss() then
      damage_table.damage = self.bonus_dmg_bosses or ability:GetSpecialValueFor("zombie_bonus_damage_against_bosses")
      damage_table.damage_type = DAMAGE_TYPE_MAGICAL
    elseif target:IsHero() or target:IsClone() or target:IsTempestDouble() then
      return
    else
      damage_table.damage = self.bonus_dmg_creeps or ability:GetSpecialValueFor("zombie_bonus_damage_against_creeps")
      damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
    end

    ApplyDamage(damage_table)
  end
end

