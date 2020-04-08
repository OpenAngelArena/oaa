--------------------------------------------------------------------------------

-- Modifier Sohei Arcana rockelec
modifier_arcana_rockelec = class(ModifierBaseClass)

function modifier_arcana_rockelec:IsHidden()
	return true
end

function modifier_arcana_rockelec:IsPurgable()
	return false
end

function modifier_arcana_rockelec:IsDebuff()
	return false
end

function modifier_arcana_rockelec:RemoveOnDeath()
	return false
end

function modifier_arcana_rockelec:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

------------------------------------------------------------------------------------

function modifier_arcana_rockelec:GetModifierModelChange( params )
	return "models/heroes/electrician/electrician_arcana/electrician_arcana_base.vmdl"
end

------------------------------------------------------------------------------------

function modifier_arcana_rockelec:DeclareFunctions()
	return
    {
      MODIFIER_PROPERTY_MODEL_CHANGE
    }
end

function modifier_arcana_rockelec:OnCreated()

-- THE FOLLOWING WAS COMMENTED OUT WHEN I COPIED FROM SOHEI ARCANA:

--  if IsServer() then
--    local parent = self:GetParent()
--    self.Glow = ParticleManager:CreateParticle( "particles/hero/sohei/arcana/dbz/dbz_flare_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
--    ParticleManager:SetParticleControlEnt( self.Glow, 0, parent, PATTACH_POINT_FOLLOW, "attach_origin", GetParentt:GetAbsOrigin(), true)
--    ParticleManager:SetParticleControlEnt( self.Glow, 3, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
--    ParticleManager:SetParticleControl( self.Glow, 2, Vector(0,0,0) )
--  end
end
