LinkLuaModifier("modifier_boss_slime_split_passive", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_boss_slime_invulnerable_oaa", "abilities/boss/slime/boss_slime_split.lua", LUA_MODIFIER_MOTION_NONE)

boss_slime_split = class(AbilityBaseClass)

function boss_slime_split:GetIntrinsicModifierName()
	return "modifier_boss_slime_split_passive"
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_split_passive = class(ModifierBaseClass)

function modifier_boss_slime_split_passive:IsHidden()
  return true
end

function modifier_boss_slime_split_passive:IsDebuff()
  return false
end

function modifier_boss_slime_split_passive:IsPurgable()
  return false
end

function modifier_boss_slime_split_passive:RemoveOnDeath()
	return true
end

function modifier_boss_slime_split_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_MIN_HEALTH, -- GetMinHealth
    MODIFIER_PROPERTY_MODEL_CHANGE, -- GetModifierModelChange
    MODIFIER_PROPERTY_MODEL_SCALE, -- GetModifierModelScale
    MODIFIER_EVENT_ON_TAKEDAMAGE, -- OnTakeDamage
    MODIFIER_EVENT_ON_DEATH, -- OnDeath
  }
end

function modifier_boss_slime_split_passive:GetMinHealth()
  if not self.readyToDie then
    return 1
  end
end

function modifier_boss_slime_split_passive:GetModifierModelChange()
  return "models/creeps/darkreef/blob/darkreef_blob_01.vmdl"
end

function modifier_boss_slime_split_passive:GetModifierModelScale()
  return 150
end

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
        parent:AddNewModifier(parent, shakeAbility, "modifier_boss_slime_invulnerable_oaa", {})
        -- Do stuff after a delay
        self:StartIntervalThink(shakeAbility:GetChannelTime())
      end
    end
	end

  function modifier_boss_slime_split_passive:OnIntervalThink()
    local parent = self:GetParent()
    local ability = self:GetAbility()
    self.readyToDie = true
    self:StartIntervalThink(-1)
    if not parent or parent:IsNull() then
      return
    end
    parent:RemoveModifierByName("modifier_boss_slime_invulnerable_oaa")
    parent:AddNoDraw()
    if parent.SetClones then
      parent:SetClones(
        self:CreateClone(parent:GetAbsOrigin() + Vector( 100,0,0)),
        self:CreateClone(parent:GetAbsOrigin() + Vector(-100,0,0))
      )
    end
    Timers:CreateTimer(function()
      if parent and not parent:IsNull() then
        --parent:Kill(ability, parent) -- crashes
        parent:ForceKillOAA(false)
      end
    end)
  end

  -- Needed for deaths not caused by ForceKill, OnDeath ignores ForceKill deaths
  function modifier_boss_slime_split_passive:OnDeath(event)
    local caster = self:GetParent()
    if not caster then
      return
    end
    if event.unit == caster then
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

function modifier_boss_slime_split_passive:CreateClone(origin)
  local caster = self:GetParent()
  local unitName = caster:GetUnitName()
  local clone = CreateUnitByName(unitName, origin, true, caster, caster, caster:GetTeamNumber())
  clone:RemoveAbility("boss_slime_split")
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = caster:GetItemInSlot(i)
    if item then
      --clone:AddItem(CreateItem(item:GetName(), clone, clone))
      clone:AddItemByName(item:GetName())
    end
  end
  return clone
end

---------------------------------------------------------------------------------------------------

modifier_boss_slime_invulnerable_oaa = class(ModifierBaseClass)

function modifier_boss_slime_invulnerable_oaa:IsHidden()
  return true
end

function modifier_boss_slime_invulnerable_oaa:IsDebuff()
  return false
end

function modifier_boss_slime_invulnerable_oaa:IsPurgable()
  return false
end

function modifier_boss_slime_invulnerable_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_boss_slime_invulnerable_oaa:CheckState()
  return {
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
  }
end
