
modifier_ardm = class(ModifierBaseClass)

function modifier_ardm:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN
  }
end

function modifier_ardm:OnRespawn(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  if event.unit ~= parent then
    return
  end

  if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() then
    return
  end

  if ARDMMode then
    ARDMMode:ReplaceHero(parent, self.hero)
  end
end

function modifier_ardm:IsHidden()
  return true
end
function modifier_ardm:IsDebuff()
  return false
end
function modifier_ardm:IsPurgable()
  return false
end
function modifier_ardm:IsPurgeException()
  return false
end
function modifier_ardm:IsPermanent()
  return true
end
function modifier_ardm:RemoveOnDeath()
  return false
end
