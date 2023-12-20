LinkLuaModifier("modifier_ogre_tank_melee_smash_thinker", "abilities/boss/ogre_tank_boss/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

ogre_tank_boss_jump_smash = class(AbilityBaseClass)

function ogre_tank_boss_jump_smash:ProcsMagicStick()
  return false
end

function ogre_tank_boss_jump_smash:GetPlaybackRateOverride()
  return self:GetSpecialValueFor("jump_speed") / 1.5 -- 0.9 for 1.8, 0.7 for 1.5
end

function ogre_tank_boss_jump_smash:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})
  end
  return true
end

function ogre_tank_boss_jump_smash:OnSpellStart()
  local caster = self:GetCaster()
  CreateModifierThinker(caster, self, "modifier_ogre_tank_melee_smash_thinker", { duration = self:GetSpecialValueFor( "jump_speed") }, caster:GetOrigin(), caster:GetTeamNumber(), false)
end
