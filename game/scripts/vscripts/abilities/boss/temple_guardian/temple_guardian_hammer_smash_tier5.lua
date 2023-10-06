LinkLuaModifier("modifier_temple_guardian_hammer_smash_thinker", "abilities/boss/temple_guardian/modifier_temple_guardian_hammer_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

temple_guardian_hammer_smash_tier5 = class(AbilityBaseClass)

function temple_guardian_hammer_smash_tier5:ProcsMagicStick()
	return false
end

function temple_guardian_hammer_smash_tier5:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.03})
    caster:EmitSound("TempleGuardian.PreAttack")
  end
  return true
end

function temple_guardian_hammer_smash_tier5:GetPlaybackRateOverride()
  return 0.4450 -- was 0.4013 -- Playbackrate ratio should be kept inversely proportional to HammerSmash base_swing_speed
end

function temple_guardian_hammer_smash_tier5:OnSpellStart()
  local caster = self:GetCaster()
  local flSpeed = self:GetSpecialValueFor( "base_swing_speed" )
  local vToTarget = self:GetCursorPosition() - caster:GetOrigin()
  vToTarget = vToTarget:Normalized()
  local vTarget = caster:GetOrigin() + vToTarget * self:GetCastRange( caster:GetOrigin(), nil )
  CreateModifierThinker( caster, self, "modifier_temple_guardian_hammer_smash_thinker", { duration = flSpeed }, vTarget, caster:GetTeamNumber(), false )
end
