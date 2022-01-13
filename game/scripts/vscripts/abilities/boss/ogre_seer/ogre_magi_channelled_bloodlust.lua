LinkLuaModifier( "modifier_ogre_magi_channelled_bloodlust", "abilities/boss/ogre_seer/modifier_ogre_magi_channelled_bloodlust", LUA_MODIFIER_MOTION_NONE )

ogre_magi_channelled_bloodlust = class(AbilityBaseClass)

-----------------------------------------------------------------------------

function ogre_magi_channelled_bloodlust:OnSpellStart()
  local hTarget = self:GetCursorTarget()
  if hTarget then
    local caster = self:GetCaster()
    self.hTarget = hTarget
    hTarget:AddNewModifier( caster, self, "modifier_ogre_magi_channelled_bloodlust", { duration = -1 } )

    hTarget:EmitSound( "OgreMagi.Bloodlust.Target")
    hTarget:EmitSound( "OgreMagi.Bloodlust.Target.FP")
    caster:EmitSound("OgreMagi.Bloodlust.Loop")

    local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf", PATTACH_CUSTOMORIGIN, caster )
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( nFXIndex, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetOrigin(), true  )
    ParticleManager:SetParticleControlEnt( nFXIndex, 2, hTarget, PATTACH_POINT_FOLLOW, "attach_hitloc", hTarget:GetOrigin(), true )
    ParticleManager:SetParticleControlEnt( nFXIndex, 3, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), true )
    ParticleManager:ReleaseParticleIndex( nFXIndex )
  end
end

-----------------------------------------------------------------------------

function ogre_magi_channelled_bloodlust:OnChannelFinish( bInterrupted )
  local caster = self:GetCaster()
  if bInterrupted then
    self:StartCooldown( self:GetSpecialValueFor( "interrupted_cooldown" ) )
  end

  if self.hTarget and not self.hTarget:IsNull() then
    local hMyBuff = self.hTarget:FindModifierByNameAndCaster( "modifier_ogre_magi_channelled_bloodlust", caster )
    if hMyBuff then
      hMyBuff:Destroy()
    end
    caster:StopSound("OgreMagi.Bloodlust.Loop")
    self.hTarget = nil
  end
end
