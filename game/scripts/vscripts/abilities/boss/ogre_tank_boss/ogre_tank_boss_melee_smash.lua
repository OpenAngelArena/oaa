LinkLuaModifier("modifier_ogre_tank_melee_smash_thinker", "abilities/boss/ogre_tank_boss/modifier_ogre_tank_melee_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

ogre_tank_boss_melee_smash = class(AbilityBaseClass)

function ogre_tank_boss_melee_smash:ProcsMagicStick()
	return false
end

function ogre_tank_boss_melee_smash:GetCooldown( iLevel )
  -- the cooldown should be lower than the default value if hasted by ogre seer
	return self.BaseClass.GetCooldown( self, self:GetLevel() ) / math.max( self:GetCaster():GetHasteFactor(), 1.0 )
end

function ogre_tank_boss_melee_smash:GetPlaybackRateOverride()
	return math.min( 2.0, math.max( self:GetCaster():GetHasteFactor(), 1.0 ) )
end

function ogre_tank_boss_melee_smash:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local cast_point = self:GetCastPoint()
    local smash_duration = self:GetSpecialValueFor("base_swing_speed") / self:GetPlaybackRateOverride()
    local delay = cast_point + smash_duration

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.1})
  end
  return true
end

function ogre_tank_boss_melee_smash:OnSpellStart()
  local caster = self:GetCaster()
  caster:EmitSound("OgreTank.Grunt")
  local flSpeed = self:GetSpecialValueFor( "base_swing_speed" ) / self:GetPlaybackRateOverride()
  local vToTarget = self:GetCursorPosition() - caster:GetOrigin()
  vToTarget = vToTarget:Normalized()
  local vTarget = caster:GetOrigin() + vToTarget * self:GetCastRange( caster:GetOrigin(), nil )
  CreateModifierThinker( caster, self, "modifier_ogre_tank_melee_smash_thinker", { duration = flSpeed }, vTarget, caster:GetTeamNumber(), false )
end
