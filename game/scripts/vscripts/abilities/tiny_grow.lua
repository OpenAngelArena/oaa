--[[

Real talk, I copy and pasted this while file from
https://raw.githubusercontent.com/darklordabc/Legends-of-Dota-Redux/develop/src/game/scripts/vscripts/abilities/tiny_grow_lod.lua

Darklord is a god of the modding community; even though he doesn't contribute directly to OAA,
his existence alone is an extreme asset to our team. Thanks homie.

Refactored heavily by chrisinajar
Updated by Darkonius

]]
tiny_grow_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_tiny_grow_oaa", "abilities/tiny_grow.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_tiny_grow_vanilla_mod_applier", "abilities/tiny_grow.lua", LUA_MODIFIER_MOTION_NONE)

function tiny_grow_oaa:GetIntrinsicModifierName()
  return "modifier_tiny_grow_oaa"
end

-- 'Hack' to make Tiny cosmetics work
function tiny_grow_oaa:OnUpgrade()
  local caster = self:GetCaster()
  local ability_level = self:GetLevel()
  local vanilla_ability = caster:FindAbilityByName("tiny_grow")

  if not vanilla_ability then
    return
  end

  if vanilla_ability:GetLevel() == 3 or ability_level >= 4 then
    return
  end

  -- Set level of vanilla Grow
  vanilla_ability:SetLevel(ability_level)
  -- Adding vanilla modifier manually because UpgradeAbility, OnUpgrade or RefreshIntrinsicModifier methods don't work
  --caster:AddNewModifier(caster, vanilla_ability, "modifier_tiny_grow", {})
  -- 'modifier_tiny_grow' is dispellable, very cool Valve :D
  -- So we add an aura that applies 'modifier_tiny_grow'
  -- this is a weird (but working) 'hack' to make 'modifier_tiny_grow' undispellable
  caster:AddNewModifier(caster, vanilla_ability, "modifier_tiny_grow_vanilla_mod_applier", {})
end
  -- if self:GetCaster():GetUnitName() == "npc_dota_hero_tiny" then
    -- local level_1 = "models/heroes/tiny_02/tiny_02.vmdl"
    -- local level_2 = "models/heroes/tiny_03/tiny_03.vmdl"
    -- local level_3 = "models/heroes/tiny_04/tiny_04.vmdl"

    -- if self:GetLevel() == 1 then
      -- self:GetCaster():SetOriginalModel(level_1)
      -- self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_body.vmdl"})
      -- self.torso:FollowEntity(self:GetCaster(), true)
      -- self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_head.vmdl"})
      -- self.head:FollowEntity(self:GetCaster(), true)
      -- self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_left_arm.vmdl"})
      -- self.left_arm:FollowEntity(self:GetCaster(), true)
      -- self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_right_arm.vmdl"})
      -- self.rigt_arm:FollowEntity(self:GetCaster(), true)
    -- elseif self:GetLevel() == 2 then
      -- self:GetCaster():SetOriginalModel(level_2)
      -- UTIL_Remove(self.torso)
      -- UTIL_Remove(self.head)
      -- UTIL_Remove(self.left_arm)
      -- UTIL_Remove(self.rigt_arm)

      -- self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_body.vmdl"})
      -- self.torso:FollowEntity(self:GetCaster(), true)
      -- self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_head.vmdl"})
      -- self.head:FollowEntity(self:GetCaster(), true)
      -- self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_left_arm.vmdl"})
      -- self.left_arm:FollowEntity(self:GetCaster(), true)
      -- self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_right_arm.vmdl"})
      -- self.rigt_arm:FollowEntity(self:GetCaster(), true)
    -- elseif self:GetLevel() >= 3 then
      -- UTIL_Remove(self.torso)
      -- UTIL_Remove(self.head)
      -- UTIL_Remove(self.left_arm)
      -- UTIL_Remove(self.rigt_arm)

      -- self:GetCaster():SetOriginalModel(level_3)

      -- self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_body.vmdl"})
      -- self.torso:FollowEntity(self:GetCaster(), true)
      -- self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_head.vmdl"})
      -- self.head:FollowEntity(self:GetCaster(), true)
      -- self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_left_arm.vmdl"})
      -- self.left_arm:FollowEntity(self:GetCaster(), true)
      -- self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_right_arm.vmdl"})
      -- self.rigt_arm:FollowEntity(self:GetCaster(), true)

      -- if self:GetLevel() > 3 then
        -- if not self.scaleMultiplier then
          -- self.scaleMultiplier = 1
        -- end
        -- local desiredScale = 1 + ((self:GetLevel() - 3) * 0.2)
        -- if desiredScale ~= self.scaleMultiplier then
          -- self:GetCaster():SetModelScale(desiredScale * self:GetCaster():GetModelScale() / self.scaleMultiplier)
          -- self.scaleMultiplier = desiredScale
        -- end
      -- end
    -- end
  -- end

---------------------------------------------------------------------------------------------------

modifier_tiny_grow_oaa = class(ModifierBaseClass)

function modifier_tiny_grow_oaa:IsHidden()
  return true
end

function modifier_tiny_grow_oaa:IsDebuff()
  return false
end

function modifier_tiny_grow_oaa:IsPurgable()
  return false
end

function modifier_tiny_grow_oaa:RemoveOnDeath()
  return false
end

function modifier_tiny_grow_oaa:OnCreated()
  self.bonus_armor = 0
  self.bonus_damage = 0
  --self.attack_speed_reduction = 0
  self.model_scale = 0

  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.bonus_armor = ability:GetSpecialValueFor("bonus_armor_oaa")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage_oaa")
  --self.attack_speed_reduction = ability:GetSpecialValueFor("attack_speed_reduction_oaa")
  self.model_scale = ability:GetSpecialValueFor("model_scale_oaa")
  self.slow_resist = ability:GetSpecialValueFor("bonus_slow_resistance")

  local parent = self:GetParent()
  -- Fix for illusions not getting 'modifier_tiny_grow'
  if parent:IsIllusion() and IsServer() then
    local vanilla_ability = parent:FindAbilityByName("tiny_grow")

    if not vanilla_ability then
      return
    end

    parent:AddNewModifier(parent, vanilla_ability, "modifier_tiny_grow_vanilla_mod_applier", {})
  end
end

function modifier_tiny_grow_oaa:OnRefresh()
  local ability = self:GetAbility()
  if not ability or ability:IsNull() then
    return
  end

  self.bonus_armor = ability:GetSpecialValueFor("bonus_armor_oaa")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage_oaa")
  --self.attack_speed_reduction = ability:GetSpecialValueFor("attack_speed_reduction_oaa")
  self.model_scale = ability:GetSpecialValueFor("model_scale_oaa")
  self.slow_resist = ability:GetSpecialValueFor("bonus_slow_resistance")
end

function modifier_tiny_grow_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    --MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    --MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,   -- this is bonus raw damage (green)
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,     -- this is bonus base damage (white)
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
    MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE,
    MODIFIER_PROPERTY_SLOW_RESISTANCE,
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

function modifier_tiny_grow_oaa:GetModifierPhysicalArmorBonus()
  return self.bonus_armor or 0
end

-- function modifier_tiny_grow_oaa:GetModifierPreAttack_BonusDamage()
  -- return self.bonus_damage or 0
-- end

function modifier_tiny_grow_oaa:GetModifierBaseAttack_BonusDamage()
  local parent = self:GetParent()
  if parent:HasModifier("modifier_tiny_tree_grab") then
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return 0
    end
    local talent = parent:FindAbilityByName("special_bonus_unique_tiny_7")
    if talent and talent:GetLevel() > 0 then
      return ability:GetSpecialValueFor("bonus_damage_with_tree_and_talent")
    end
    return ability:GetSpecialValueFor("bonus_damage_with_tree")
  end
  return self.bonus_damage or 0
end

-- function modifier_tiny_grow_oaa:GetModifierAttackSpeedBonus_Constant()
  -- if not self.attack_speed_reduction then
    -- return 0
  -- end
  -- return 0 - math.abs(self.attack_speed_reduction)
-- end

function modifier_tiny_grow_oaa:GetModifierModelScale()
  return self.model_scale or 0
end

if IsServer() then
  function modifier_tiny_grow_oaa:GetModifierOverrideAbilitySpecial(keys)
    if not keys.ability or not keys.ability_special_value then
      return 0
    end
    if keys.ability_special_value == "toss_damage" then
      return 1
    end
    return 0
  end

  function modifier_tiny_grow_oaa:GetModifierOverrideAbilitySpecialValue(keys)
    local value = keys.ability:GetLevelSpecialValueNoOverride(keys.ability_special_value, keys.ability_special_level)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return value
    end
    if keys.ability_special_value == "toss_damage" then
      return value + ability:GetSpecialValueFor("bonus_toss_damage_oaa")
    end
    return value
  end

  function modifier_tiny_grow_oaa:GetModifierSlowResistance()
    return self.slow_resist or 0
  end

  function modifier_tiny_grow_oaa:OnAbilityExecuted(event)
    local cast_ability = event.ability
    local caster = event.unit

    if not cast_ability or cast_ability:IsNull() or not caster or caster:IsNull() then
      return
    end

    if caster ~= self:GetParent() then
      return
    end

    if cast_ability:GetAbilityName() ~= "tiny_tree_channel" then
      return
    end

    local number_of_trees = 4
    for i = 1, number_of_trees do
      local random_location = caster:GetAbsOrigin() + RandomVector(500)
      CreateTempTree(random_location, 3)
      ResolveNPCPositions(random_location, 64.0)
    end
  end
end

---------------------------------------------------------------------------------------------------

modifier_tiny_grow_vanilla_mod_applier = class(ModifierBaseClass)

function modifier_tiny_grow_vanilla_mod_applier:IsHidden()
  return true
end

function modifier_tiny_grow_vanilla_mod_applier:IsDebuff()
  return false
end

function modifier_tiny_grow_vanilla_mod_applier:IsPurgable()
  return false
end

function modifier_tiny_grow_vanilla_mod_applier:RemoveOnDeath()
  return false
end

function modifier_tiny_grow_vanilla_mod_applier:IsAura()
  return true
end

function modifier_tiny_grow_vanilla_mod_applier:GetModifierAura()
  return "modifier_tiny_grow"
end

function modifier_tiny_grow_vanilla_mod_applier:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_tiny_grow_vanilla_mod_applier:GetAuraSearchType()
  return DOTA_UNIT_TARGET_HERO
end

function modifier_tiny_grow_vanilla_mod_applier:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD)
end

function modifier_tiny_grow_vanilla_mod_applier:GetAuraRadius()
  return 200
end

function modifier_tiny_grow_vanilla_mod_applier:GetAuraEntityReject(hEntity)
  local parent = self:GetParent() -- using parent instead of caster so it works on illusions too
  -- Dont provide the aura effect to other heroes than Tiny
  if hEntity ~= parent then
    return true
  end
  return false
end
