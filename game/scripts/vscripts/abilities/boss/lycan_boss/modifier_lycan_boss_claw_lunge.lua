modifier_lycan_boss_claw_lunge = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:OnCreated( kv )
	if IsServer() then
		if self:ApplyHorizontalMotionController() == false then
			self:Destroy()
			return
		end
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:GetEffectName()
	return "particles/units/heroes/hero_bloodseeker/bloodseeker_thirst_owner.vpcf"
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:IsHidden()
  return true
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:IsDebuff()
  return false
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:IsPurgable()
  return false
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveHorizontalMotionController( self )
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
	}
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:CheckState()
  return {
    [MODIFIER_STATE_STUNNED] = true, -- If the parent has Debuff Protection it will not stun
    [MODIFIER_STATE_MAGIC_IMMUNE] = true, -- replace with MODIFIER_STATE_DEBUFF_IMMUNE if needed
    [MODIFIER_STATE_HEXED] = false,
    [MODIFIER_STATE_ROOTED] = false,
    [MODIFIER_STATE_SILENCED] = false,
    [MODIFIER_STATE_FROZEN] = false,
    [MODIFIER_STATE_FEARED] = false,
    --[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true, -- motion controller modifier having this is a paradox
  }
end

function modifier_lycan_boss_claw_lunge:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA + 20000 -- it needs to be higher priority than boss properties and anti-stun
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:GetOverrideAnimation()
	return ACT_DOTA_RUN_STATUE
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:UpdateHorizontalMotion( me, dt )
	if IsServer() then
		me:SetOrigin( self:GetAbility().vProjectileLocation )
	end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_claw_lunge:OnHorizontalMotionInterrupted()
  self:Destroy()
end
