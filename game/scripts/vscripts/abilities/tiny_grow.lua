--[[

Real talk, I copy and pasted this while file from
https://raw.githubusercontent.com/darklordabc/Legends-of-Dota-Redux/develop/src/game/scripts/vscripts/abilities/tiny_grow_lod.lua

Darklord is a god of the modding community; even though he doesn't contribute directly to OAA,
his existence alone is an extreme asset to our team. Thanks homie.

Refactored heavily by chrisinajar

]]
if tiny_grow_oaa == nil then tiny_grow_oaa = class(AbilityBaseClass) end

LinkLuaModifier("modifier_tiny_grow_oaa", "abilities/tiny_grow.lua", LUA_MODIFIER_MOTION_NONE) --- PATH WERY IMPORTANT


local banana

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
      if self:GetCaster():HasScepter() then
        if banana then
          if type(banana) == "table" then
          UTIL_Remove(banana)
          banana = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_01/tiny_01_tree.vmdl"})
          banana:FollowEntity(self:GetCaster(), true)
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
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_tiny_grow_oaa:OnIntervalThink()
  if self:GetCaster():GetUnitName() == "npc_dota_hero_tiny" then
    if self:GetParent():HasScepter() then
      if banana == nil then
        banana = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/tiny_01/tiny_01_tree.vmdl"})
        banana:FollowEntity(self:GetParent(), true)
      end
    else
      if banana ~= nil then
        if type(banana) == "table" then
          UTIL_Remove(banana)
        end
      end
    end
  end
end

function modifier_tiny_grow_oaa:OnDestroy()
  if self.scaleMultiplier then
    self:GetCaster():SetModelScale(self:GetCaster():GetModelScale() / self.scaleMultiplier)
  end

  if banana ~= nil then
    if type(banana) == "table" then
      UTIL_Remove(banana)
    end
  end
end

function modifier_tiny_grow_oaa:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
    MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
    MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
    MODIFIER_EVENT_ON_ATTACK_LANDED
  }

  return funcs
end

function modifier_tiny_grow_oaa:GetModifierMoveSpeedBonus_Constant (params)
  local hAbility = self:GetAbility ()
  return hAbility:GetSpecialValueFor ("bonus_movement_speed")
end

function modifier_tiny_grow_oaa:GetModifierPreAttack_BonusDamage (params)
  local hAbility = self:GetAbility ()
  return hAbility:GetSpecialValueFor ("bonus_damage")
end

function modifier_tiny_grow_oaa:GetModifierAttackSpeedBonus_Constant (params)
  local hAbility = self:GetAbility ()
  return hAbility:GetSpecialValueFor ("bonus_attack_speed")
end

function modifier_tiny_grow_oaa:GetModifierAttackRangeBonus (params)
  if self:GetParent():HasScepter() then
    local hAbility = self:GetAbility ()
    return hAbility:GetSpecialValueFor ("bonus_range_scepter")
  else
    return 0
  end
end

function modifier_tiny_grow_oaa:OnAttackLanded (params)
  if IsServer () then
    if self:GetParent():HasScepter() then
      if params.attacker == self:GetParent() and ( not self:GetParent():IsIllusion() ) then
        if self:GetParent():PassivesDisabled() then
          return 0
        end
        local target = params.target
        EmitSoundOn( "DOTA_Item.BattleFury", target )
        if target ~= nil and target:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
          local cleaveDamage = ( self:GetAbility():GetSpecialValueFor( "bonus_cleave_damage_scepter" ) * params.damage ) / 100.0
          DoCleaveAttack( self:GetParent(), target, self:GetAbility(), cleaveDamage, self:GetAbility():GetSpecialValueFor( "cleave_starting_width" ), self:GetAbility():GetSpecialValueFor( "cleave_ending_width" ), self:GetAbility():GetSpecialValueFor( "cleave_distance" ), "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf" )
        end

      end
    end
  end
  return 0
end
