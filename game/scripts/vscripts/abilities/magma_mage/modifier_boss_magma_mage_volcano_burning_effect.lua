modifier_boss_magma_mage_volcano_burning_effect = class(ModifierBaseClass)

--------------------------------------------------------------------------------
function modifier_boss_magma_mage_volcano_burning_effect:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:IsDebuff()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano_burning_effect:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano_burning_effect:DeclareFunctions()
  local funcs = {
  }
  return funcs
end

function modifier_boss_magma_mage_volcano_burning_effect:OnCreated()
  if IsServer() then
    local nFXIndex = ParticleManager:CreateParticle( "particles/boss_magma_mage_volcano_burning.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControlEnt( nFXIndex, 0, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, nil, self:GetParent():GetOrigin(), true )
    ParticleManager:SetParticleControl(nFXIndex, 2, Vector(2,0,0))
    self.nFXIndex = nFXIndex
  end
  return
end


function modifier_boss_magma_mage_volcano_burning_effect:OnDestroy()
  if IsServer() then
    ParticleManager:DestroyParticle(self.nFXIndex, false)
    ParticleManager:ReleaseParticleIndex( self.nFXIndex )
  end
  return
end

function modifier_boss_magma_mage_volcano_burning_effect:CheckState()
  local state = {
  }
  return state
end

