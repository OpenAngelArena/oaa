LinkLuaModifier("modifier_temple_guardian_hammer_smash_thinker", "abilities/boss/temple_guardian/modifier_temple_guardian_hammer_smash_thinker.lua", LUA_MODIFIER_MOTION_NONE)

temple_guardian_rage_hammer_smash = class(AbilityBaseClass)

function temple_guardian_rage_hammer_smash:ProcsMagicStick()
	return false
end

function temple_guardian_rage_hammer_smash:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    local delay = self:GetCastPoint()

    caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", {duration = delay + 0.03})
    caster:EmitSound("TempleGuardian.PreAttack")
  end
  return true
end

function temple_guardian_rage_hammer_smash:GetPlaybackRateOverride()
  return 0.6090 -- was 0.5500 -- Playbackrate ratio should be kept inversely proportional to RageHammerSmash base_swing_speed
end

function temple_guardian_rage_hammer_smash:OnSpellStart()
  local caster = self:GetCaster()
  local flSpeed = self:GetSpecialValueFor( "base_swing_speed" )
  local vToTarget = self:GetCursorPosition() - caster:GetOrigin()
  vToTarget = vToTarget:Normalized()
  local vTarget = caster:GetOrigin() + vToTarget * self:GetCastRange( caster:GetOrigin(), nil )
  CreateModifierThinker( caster, self, "modifier_temple_guardian_hammer_smash_thinker", { duration = flSpeed }, vTarget, caster:GetTeamNumber(), false )
end
