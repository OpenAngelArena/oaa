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

function modifier_arcana_pepsi:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end

-- AllowIllusionDuplicate() doesn't work; SetOriginalModel doesn't work;
function modifier_arcana_pepsi:GetModifierModelChange()
  return "models/heroes/sohei/bepis_sohei/bepis_sohei_base.vmdl"
end

if IsServer() then
  function modifier_arcana_pepsi:OnCreated()
    local parent = self:GetParent()
    self.Glow = ParticleManager:CreateParticle( "particles/hero/sohei/arcana/pepsi/pepsi_flare_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( self.Glow, 0, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt( self.Glow, 3, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl( self.Glow, 2, Vector(0,0,0) )
  end

  function modifier_arcana_pepsi:OnDestroy()
    if self.Glow then
      ParticleManager:DestroyParticle(self.Glow, true)
      ParticleManager:ReleaseParticleIndex(self.Glow)
    end
  end
end
