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

function modifier_arcana_dbz:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
  }
end

-- AllowIllusionDuplicate() doesn't work; SetOriginalModel doesn't work;
function modifier_arcana_dbz:GetModifierModelChange()
  return "models/heroes/sohei/sohei_arcana/sohei_arcana.vmdl"
end

if IsServer() then
  function modifier_arcana_dbz:OnCreated()
    local parent = self:GetParent()
    self.Glow = ParticleManager:CreateParticle( "particles/hero/sohei/arcana/dbz/dbz_flare_core.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent )
    ParticleManager:SetParticleControlEnt( self.Glow, 0, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt( self.Glow, 3, parent, PATTACH_POINT_FOLLOW, "attach_origin", parent:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl( self.Glow, 2, Vector(0,0,0) )
  end

  function modifier_arcana_dbz:OnDestroy()
    if self.Glow then
      ParticleManager:DestroyParticle(self.Glow, true)
      ParticleManager:ReleaseParticleIndex(self.Glow)
    end
  end
end
