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

end

modifier_eul_innate_oaa.OnRefresh = modifier_eul_innate_oaa.OnCreated

function modifier_eul_innate_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_ABILITY_EXECUTED,
  }
end

if IsServer() then
  function modifier_eul_innate_oaa:OnAbilityExecuted(event)
    local cast_ability = event.ability
    local target = event.target
    local caster = event.unit

    if not cast_ability or cast_ability:IsNull() or not target or target:IsNull() or not caster or caster:IsNull() then
      return
    end

    -- Find Hurricane ability (it can be on the Rubick or Morphling too and they don't have this innate)
    local hurricane = caster:FindAbilityByName("eul_hurricane_oaa")
    if not hurricane then
      return
    end

    -- Check if cast ability is Hurricane
    if cast_ability:GetAbilityName() ~= hurricane:GetAbilityName() then
      return
    end

    -- Check if target is on the enemy team
    if target:GetTeamNumber() == caster:GetTeamNumber() then
      return
    end

    -- Applying the debuff tracker
    target:AddNewModifier(caster, hurricane, "modifier_eul_hurricane_oaa", {})
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
  local caster = self:GetCaster()
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
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
  if not parent or parent:IsNull() or not caster or caster:IsNull() then
    return
  end

  -- Check if parent is dead
  if not parent:IsAlive() then
    return
  end

  if not ability or ability:IsNull() then
    ability = caster:FindAbilityByName("eul_hurricane_oaa")
    if not ability then
      return -- sorry Rubick and Morphling
    end
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
  local sound_name = "n_creep_Wildkin.Tornado"
  caster:StopSound(sound_name)
  StopSoundOn(sound_name, caster)
  if parent and not parent:IsNull() then
    parent:StopSound(sound_name)
    StopSoundOn(sound_name, parent)
  end
end
