modifier_shrine_oaa = class({})

function modifier_shrine_oaa:IsHidden()
  return true
end

function modifier_shrine_oaa:IsPurgable()
  return false
end

function modifier_shrine_oaa:OnCreated()
  self.ordered_heroes = {}
  local parent = self:GetParent()
  if parent:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
    self.particle_name = "particles/misc/shrines/radiant_shrine_ambient.vpcf"
  elseif parent:GetTeamNumber() == DOTA_TEAM_BADGUYS then
    self.particle_name = "particles/misc/shrines/dire_shrine_ambient.vpcf"
  end
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_shrine_oaa:OnIntervalThink()
  local parent = self:GetParent() -- shrine
  local ability = parent:FindAbilityByName("shrine_sanctuary_oaa")
  if not ability then
    self:StartIntervalThink(-1)
    return
  end
  if ability:IsCooldownReady() then
    if self:GetStackCount() ~= 1 then
      parent:EmitSound("Shrine.Recharged")
      self.particle = ParticleManager:CreateParticle(self.particle_name, PATTACH_WORLDORIGIN, parent)
      ParticleManager:SetParticleControl(self.particle, 0, parent:GetAbsOrigin())
      self:SetStackCount(1)
      self:StartIntervalThink(0.1)
    end

    for _, hero in pairs(self.ordered_heroes) do
      if hero then
        -- Check hero's last target
        if hero.hero_last_target == parent then
          local distance = (hero:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()
          -- Check if hero reached the shrine
          if distance < 200 then
            self:Sanctuary()
            break
          end
        else
          self.ordered_heroes[hero:entindex()] = nil
        end
      end
    end
  else
    parent:StopSound("Shrine.Recharged")
    if self.particle then
      ParticleManager:DestroyParticle(self.particle, false)
      ParticleManager:ReleaseParticleIndex(self.particle)
    end
    self:SetStackCount(2)
    self:StartIntervalThink(ability:GetCooldownTimeRemaining())
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

    if not hOrderedUnit or not hOrderedUnit:IsRealHero() or hOrderedUnit:GetTeamNumber() ~= parent:GetTeamNumber() then
      return
    end

    local ability = parent:FindAbilityByName("shrine_sanctuary_oaa")
    if not ability then
      return
    end
    if not ability:IsCooldownReady() then
      return
    end

    hOrderedUnit.hero_last_target = hTargetUnit

    if not hTargetUnit or hTargetUnit ~= parent then
      return
    end

    local distance = (hOrderedUnit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D()

    -- Check if hero is near the shrine, then activate immediately
    -- if not periodically check distance of all the heroes that clicked on the shrine
    if distance < 200 then
      self:Sanctuary()
    else
      --table.insert(self.ordered_heroes, hOrderedUnit)
      self.ordered_heroes[hOrderedUnit:entindex()] = hOrderedUnit
    end
  end

  function modifier_shrine_oaa:Sanctuary()
    local parent = self:GetParent()
    self.ordered_heroes = {}
    local ability = parent:FindAbilityByName("shrine_sanctuary_oaa")
    if not ability then
      return
    end
    ability:CastAbility()
  end
end