LinkLuaModifier("modifier_anti_stun_oaa", "modifiers/modifier_anti_stun_oaa.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_ogre_tank_melee_smash_thinker", "abilities/boss/ogre_tank_boss/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

ogre_tank_boss_jump_smash_tier5  = class(AbilityBaseClass)

function ogre_tank_boss_jump_smash_tier5:ProcsMagicStick()
  return false
end

function ogre_tank_boss_jump_smash_tier5:GetPlaybackRateOverride()
  return self:GetSpecialValueFor("jump_speed") / 1.5 -- 0.9 for 1.8, 0.7 for 1.5
end

function ogre_tank_boss_jump_smash_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay})
  end
  return true
end

function ogre_tank_boss_jump_smash_tier5:OnSpellStart()
  local caster = self:GetCaster()
  local hThinker = CreateModifierThinker(caster, self, "modifier_ogre_tank_melee_smash_thinker", { duration = self:GetSpecialValueFor( "jump_speed") }, caster:GetOrigin(), caster:GetTeamNumber(), false)
end
