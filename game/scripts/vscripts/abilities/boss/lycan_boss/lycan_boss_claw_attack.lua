LinkLuaModifier("modifier_lycan_boss_claw_attack", "abilities/boss/lycan_boss/modifier_lycan_boss_claw_attack", LUA_MODIFIER_MOTION_NONE)

lycan_boss_claw_attack = class(AbilityBaseClass)

function lycan_boss_claw_attack:Precache(context)
  PrecacheResource("particle", "particles/test_particle/generic_attack_crit_blur.vpcf", context)
  PrecacheResource("particle", "particles/test_particle/generic_attack_crit_blur_shapeshift.vpcf", context)
  PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_lycan.vsndevts", context)
end

function lycan_boss_claw_attack:OnAbilityPhaseStart()
  if IsServer() then
    local caster = self:GetCaster()
    self.animation_time = self:GetSpecialValueFor( "animation_time" )
    self.initial_delay = self:GetSpecialValueFor( "initial_delay" )
    self.shapeshift_animation_time = self:GetSpecialValueFor( "shapeshift_animation_time" )
    self.shapeshift_initial_delay = self:GetSpecialValueFor( "shapeshift_initial_delay" )

    local bShapeshift = caster:HasModifier( "modifier_lycan_boss_shapeshift" )
    if RandomInt( 0, 1 ) == 1 then
      self:PlayClawAttackSpeech( bShapeshift )
    end

    local kv = {}
    if bShapeshift then
      kv["duration"] = self.shapeshift_animation_time
      kv["initial_delay"] = self.shapeshift_initial_delay
    else
      kv["duration"] = self.animation_time
      kv["initial_delay"] = self.initial_delay
    end

    caster:AddNewModifier(caster, self, "modifier_lycan_boss_claw_attack", kv)
    --caster:AddNewModifier(caster, self, "modifier_anti_stun_oaa", kv)
  end

  return true
end

--------------------------------------------------------------------------------

function lycan_boss_claw_attack:OnAbilityPhaseInterrupted()
	if IsServer() then
		self:GetCaster():RemoveModifierByName( "modifier_lycan_boss_claw_attack" )
	end
end

--------------------------------------------------------------------------------

function lycan_boss_claw_attack:GetPlaybackRateOverride()
	return 0.4
end

--------------------------------------------------------------------------------

function lycan_boss_claw_attack:GetCastRange( vLocation, hTarget )
	if IsServer() then
		if self:GetCaster():FindModifierByName( "modifier_lycan_boss_claw_attack" ) ~= nil then
			return 99999
		end
	end

	return self.BaseClass.GetCastRange( self, vLocation, hTarget )
end

--------------------------------------------------------------------------------

function lycan_boss_claw_attack:PlayClawAttackSpeech( bShapeshift )
  if IsServer() then
    local caster = self:GetCaster()
    local nSound = RandomInt( 0, 3 )
    if nSound == 1 then
      caster:EmitSound("lycan_lycan_pain_01")
    elseif nSound == 2 then
      caster:EmitSound("lycan_lycan_pain_08")
    else
      if bShapeshift then
        if nSound == 0 then
          caster:EmitSound("lycan_lycan_wolf_attack_01")
        elseif nSound == 3 then
          caster:EmitSound("lycan_lycan_wolf_attack_10")
        end
      elseif nSound == 0 then
        caster:EmitSound("lycan_lycan_attack_01")
      elseif nSound == 3 then
        caster:EmitSound("lycan_lycan_pain_09")
      end
    end
  end
end
