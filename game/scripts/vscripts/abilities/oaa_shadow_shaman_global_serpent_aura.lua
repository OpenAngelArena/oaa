shadow_shaman_global_serpent_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_serpent_ward_global_aura_emitter", "abilities/oaa_shadow_shaman_global_serpent_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_serpent_ward_global_aura_effect", "abilities/oaa_shadow_shaman_global_serpent_aura.lua", LUA_MODIFIER_MOTION_NONE)

function shadow_shaman_global_serpent_aura_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function shadow_shaman_global_serpent_aura_oaa:GetIntrinsicModifierName()
  return "modifier_serpent_ward_global_aura_emitter"
end

function shadow_shaman_global_serpent_aura_oaa:IsStealable()
  return false
end

function shadow_shaman_global_serpent_aura_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_serpent_ward_global_aura_emitter = class({})

function modifier_serpent_ward_global_aura_emitter:IsHidden()
  return true
end

function modifier_serpent_ward_global_aura_emitter:IsDebuff()
  return false
end

function modifier_serpent_ward_global_aura_emitter:IsPurgable()
  return false
end

function modifier_serpent_ward_global_aura_emitter:RemoveOnDeath()
  return false
end

function modifier_serpent_ward_global_aura_emitter:IsAura()
  return true
end

function modifier_serpent_ward_global_aura_emitter:GetModifierAura()
  return "modifier_serpent_ward_global_aura_effect"
end

function modifier_serpent_ward_global_aura_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_serpent_ward_global_aura_emitter:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_serpent_ward_global_aura_emitter:GetAuraRadius()
  return 20000
end

function modifier_serpent_ward_global_aura_emitter:GetAuraEntityReject(hEntity)
  if string.find(hEntity:GetUnitName(), "npc_dota_shadow_shaman_ward") then
    return false
  end
  return true
end

---------------------------------------------------------------------------------------------------

modifier_serpent_ward_global_aura_effect = class({})

function modifier_serpent_ward_global_aura_effect:IsHidden()
  return true
end

function modifier_serpent_ward_global_aura_effect:IsDebuff()
  return false
end

function modifier_serpent_ward_global_aura_effect:IsPurgable()
  return false
end

function modifier_serpent_ward_global_aura_effect:OnCreated()
  self.bonus_dmg_bosses = 0.5
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.bonus_dmg_bosses = ability:GetSpecialValueFor("damage_multiplier_against_bosses")
  end
end

function modifier_serpent_ward_global_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
    MODIFIER_EVENT_ON_ATTACK_LANDED,
  }
end

-- Fix for ward damage created with shard shackles
function modifier_serpent_ward_global_aura_effect:GetModifierBaseAttack_BonusDamage()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if not caster or caster:IsNull() then
    return 0
  end

  -- Check if caster has Aghanim Shard
  if not caster:HasShardOAA() then
    return 0
  end

  if parent.GetUnitName == nil then
    return 0
  end

  -- Check parent name
  if parent:GetUnitName() ~= "npc_dota_shadow_shaman_ward_3" then
    return 0
  end

  local mass_serpent_wards_custom = caster:FindAbilityByName("shadow_shaman_mass_serpent_ward_oaa")
  local mass_serpent_wards_vanilla = caster:FindAbilityByName("shadow_shaman_mass_serpent_ward")
  if not mass_serpent_wards_custom or not mass_serpent_wards_vanilla then
    return 0
  end

  if mass_serpent_wards_vanilla:GetLevel() < 3 or mass_serpent_wards_custom:GetLevel() <= 3 then
    return 0
  end

  return mass_serpent_wards_custom:GetSpecialValueFor("damage_tooltip") - mass_serpent_wards_vanilla:GetSpecialValueFor("damage_tooltip")
end

if IsServer() then
  function modifier_serpent_ward_global_aura_effect:OnAttackLanded(event)
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local target = event.target

    -- Doesn't work on units that dont have this modifier
    if parent ~= event.attacker then
      return
    end

    -- Check if parent has the stuff
    if parent.GetAttackDamage == nil then
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

    if target:IsOAABoss() then
      local damage_table = {
        attacker = parent,
        victim = target,
        --ability = ability,
        damage = parent:GetAttackDamage() * self.bonus_dmg_bosses,
        damage_type = DAMAGE_TYPE_MAGICAL,
      }

      ApplyDamage(damage_table)
    end
  end
end

