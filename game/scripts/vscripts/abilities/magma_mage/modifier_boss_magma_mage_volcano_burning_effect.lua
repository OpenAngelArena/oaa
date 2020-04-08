modifier_boss_magma_mage_volcano_burning_effect = class(ModifierBaseClass)

function modifier_boss_magma_mage_volcano_burning_effect:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:IsDebuff()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:OnCreated()
  if IsServer() then
    local parent = self:GetParent()
    local nFXIndex = ParticleManager:CreateParticle("particles/boss_magma_mage_volcano_burning.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControlEnt(nFXIndex, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetOrigin(), true)
    ParticleManager:SetParticleControl(nFXIndex, 2, Vector(2,0,0))
    self.nFXIndex = nFXIndex
  end
end

function modifier_boss_magma_mage_volcano_burning_effect:OnDestroy()
  if IsServer() then
    if self.nFXIndex then
      ParticleManager:DestroyParticle(self.nFXIndex, false)
      ParticleManager:ReleaseParticleIndex(self.nFXIndex)
    end
  end
end
