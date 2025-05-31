wraith_king_global_skeleton_aura_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_skeleton_global_aura_emitter", "abilities/oaa_wraith_king_global_skeleton_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_skeleton_global_aura_effect", "abilities/oaa_wraith_king_global_skeleton_aura.lua", LUA_MODIFIER_MOTION_NONE)

function wraith_king_global_skeleton_aura_oaa:Spawn()
  if IsServer() then
    self:SetLevel(1)
  end
end

function wraith_king_global_skeleton_aura_oaa:GetIntrinsicModifierName()
  return "modifier_skeleton_global_aura_emitter"
end

function wraith_king_global_skeleton_aura_oaa:IsStealable()
  return false
end

function wraith_king_global_skeleton_aura_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_skeleton_global_aura_emitter = class({})

function modifier_skeleton_global_aura_emitter:IsHidden()
  return true
end

function modifier_skeleton_global_aura_emitter:IsDebuff()
  return false
end

function modifier_skeleton_global_aura_emitter:IsPurgable()
  return false
end

function modifier_skeleton_global_aura_emitter:RemoveOnDeath()
  return false
end

function modifier_skeleton_global_aura_emitter:IsAura()
  return true
end

function modifier_skeleton_global_aura_emitter:GetModifierAura()
  return "modifier_skeleton_global_aura_effect"
end

function modifier_skeleton_global_aura_emitter:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_skeleton_global_aura_emitter:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL
end

function modifier_skeleton_global_aura_emitter:GetAuraRadius()
  return 20000
end

function modifier_skeleton_global_aura_emitter:GetAuraEntityReject(hEntity)
  if hEntity:GetUnitName() ~= "npc_dota_wraith_king_skeleton_warrior" then
    return true
  end
  return false
end

---------------------------------------------------------------------------------------------------

modifier_skeleton_global_aura_effect = class({})

function modifier_skeleton_global_aura_effect:IsHidden()
  return true
end

function modifier_skeleton_global_aura_effect:IsDebuff()
  return false
end

function modifier_skeleton_global_aura_effect:IsPurgable()
  return false
end

function modifier_skeleton_global_aura_effect:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_per_level = ability:GetSpecialValueFor("skeleton_attack_damage_per_level")
    self.as_per_level = ability:GetSpecialValueFor("skeleton_attack_speed_per_level")
    self.bonus_dmg_creeps = ability:GetSpecialValueFor("skeleton_bonus_damage_against_creeps")
    self.bonus_dmg_bosses = ability:GetSpecialValueFor("skeleton_bonus_damage_against_bosses")
  end
end

function modifier_skeleton_global_aura_effect:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.dmg_per_level = ability:GetSpecialValueFor("skeleton_attack_damage_per_level")
    self.as_per_level = ability:GetSpecialValueFor("skeleton_attack_speed_per_level")
    self.bonus_dmg_creeps = ability:GetSpecialValueFor("skeleton_bonus_damage_against_creeps")
    self.bonus_dmg_bosses = ability:GetSpecialValueFor("skeleton_bonus_damage_against_bosses")
  end
end

function modifier_skeleton_global_aura_effect:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, -- GetModifierProcAttack_BonusDamage_Physical
    MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL, -- GetModifierProcAttack_BonusDamage_Magical
  }
end

function modifier_skeleton_global_aura_effect:GetModifierPreAttack_BonusDamage()
  local caster = self:GetCaster()
  if caster and not caster:IsNull() then
    local level = caster:GetLevel()
    return (level - 1) * self.dmg_per_level
  end
  return 0
end

if IsServer() then
  function modifier_skeleton_global_aura_effect:GetModifierAttackSpeedBonus_Constant()
    local caster = self:GetCaster()
    if caster and not caster:IsNull() then
      local level = caster:GetLevel()
      return (level - 1) * self.as_per_level
    end
    return 0
  end

  function modifier_skeleton_global_aura_effect:GetModifierProcAttack_BonusDamage_Physical(event)
    local target = event.target

    -- To prevent crashes:
    if not target or target:IsNull() then
      return 0
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return 0
    end

    -- Ignore buildings, wards, heroes, illusions, clones and bosses
    if target:IsTower() or target:IsBuilding() or target:IsOther() or target:IsHero() or target:IsClone() or target:IsTempestDouble() or target:IsOAABoss() then
      return 0
    end

    return self.bonus_dmg_creeps
  end

  function modifier_skeleton_global_aura_effect:GetModifierProcAttack_BonusDamage_Magical(event)
    local target = event.target

    -- To prevent crashes:
    if not target or target:IsNull() then
      return 0
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have that method -> nil; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return 0
    end

    -- Ignore buildings, wards, heroes, illusions, clones and creeps
    if target:IsTower() or target:IsBuilding() or target:IsOther() or target:IsClone() or target:IsTempestDouble() or not target:IsOAABoss() then
      return 0
    end

    return self.bonus_dmg_bosses
  end
end

