-- Modifier for handling construction of Azazel buildings
-- Expects its parent ability to have "health", "construction_time", "sink_hegiht", and "think_interval" special values
-- Defaults to not making the building rise from the ground if no "sink_hegiht" is set
-- Defaults to "think_interval" of 0.1

-- If you look at this and wonder why it doesn't use SetMaxHealth,
-- it's because for some weird reason, doing that causes the max health to revert when the modifier is destroyed
-- #ThanksValve

LinkLuaModifier("modifier_building_health", "modifiers/modifier_building_construction.lua", LUA_MODIFIER_MOTION_NONE)

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
    parent:AddNewModifier(parent, ability, "modifier_building_health", {})
    self.constructionTime = ability:GetSpecialValueFor("construction_time")
    self.maxHealth = ability:GetSpecialValueFor("health")
    self.initialSinkHeight = ability:GetSpecialValueFor("sink_height")
    self.thinkInterval = ability:GetSpecialValueFor("think_interval")
    if self.thinkInterval == 0 then
      self.thinkInterval = 0.1
    end

    local origin = parent:GetOrigin()
    parent:SetAbsOrigin(Vector(origin.x, origin.y, origin.z-self.initialSinkHeight))

    PreventGettingStuck(parent, origin)

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

    local origin = parent:GetOrigin()
    parent:SetAbsOrigin(Vector(origin.x, origin.y, origin.z+self.initialSinkHeight / self.totalTicks))

    -- The call in OnCreated often does not push units out, so call continuously to
    -- ensure units don't get stuck inside the building
    PreventGettingStuck(parent, origin)

    self.ticksRemaining = self.ticksRemaining - 1
  end
end

function modifier_building_construction:CheckState()
  return {
    [MODIFIER_STATE_DISARMED] = true,
    [MODIFIER_STATE_BLIND] = true,
    [MODIFIER_STATE_FROZEN] = true -- Freeze animation to prevent choppiness as calling SetOrigin resets the animation
  }
end

function modifier_building_construction:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
  }
end

function modifier_building_construction:GetModifierConstantHealthRegen()
  if IsServer() then
    return self.maxHealth * 0.99 / self.constructionTime
  end
end



modifier_building_health = class(ModifierBaseClass)

function modifier_building_health:IsHidden()
  return true
end

function modifier_building_health:IsPurgable()
  return false
end

if IsServer() then
  function modifier_building_health:OnCreated()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    self.initialMaxHealth = parent:GetMaxHealth()
    self.maxHealth = ability:GetSpecialValueFor("health")
  end
end

function modifier_building_health:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS
  }
end

function modifier_building_health:GetModifierExtraHealthBonus()
  if self.maxHealth == 0 then
    return 0
  else
    return self.maxHealth - self.initialMaxHealth
  end
end
