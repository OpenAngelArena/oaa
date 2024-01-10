modifier_lycan_boss_shapeshift = class(ModifierBaseClass)

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:OnCreated( kv )
  if IsServer() then
    local parent = self:GetParent()
    if self.nFXIndex then
      ParticleManager:DestroyParticle(self.nFXIndex, true)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex)
      self.nFXIndex = nil
    end
    if self.nPortraitFXIndex then
      ParticleManager:DestroyParticle(self.nPortraitFXIndex, true)
      ParticleManager:ReleaseParticleIndex(self.nPortraitFXIndex)
      self.nPortraitFXIndex = nil
    end

    self.nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_shapeshift_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(self.nFXIndex, 1, parent, PATTACH_POINT_FOLLOW, "attach_mane", parent:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt(self.nFXIndex, 2, parent, PATTACH_POINT_FOLLOW, "attach_tail", parent:GetOrigin(), true )

    self.nPortraitFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_lycan/lycan_shapeshift_portrait.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt(self.nPortraitFXIndex, 1, parent, PATTACH_POINT_FOLLOW, "attach_mouth", parent:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt(self.nPortraitFXIndex, 2, parent, PATTACH_POINT_FOLLOW, "attach_upper_jaw", parent:GetOrigin(), true )
  end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:OnDestroy()
  if IsServer() then
    local revert_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_shapeshift_revert.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:ReleaseParticleIndex(revert_particle)
    if self.nFXIndex then
      ParticleManager:DestroyParticle(self.nFXIndex, true)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex)
      self.nFXIndex = nil
    end
    if self.nPortraitFXIndex then
      ParticleManager:DestroyParticle(self.nPortraitFXIndex, true)
      ParticleManager:ReleaseParticleIndex(self.nPortraitFXIndex)
      self.nPortraitFXIndex = nil
    end
  end
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT,
	}
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetModifierModelChange()
	return "models/creeps/knoll_1/werewolf_boss.vmdl"
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetActivityTranslationModifiers()
	return "shapeshift"
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetModifierModelScale()
	return 75
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetModifierMoveSpeed_Absolute()
	return 550
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetModifierPercentageCooldown()
	return 50
end

--------------------------------------------------------------------------------

function modifier_lycan_boss_shapeshift:GetModifierAttackPointConstant()
	return 0.43
end
