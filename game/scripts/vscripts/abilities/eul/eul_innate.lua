LinkLuaModifier("modifier_eul_innate_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_hurricane_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)

eul_innate_oaa = class(AbilityBaseClass)

function eul_innate_oaa:GetIntrinsicModifierName()
  return "modifier_eul_innate_oaa"
end

---------------------------------------------------------------------------------------------------
modifier_eul_innate_oaa = class(ModifierBaseClass)

function modifier_eul_innate_oaa:IsHidden()
  return true
end

function modifier_eul_innate_oaa:IsDebuff()
  return false
end

function modifier_eul_innate_oaa:IsPurgable()
  return false
end

function modifier_eul_innate_oaa:RemoveOnDeath()
  return false
end

function modifier_eul_innate_oaa:OnCreated()
  -- local ability = self:GetAbility()
  -- if ability and not ability:IsNull() then
    -- self.dmg = ability:GetSpecialValueFor("")
  -- else
    -- self.dmg = 0
  -- end
end

modifier_eul_innate_oaa.OnRefresh = modifier_eul_innate_oaa.OnCreated

function modifier_eul_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

if IsServer() then
  function modifier_eul_innate_oaa:OnAbilityExecuted(event)
    local parent = self:GetParent()
    local cast_ability = event.ability
    local target = event.target
    local caster = event.unit

    if not cast_ability or cast_ability:IsNull() or not target or target:IsNull() or not caster or caster:IsNull() then
      return
    end

    if parent ~= caster then
      return
    end

    local hurricane = parent:FindAbilityByName("eul_hurricane_oaa")
    if not hurricane then
      return
    end

    -- Check if cast ability is Hurricane
    if cast_ability:GetAbilityName() ~= hurricane:GetAbilityName() then
      return
    end

    -- Check if target is on the enemy team
    if target:GetTeamNumber() == parent:GetTeamNumber() then
      return
    end

    -- Applying the debuff tracker
    target:AddNewModifier(parent, hurricane, "modifier_eul_hurricane_oaa", {})
  end
end

---------------------------------------------------------------------------------------------------

modifier_eul_hurricane_oaa = class(ModifierBaseClass)

function modifier_eul_hurricane_oaa:IsHidden()
  return true
end

function modifier_eul_hurricane_oaa:IsDebuff()
  return false
end

function modifier_eul_hurricane_oaa:IsPurgable()
  return false
end

function modifier_eul_hurricane_oaa:RemoveOnDeath()
  return true
end

function modifier_eul_hurricane_oaa:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0)
  end
end

function modifier_eul_hurricane_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() or not ability or ability:IsNull() or not caster or caster:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Check if parent still has the vanilla ModifierBaseClass
  if not parent:HasModifier("modifier_enraged_wildkin_hurricane") then
    self:StartIntervalThink(-1)
    self:Destroy()
  end
end

function modifier_eul_hurricane_oaa:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local ability = self:GetAbility()
  local caster = self:GetCaster()
  if not parent or parent:IsNull() or not ability or ability:IsNull() or not caster or caster:IsNull() then
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    return
  end

  local damage = ability:GetSpecialValueFor("damage")

  local damage_table = {
    attacker = caster,
    victim = parent,
    damage = damage,
    damage_type = ability:GetAbilityDamageType(),
    ability = ability,
  }

  ApplyDamage(damage_table)

  -- Try to stop sound loops
  caster:StopSound("n_creep_Wildkin.Tornado")
  if parent and not parent:IsNull() then
    parent:StopSound("n_creep_Wildkin.Tornado")
  end
end
