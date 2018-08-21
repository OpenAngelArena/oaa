--------------------------------------------------------------------------------

-- Modifier Sohei Arcana dbz
modifier_arcana_dbz = class(ModifierBaseClass)

function modifier_arcana_dbz:IsHidden()
	return true
end

function modifier_arcana_dbz:IsPurgable()
	return false
end

function modifier_arcana_dbz:IsDebuff()
	return false
end

function modifier_arcana_dbz:RemoveOnDeath()
	return false
end

function modifier_arcana_dbz:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

------------------------------------------------------------------------------------

function modifier_arcana_dbz:GetModifierModelChange( params )
	return "models/heroes/sohei/sohei_arcana/sohei_arcana.vmdl"
end

------------------------------------------------------------------------------------

function modifier_arcana_dbz:DeclareFunctions()
	return
    {
      MODIFIER_PROPERTY_MODEL_CHANGE
    }
end

function modifier_arcana_dbz:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    self.Glow = ParticleManager:CreateParticle( "particles/hero/sohei/arcana/dbz/dbz_flare_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( self.Glow, 0, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt( self.Glow, 3, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl( self.Glow, 2, Vector(0,0,0) )
  end
end
