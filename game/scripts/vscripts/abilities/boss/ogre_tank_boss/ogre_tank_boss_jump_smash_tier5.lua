LinkLuaModifier("modifier_ogre_tank_melee_smash_thinker", "abilities/boss/ogre_tank_boss/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

ogre_tank_boss_jump_smash_tier5  = class(AbilityBaseClass)

function ogre_tank_boss_jump_smash_tier5:ProcsMagicStick()
  return false
end

function ogre_tank_boss_jump_smash_tier5:GetPlaybackRateOverride()
  return self:GetSpecialValueFor("jump_speed") / 2
end

function ogre_tank_boss_jump_smash_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local cast_point = self:GetCastPoint()
    local jump_duration = self:GetSpecialValueFor("jump_speed")
    local delay = cast_point + jump_duration

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})
  end
  return true
end

function ogre_tank_boss_jump_smash_tier5:OnSpellStart()
  local caster = self:GetCaster()
  CreateModifierThinker(caster, self, "modifier_ogre_tank_melee_smash_thinker", { duration = self:GetSpecialValueFor( "jump_speed") }, caster:GetOrigin(), caster:GetTeamNumber(), false)
end
