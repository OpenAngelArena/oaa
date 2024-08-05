LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)

--------------------------------------------------------------------------------

boss_slime_split = class(AbilityBaseClass)

--------------------------------------------------------------------------------

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

------------------------------------------------------------------------------------

modifier_boss_slime_split_passive = class(ModifierBaseClass)


------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetModifierModelChange()
	return "models/creeps/darkreef/blob/darkreef_blob_01.vmdl"
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MODEL_CHANGE,
    MODIFIER_PROPERTY_MIN_HEALTH,
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_MODEL_SCALE,
    MODIFIER_EVENT_ON_TAKEDAMAGE
  }
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetPriority()
  return MODIFIER_PRIORITY_SUPER_ULTRA
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:RemoveOnDeath()
	return true
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetMinHealth()
	if self.readyToDie then return nil end
	return 1.0
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:GetModifierModelScale()
	return 150.0
end

------------------------------------------------------------------------------------

if IsServer() then
  function modifier_boss_slime_split_passive:OnTakeDamage(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local damaged_unit = event.unit

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    -- Check if damaged entity exists
    if not damaged_unit or damaged_unit:IsNull() then
      return
    end

    -- Check if damaged entity is the parent
    if damaged_unit ~= parent then
      return
    end

    if parent:GetHealth() == 1.0 then
      local shakeAbility = parent:FindAbilityByName("boss_slime_shake")
      if shakeAbility then
        parent:Stop()
        shakeAbility:EndCooldown()
        ExecuteOrderFromTable({
          UnitIndex = parent:entindex(),
          OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
          AbilityIndex = shakeAbility:entindex(),
        })
        parent:AddNewModifier(parent, shakeAbility, "modifier_invulnerable", {})
        -- Do stuff after a delay
        self:StartIntervalThink(shakeAbility:GetChannelTime())
      end
    end
	end

  function modifier_boss_slime_split_passive:OnIntervalThink()
    local parent = self:GetParent()
    self.readyToDie = true
    self:StartIntervalThink(-1)
    parent:RemoveModifierByName("modifier_invulnerable")
    Timers:CreateTimer(function()
      if parent and not parent:IsNull() then
        parent:Kill(nil, parent)
      end
    end)
  end

  function modifier_boss_slime_split_passive:OnDeath(keys)
    local caster = self:GetParent()
    if keys.unit:entindex() == caster:entindex() then
      if caster.SetClones then
        caster:SetClones(
          self:CreateClone(caster:GetAbsOrigin() + Vector( 100,0,0)),
          self:CreateClone(caster:GetAbsOrigin() + Vector(-100,0,0))
        )
      end
      caster:AddNoDraw()
    end
  end
end

------------------------------------------------------------------------------------

function modifier_boss_slime_split_passive:CreateClone(origin)
  local caster = self:GetParent()
  local unitName = caster:GetUnitName()
  local clone = CreateUnitByName(unitName, origin, true, caster, caster, caster:GetTeamNumber())
  clone:RemoveAbility("boss_slime_split")
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(i)
    if item then
      clone:AddItem(CreateItem(item:GetName(), clone, clone))
    end
  end
  return clone
end
