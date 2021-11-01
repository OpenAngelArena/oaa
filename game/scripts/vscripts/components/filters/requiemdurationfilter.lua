if RequiemDurationFilter == nil then
  RequiemDurationFilter = class({})
end

function RequiemDurationFilter:Init ()
  self.moduleName = "RequiemDurationFilter"

  LinkLuaModifier("modifier_oaa_requiem_allowed", "components/filters/requiemdurationfilter.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_oaa_requiem_not_allowed", "components/filters/requiemdurationfilter.lua", LUA_MODIFIER_MOTION_NONE)
  FilterManager:AddFilter(FilterManager.ModifierGained, self, Dynamic_Wrap(RequiemDurationFilter, "ModifierFilter"))
end

function RequiemDurationFilter:ModifierFilter(keys)
  if not keys.entindex_parent_const or not keys.entindex_caster_const or not keys.entindex_ability_const then
    return true
  end

  local caster = EntIndexToHScript(keys.entindex_caster_const)
  local victim = EntIndexToHScript(keys.entindex_parent_const)
  local ability = EntIndexToHScript(keys.entindex_ability_const)
  local modifier_name = keys.name_const
  --local modifier_duration = keys.duration

  local ability_name = ability:GetName()

  if ability_name == "nevermore_requiem" and modifier_name == "modifier_nevermore_requiem_slow" then
    if victim:HasModifier("modifier_oaa_requiem_not_allowed") then
      return false
    end
    if caster:HasScepter() and not victim:HasModifier("modifier_oaa_requiem_allowed") then
      local max_duration = ability:GetSpecialValueFor("requiem_slow_duration_max") + 1.5 * (ability:GetSpecialValueFor("requiem_radius") / ability:GetSpecialValueFor("requiem_line_speed"))
      local talent = caster:FindAbilityByName("special_bonus_unique_nevermore_6")
      if talent and talent:GetLevel() > 0 then
        max_duration = max_duration + talent:GetSpecialValueFor("value2")
      end
      victim:AddNewModifier(caster, ability, "modifier_oaa_requiem_allowed", {duration = math.min(max_duration, 6.5), immune_time = 3})
    end
  end

  return true
end

---------------------------------------------------------------------------------------------------

modifier_oaa_requiem_allowed = modifier_oaa_requiem_allowed or class({})

function modifier_oaa_requiem_allowed:IsHidden()
	return true
end

function modifier_oaa_requiem_allowed:IsDebuff()
  return false
end

function modifier_oaa_requiem_allowed:IsPurgable()
	return false
end

function modifier_oaa_requiem_allowed:RemoveOnDeath()
  return true
end

function modifier_oaa_requiem_allowed:OnCreated(keys)
  if not IsServer() then
    return
  end
  self.immune_time = keys.immune_time
end

function modifier_oaa_requiem_allowed:OnDestroy()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  if not parent or parent:IsNull() or not self.immune_time then
    return
  end

  parent:AddNewModifier(parent, nil, "modifier_oaa_requiem_not_allowed", {duration = self.immune_time})
end

---------------------------------------------------------------------------------------------------

modifier_oaa_requiem_not_allowed = modifier_oaa_requiem_not_allowed or class({})

function modifier_oaa_requiem_not_allowed:IsHidden()
	return true
end

function modifier_oaa_requiem_not_allowed:IsDebuff()
  return false
end

function modifier_oaa_requiem_not_allowed:IsPurgable()
	return false
end

function modifier_oaa_requiem_not_allowed:RemoveOnDeath()
  return true
end

function modifier_oaa_requiem_not_allowed:OnCreated()
  if not IsServer() then
    return
  end
  self:GetParent():RemoveModifierByName("modifier_nevermore_requiem_slow")
end
