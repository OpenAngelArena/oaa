--[[

Real talk, I copy and pasted this while file from
https://raw.githubusercontent.com/darklordabc/Legends-of-Dota-Redux/develop/src/game/scripts/vscripts/abilities/tiny_grow_lod.lua

Darklord is a god of the modding community; even though he doesn't contribute directly to OAA,
his existence alone is an extreme asset to our team. Thanks homie.

Refactored heavily by chrisinajar
Updated to 7.22 by Darkonius

]]
if tiny_grow_oaa == nil then tiny_grow_oaa = class(AbilityBaseClass) end

LinkLuaModifier("modifier_tiny_grow_oaa", "abilities/tiny_grow.lua", LUA_MODIFIER_MOTION_NONE) --- PATH WERY IMPORTANT

function tiny_grow_oaa:GetIntrinsicModifierName()
  return "modifier_tiny_grow_oaa"
end

function tiny_grow_oaa:GetBehavior ()
  return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function tiny_grow_oaa:OnUpgrade()
  if IsServer() then
    if self:GetCaster():GetUnitName() == "npc_dota_hero_tiny" then
      local level_1 = "models/heroes/tiny_02/tiny_02.vmdl"
      local level_2 = "models/heroes/tiny_03/tiny_03.vmdl"
      local level_3 = "models/heroes/tiny_04/tiny_04.vmdl"

      if self:GetLevel() == 1 then
        self:GetCaster():SetOriginalModel(level_1)
        self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_body.vmdl"})
        self.torso:FollowEntity(self:GetCaster(), true)
        self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_head.vmdl"})
        self.head:FollowEntity(self:GetCaster(), true)
        self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_left_arm.vmdl"})
        self.left_arm:FollowEntity(self:GetCaster(), true)
        self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_02/tiny_02_right_arm.vmdl"})
        self.rigt_arm:FollowEntity(self:GetCaster(), true)
      elseif self:GetLevel() == 2 then
        self:GetCaster():SetOriginalModel(level_2)
        UTIL_Remove(self.torso)
        UTIL_Remove(self.head)
        UTIL_Remove(self.left_arm)
        UTIL_Remove(self.rigt_arm)

        self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_body.vmdl"})
        self.torso:FollowEntity(self:GetCaster(), true)
        self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_head.vmdl"})
        self.head:FollowEntity(self:GetCaster(), true)
        self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_left_arm.vmdl"})
        self.left_arm:FollowEntity(self:GetCaster(), true)
        self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_03/tiny_03_right_arm.vmdl"})
        self.rigt_arm:FollowEntity(self:GetCaster(), true)
      elseif self:GetLevel() >= 3 then
        UTIL_Remove(self.torso)
        UTIL_Remove(self.head)
        UTIL_Remove(self.left_arm)
        UTIL_Remove(self.rigt_arm)

        self:GetCaster():SetOriginalModel(level_3)

        self.torso = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_body.vmdl"})
        self.torso:FollowEntity(self:GetCaster(), true)
        self.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_head.vmdl"})
        self.head:FollowEntity(self:GetCaster(), true)
        self.left_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_left_arm.vmdl"})
        self.left_arm:FollowEntity(self:GetCaster(), true)
        self.rigt_arm = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_04/tiny_04_right_arm.vmdl"})
        self.rigt_arm:FollowEntity(self:GetCaster(), true)

        if self:GetLevel() > 3 then
          if not self.scaleMultiplier then
            self.scaleMultiplier = 1
          end
          local desiredScale = 1 + ((self:GetLevel() - 3) * 0.2)
          if desiredScale ~= self.scaleMultiplier then
            self:GetCaster():SetModelScale(desiredScale * self:GetCaster():GetModelScale() / self.scaleMultiplier)
            self.scaleMultiplier = desiredScale
          end
        end
      end
    end
  end
end

if modifier_tiny_grow_oaa == nil then modifier_tiny_grow_oaa = class(ModifierBaseClass) end

function modifier_tiny_grow_oaa:IsHidden()
  return true
end

function modifier_tiny_grow_oaa:IsPurgable()
  return false
end

function modifier_tiny_grow_oaa:OnCreated()
  local ability = self:GetAbility()
  self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  self.attack_speed_reduction = ability:GetSpecialValueFor("attack_speed_reduction")
end

function modifier_tiny_grow_oaa:OnRefresh()
  local ability = self:GetAbility()
  self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
  self.bonus_damage = ability:GetSpecialValueFor("bonus_damage")
  self.attack_speed_reduction = ability:GetSpecialValueFor("attack_speed_reduction")
end

function modifier_tiny_grow_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    --MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,   -- this is bonus raw damage (green)
    MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE     -- this is bonus base damage (white)
  }

  return funcs
end

function modifier_tiny_grow_oaa:GetModifierPhysicalArmorBonus()
  return self.bonus_armor
end

--function modifier_tiny_grow_oaa:GetModifierPreAttack_BonusDamage()
  --return self.bonus_damage
--end

function modifier_tiny_grow_oaa:GetModifierBaseAttack_BonusDamage()
  return self.bonus_damage
end

function modifier_tiny_grow_oaa:GetModifierAttackSpeedBonus_Constant()
  return 0 - math.abs(self.attack_speed_reduction)
end
