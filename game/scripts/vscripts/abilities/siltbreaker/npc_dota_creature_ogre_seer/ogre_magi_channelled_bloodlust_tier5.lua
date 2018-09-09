ogre_magi_channelled_bloodlust_tier5 = class(AbilityBaseClass)
LinkLuaModifier( "modifier_ogre_magi_channelled_bloodlust", "modifiers/modifier_ogre_magi_channelled_bloodlust", LUA_MODIFIER_MOTION_NONE )

-----------------------------------------------------------------------------

function ogre_magi_channelled_bloodlust_tier5:OnSpellStart()
	if IsServer() then
		local hTarget = self:GetCursorTarget()
    if hTarget ~= nil then
      local caster = self:GetCaster()
			self.hTarget = hTarget
			self.hTarget:AddNewModifier( caster, self, "modifier_ogre_magi_channelled_bloodlust", { duration = -1 } )

			self.hTarget:EmitSound( "OgreMagi.Bloodlust.Target")
			self.hTarget:EmitSound( "OgreMagi.Bloodlust.Target.FP")
			caster:EmitSound("OgreMagi.Bloodlust.Loop")

			local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf", PATTACH_CUSTOMORIGIN, caster )
			ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true  )
			ParticleManager:SetParticleControlEnt( nFXIndex, 2, self.hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", self.hTarget:GetOrigin(), true )
			ParticleManager:SetParticleControlEnt( nFXIndex, 3, self.hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, self.hTarget:GetOrigin(), true   )
			ParticleManager:ReleaseParticleIndex( nFXIndex )
		end
	end
end

-----------------------------------------------------------------------------

function ogre_magi_channelled_bloodlust_tier5:OnChannelFinish( bInterrupted )
  if IsServer() then
    local caster = self:GetCaster()
		if bInterrupted then
			self:StartCooldown( self:GetSpecialValueFor( "interrupted_cooldown" ) )
		end

		if self.hTarget ~= nil then
			local hMyBuff = self.hTarget:FindModifierByNameAndCaster( "modifier_ogre_magi_channelled_bloodlust", caster )
			if hMyBuff then
				hMyBuff:Destroy()
			end
			caster:StopSound("OgreMagi.Bloodlust.Loop")
			self.hTarget = nil
		end
	end
end

-----------------------------------------------------------------------------

