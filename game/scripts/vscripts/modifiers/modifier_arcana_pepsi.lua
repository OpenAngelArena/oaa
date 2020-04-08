--------------------------------------------------------------------------------

-- Modifier Sohei Arcana pepsi
modifier_arcana_pepsi = class(ModifierBaseClass)

function modifier_arcana_pepsi:IsHidden()
	return true
end

function modifier_arcana_pepsi:IsPurgable()
	return false
end

function modifier_arcana_pepsi:IsDebuff()
	return false
end

function modifier_arcana_pepsi:RemoveOnDeath()
	return false
end

function modifier_arcana_pepsi:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

------------------------------------------------------------------------------------

function modifier_arcana_pepsi:GetModifierModelChange( params )
  return "models/heroes/sohei/bepis_sohei/bepis_sohei_base.vmdl"
end

------------------------------------------------------------------------------------

function modifier_arcana_pepsi:DeclareFunctions()
	return
    {
      MODIFIER_PROPERTY_MODEL_CHANGE
    }
end

function modifier_arcana_pepsi:OnCreated()

  if IsServer() then
    local parent = self:GetParent()
    self.Glow = ParticleManager:CreateParticle( "particles/hero/sohei/arcana/pepsi/pepsi_flare_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( self.Glow, 0, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt( self.Glow, 3, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl( self.Glow, 2, Vector(0,0,0) )
  end
end
