-- Modifier for handling construction of Azazel buildings
-- Expects its parent ability to have "health", "construction_time", "sink_hegiht", and "think_interval" special values
-- Defaults to not making the building rise from the ground if no "sink_hegiht" is set
-- Defaults to "think_interval" of 0.1

modifier_building_construction = class(ModifierBaseClass)

function modifier_building_construction:IsHidden()
  return true
end

function modifier_building_construction:IsPurgable()
  return false
end

if IsServer() then
  function modifier_building_construction:OnCreated()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    self.constructionTime = ability:GetSpecialValueFor("construction_time")
    self.maxHealth = ability:GetSpecialValueFor("health")
    self.initialSinkHeight = ability:GetSpecialValueFor("sink_height")
    self.thinkInterval = ability:GetSpecialValueFor("think_interval")
    if self.thinkInterval == 0 then
      self.thinkInterval = 0.1
    end

    local origin = parent:GetOrigin()
    parent:SetOrigin(GetGroundPosition(origin, parent) - Vector(0, 0, self.initialSinkHeight))

    ResolveNPCPositions(origin, parent:GetHullRadius())

    parent:SetMaxHealth(self.maxHealth)
    parent:SetHealth(self.maxHealth * 0.01)

    self.totalTicks = math.floor(self.constructionTime / self.thinkInterval)
    self.ticksRemaining = self.totalTicks
    self:StartIntervalThink(self.thinkInterval)
  end

  function modifier_building_construction:OnIntervalThink()
    if self.ticksRemaining <= 0 then
      self:StartIntervalThink(-1)
      self:Destroy()
      return
    end
    local parent = self:GetParent()

    -- Setting max health directly after spawning pretty much never works, so this ensures max health gets set corretly
    if parent:GetMaxHealth() ~= self.maxHealth then
      parent:SetMaxHealth(self.maxHealth)
    end

    local origin = parent:GetOrigin()
    parent:SetOrigin(origin + Vector(0, 0, self.initialSinkHeight / self.totalTicks))

    ResolveNPCPositions(origin, parent:GetHullRadius())

    self.ticksRemaining = self.ticksRemaining - 1
  end
end

function modifier_building_construction:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_FROZEN] = true
  }
end

function modifier_building_construction:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
  }
end

function modifier_building_construction:GetModifierConstantHealthRegen()
  return self.maxHealth * 0.99 / self.constructionTime
end
