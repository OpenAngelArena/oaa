modifier_boss_magma_mage_volcano = class(ModifierBaseClass)

GRAVITY_DECEL = 800
--------------------------------------------------------------------------------
function modifier_boss_magma_mage_volcano:IsHidden()
  return true
end

function modifier_boss_magma_mage_volcano:IsStunDebuff()
  return true
end

function modifier_boss_magma_mage_volcano:IsAura()
  return false
end

function modifier_boss_magma_mage_volcano:IsDebuff()
  return true
end

function modifier_boss_magma_mage_volcano:IsPurgable()
  return false
end

function modifier_boss_magma_mage_volcano:IsPurgeException()
  return true
end

function modifier_boss_magma_mage_volcano:RemoveOnDeath()
  return true
end

function modifier_boss_magma_mage_volcano:DeclareFunctions()
  local funcs = {
  MODIFIER_PROPERTY_OVERRIDE_ANIMATION
  }
  return funcs
end

function modifier_boss_magma_mage_volcano:GetOverrideAnimation( params )
  return ACT_DOTA_FLAIL
end

function modifier_boss_magma_mage_volcano:OnCreated( kv )
  if IsServer() then
    --set speed so that the rise/fall will match the knockup duration
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
  return
end

function modifier_boss_magma_mage_volcano:OnRefresh( kv )
  if IsServer() then
    local hParent = self:GetParent()
    hParent:RemoveVerticalMotionController(self)
    self.speed = kv.duration*GRAVITY_DECEL/2
    if self:ApplyVerticalMotionController() == false then
      self:Destroy()
    end
  end
  return
end


function modifier_boss_magma_mage_volcano:OnDestroy()
  if IsServer() then
    local hParent = self:GetParent()
    hParent:RemoveVerticalMotionController(self)
  end
  return
end

function modifier_boss_magma_mage_volcano:UpdateVerticalMotion( me, dt )
  if IsServer() then
    local parent = self:GetParent()
    local iVectLength = self.speed*dt
    self.speed = self.speed - GRAVITY_DECEL*dt
    local vVect = iVectLength*Vector(0,0,1)
    parent:SetOrigin(parent:GetOrigin()+vVect)
  end
  return
end

function modifier_boss_magma_mage_volcano:CheckState()
  local state = {
  [MODIFIER_STATE_STUNNED] = true
  }
  return state
end

