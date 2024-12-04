LinkLuaModifier("modifier_eul_innate_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_eul_hurricane_oaa", "abilities/eul/eul_innate.lua", LUA_MODIFIER_MOTION_NONE)

eul_innate_oaa = class(AbilityBaseClass)

function eul_innate_oaa:Spawn()
  if IsServer() then
    if FilterManager then
      FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(self, "FilterOrders"))
    end
  end
end

function eul_innate_oaa:GetIntrinsicModifierName()
  return "modifier_eul_innate_oaa"
end

function eul_innate_oaa:FilterOrders(keys)
  local order = keys.order_type
  local units = keys.units
  local playerID = keys.issuer_player_id_const

  local unit_with_order
  if units and units["0"] then
    unit_with_order = EntIndexToHScript(units["0"])
  end
  local ability_index = keys.entindex_ability
  local ability
  if ability_index then
    ability = EntIndexToHScript(ability_index)
  end
  local target_index = keys.entindex_target
  local target
  if target_index then
    target = EntIndexToHScript(target_index)
  end

  if order == DOTA_UNIT_ORDER_CAST_TARGET then
    -- Check if needed variables exist
    if unit_with_order and ability and target then
      -- Get ability name
      local ability_name = ability:GetAbilityName()
      -- Prevent targetting if certain conditions are fulfilled
      if target:GetTeamNumber() ~= unit_with_order:GetTeamNumber() and ability_name == "eul_hurricane_oaa" then
        -- Simulate Spell Block (and Spell Reflection)
        if target:TriggerSpellAbsorb(ability) then
          ability:UseResources(true, false, false, true)
          return false
        end
      end
    end
  end

  return true
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

    -- Check for dispel
    local dispel = hurricane:GetSpecialValueFor("dispel") == 1

    -- Check if target is on the enemy team
    if target:GetTeamNumber() == caster:GetTeamNumber() then
      -- Dispel allies
      if dispel then
        target:Purge(false, true, false, false, false)
      end
      return
    else
      -- Purge enemies before the damage
      if dispel then
        target:Purge(true, false, false, false, false)
      end
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

  -- Try to stop sound loops (does not work, it stops sounds only if the spell is reflected)
  local sound_name = "n_creep_Wildkin.Tornado"
  caster:StopSound(sound_name)
  StopSoundOn(sound_name, caster)
  if parent and not parent:IsNull() then
    parent:StopSound(sound_name)
    StopSoundOn(sound_name, parent)
  end
end
