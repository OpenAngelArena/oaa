LinkLuaModifier("modifier_item_far_sight", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_item_far_sight_true_sight", "items/sight.lua", LUA_MODIFIER_MOTION_NONE)

item_far_sight = class(ItemBaseClass)

function item_far_sight:GetAOERadius()
  return self:GetSpecialValueFor("reveal_radius")
end

function item_far_sight:GetIntrinsicModifierName()
  return "modifier_item_far_sight"
end

if IsServer() then
  function item_far_sight:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorPosition()
    local casterTeam = caster:GetTeam()
    local revealDuration = self:GetSpecialValueFor("reveal_duration")

    AddFOWViewer(casterTeam, target, self:GetSpecialValueFor("reveal_radius"), revealDuration, false)
    local trueSightThinker = CreateModifierThinker(caster, self, "modifier_item_far_sight_true_sight", {duration = revealDuration}, target, casterTeam, false)
  end
end

item_far_sight_2 = item_far_sight
item_far_sight_3 = item_far_sight
item_far_sight_4 = item_far_sight

--------------------------------------------------------------------------------

modifier_item_far_sight = class(ModifierBaseClass)

function modifier_item_far_sight:IsHidden()
  return true
end

function modifier_item_far_sight:IsDebuff()
  return false
end

function modifier_item_far_sight:IsPurgable()
  return false
end

function modifier_item_far_sight:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_far_sight:DeclareFunctions()
  local funcs  = {
    MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
  return funcs
end

function modifier_item_far_sight:GetModifierPhysicalArmorBonus()
  return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_item_far_sight:GetModifierBonusStats_Strength()
  return self:GetAbility():GetSpecialValueFor("bonus_str")
end

function modifier_item_far_sight:GetModifierBonusStats_Intellect()
  return self:GetAbility():GetSpecialValueFor("bonus_int")
end

function modifier_item_far_sight:GetModifierConstantHealthRegen()
  return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

--------------------------------------------------------------------------------

modifier_item_far_sight_true_sight = class(ModifierBaseClass)

function modifier_item_far_sight_true_sight:IsHidden()
  return true
end

function modifier_item_far_sight_true_sight:IsPurgable()
  return false
end

function modifier_item_far_sight_true_sight:IsAura()
  return true
end

if IsServer() then
  function modifier_item_far_sight_true_sight:OnCreated()
    self.revealRadius = self:GetAbility():GetSpecialValueFor("reveal_radius")

    if IsServer() then
      self.nFXIndex = ParticleManager:CreateParticle( "particles/items/far_sight.vpcf", PATTACH_CUSTOMORIGIN, nil )
      ParticleManager:SetParticleControl( self.nFXIndex, 0, self:GetParent():GetOrigin() )
      ParticleManager:SetParticleControl( self.nFXIndex, 1, Vector(self.revealRadius, 0, 0) )
    end
  end
end

function modifier_item_far_sight_true_sight:GetModifierAura()
  return "modifier_truesight"
end

function modifier_item_far_sight_true_sight:GetAuraRadius()
  return self.revealRadius
end

function modifier_item_far_sight_true_sight:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_item_far_sight_true_sight:GetAuraSearchType()
  return bit.bor(DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_OTHER)
end

function modifier_item_far_sight_true_sight:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE)
end

function modifier_item_far_sight_true_sight:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle( self.nFXIndex , false)
    ParticleManager:ReleaseParticleIndex( self.nFXIndex )
    UTIL_Remove(self:GetParent())
  end
end
