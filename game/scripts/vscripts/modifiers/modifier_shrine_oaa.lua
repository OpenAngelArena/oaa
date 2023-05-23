modifier_shrine_oaa = class({})

function modifier_shrine_oaa:IsHidden()
  return true
end

function modifier_shrine_oaa:IsPurgable()
  return false
end

function modifier_shrine_oaa:OnCreated()
  
end

function modifier_shrine_oaa:OnIntervalThink()
  local hOrderedUnit = self.ordered_hero
  if not hOrderedUnit then
    self:StartIntervalThink(-1)
    return
  end
  local parent = self:GetParent() -- shrine
  local distance = (hOrderedUnit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
  if distance < 300 then
    self:StartIntervalThink(-1)
    self:Sanctuary()
  end
end

function modifier_shrine_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
    MODIFIER_EVENT_ON_ORDER,
  }
end

function modifier_shrine_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_shrine_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_shrine_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_shrine_oaa:CheckState()
  return {
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    --[MODIFIER_STATE_OUT_OF_GAME] = true,
    --[MODIFIER_STATE_INVULNERABLE] = true,
  }
end

if IsServer() then
  function modifier_shrine_oaa:OnOrder(params)
    local parent = self:GetParent() -- shrine entity
    local hOrderedUnit = params.unit
    local hTargetUnit = params.target
    local nOrderType = params.order_type

    if nOrderType ~= DOTA_UNIT_ORDER_MOVE_TO_TARGET then
      return
    end

    if not hTargetUnit or hTargetUnit ~= parent then
      return
    end

    if not hOrderedUnit or not hOrderedUnit:IsRealHero() or hOrderedUnit:GetTeamNumber() ~= parent:GetTeamNumber() then
      return
    end

    local ability = self:FindAbilityByName("shrine_sanctuary_oaa")
    if not ability then
      return
    end

    local distance = (hOrderedUnit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()

    if distance < 300 then
      self:StartIntervalThink(-1)
      self:Sanctuary()
    else
      self.ordered_hero = hOrderedUnit
      self:StartIntervalThink(0)
    end
  end

  function modifier_shrine_oaa:Sanctuary()

  end
end