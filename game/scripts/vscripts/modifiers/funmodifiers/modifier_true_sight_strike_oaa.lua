LinkLuaModifier("modifier_truesight_aura_effect_oaa", "modifiers/funmodifiers/modifier_true_sight_strike_oaa.lua", LUA_MODIFIER_MOTION_NONE)

-- Keeper of the Truth

modifier_true_sight_strike_oaa = class(ModifierBaseClass)

function modifier_true_sight_strike_oaa:IsHidden()
  return false
end

function modifier_true_sight_strike_oaa:IsDebuff()
  return false
end

function modifier_true_sight_strike_oaa:IsPurgable()
  return false
end

function modifier_true_sight_strike_oaa:RemoveOnDeath()
  return false
end

function modifier_true_sight_strike_oaa:OnCreated()
  self.radius = 800
end

function modifier_true_sight_strike_oaa:IsAura()
  return true
end

function modifier_true_sight_strike_oaa:GetModifierAura()
  return "modifier_truesight_aura_effect_oaa"
end

function modifier_true_sight_strike_oaa:GetAuraSearchTeam()
  return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_true_sight_strike_oaa:GetAuraSearchType()
  return DOTA_UNIT_TARGET_ALL --bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC)
end

function modifier_true_sight_strike_oaa:GetAuraSearchFlags()
  return bit.bor(DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS)
end

function modifier_true_sight_strike_oaa:GetAuraRadius()
  return self.radius
end

function modifier_true_sight_strike_oaa:CheckState()
  return {
    [MODIFIER_STATE_CANNOT_MISS] =  true,
  }
end

function modifier_true_sight_strike_oaa:GetTexture()
  return "item_gem"
end

---------------------------------------------------------------------------------------------------

modifier_truesight_aura_effect_oaa = class(ModifierBaseClass)

function modifier_truesight_aura_effect_oaa:IsHidden()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if not caster or caster:IsNull() or parent:HasModifier("modifier_slark_shadow_dance") or parent:HasModifier("modifier_slark_depth_shroud") then
    return true
  end

  return false
end

function modifier_truesight_aura_effect_oaa:IsDebuff()
  return true
end

function modifier_truesight_aura_effect_oaa:IsPurgable()
  return false
end

function modifier_truesight_aura_effect_oaa:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_truesight_aura_effect_oaa:CheckState()
  local parent = self:GetParent()
  local caster = self:GetCaster()

  if parent.HasModifier and (not caster or caster:IsNull() or parent:HasModifier("modifier_slark_shadow_dance") or parent:HasModifier("modifier_slark_depth_shroud")) then
    return {}
  end

  return {
    [MODIFIER_STATE_INVISIBLE] = false
  }
end

function modifier_truesight_aura_effect_oaa:GetEffectName()
  local parent = self:GetParent()

  if parent.IsRealHero and parent:IsRealHero() then
    return "particles/generic_gameplay/generic_has_quest.vpcf"
  end

  return
end

function modifier_truesight_aura_effect_oaa:GetEffectAttachType()
  return PATTACH_OVERHEAD_FOLLOW
end

--[[ -- doesn't work
function modifier_truesight_aura_effect_oaa:GetStatusEffectName()
  local parent = self:GetParent()
  if parent.IsIllusion and parent:IsIllusion() then
    return "particles/status_fx/status_effect_dark_seer_illusion.vpcf"
  end
  return
end

function modifier_truesight_aura_effect_oaa:StatusEffectPriority()
  local parent = self:GetParent()
  if parent.IsIllusion and parent:IsIllusion() then
    return MODIFIER_PRIORITY_SUPER_ULTRA + 10000
  else
    return MODIFIER_PRIORITY_LOW
  end
end
]]

function modifier_truesight_aura_effect_oaa:GetTexture()
  return "item_gem"
end
