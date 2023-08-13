
modifier_ardm = class(ModifierBaseClass)

function modifier_ardm:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN
  }
end

if IsServer() then
  function modifier_ardm:OnRespawn(event)
    local parent = self:GetParent()

    if event.unit ~= parent then
      return
    end

    if not parent:IsRealHero() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
      return
    end

    if ARDMMode and self.allowed then
      ARDMMode:ReplaceHero(parent, self.hero)
    end
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
function modifier_ardm:RemoveOnDeath()
  return false
end
