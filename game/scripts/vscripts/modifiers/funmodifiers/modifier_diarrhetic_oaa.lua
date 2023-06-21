LinkLuaModifier("modifier_ward_invisibility", "modifiers/modifier_ward_invisibility.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_generic_dead_tracker_oaa", "modifiers/modifier_generic_dead_tracker_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_diarrhetic_oaa = class(ModifierBaseClass)

function modifier_diarrhetic_oaa:IsHidden()
  return false
end

function modifier_diarrhetic_oaa:IsDebuff()
  return true
end

function modifier_diarrhetic_oaa:IsPurgable()
  return false
end

function modifier_diarrhetic_oaa:RemoveOnDeath()
  return false
end

function modifier_diarrhetic_oaa:OnCreated()
  local interval = 30
  self.check_for_ward_radius = POOP_WARD_RADIUS
  self.duration = 2 * interval

  if IsServer() then
    self:StartIntervalThink(interval)
  end
end

if IsServer() then
  function modifier_diarrhetic_oaa:OnIntervalThink()
    local parent = self:GetParent()
    local position = parent:GetAbsOrigin()
    local team = parent:GetTeamNumber()
    local no_wards_nearby = true

    local wards = FindUnitsInRadius(
      team,
      position,
      nil,
      self.check_for_ward_radius,
      DOTA_UNIT_TARGET_TEAM_FRIENDLY,
      DOTA_UNIT_TARGET_OTHER,
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    for _, v in pairs(wards) do
      if v and not v:IsNull() and (v:HasModifier("modifier_item_buff_ward") or v:HasModifier("modifier_ward_invisibility")) then
        no_wards_nearby = false
        break
      end
    end

    if no_wards_nearby then
      local observer = CreateUnitByName("npc_dota_observer_wards", position, true, nil, parent, team)
      observer:AddNewModifier(parent, nil, "modifier_kill", {duration = self.duration})
      observer:AddNewModifier(parent, nil, "modifier_generic_dead_tracker_oaa", {duration = self.duration + MANUAL_GARBAGE_CLEANING_TIME})
      observer:AddNewModifier(parent, nil, "modifier_ward_invisibility", {})
    else
      local sentry = CreateUnitByName("npc_dota_sentry_wards", position, true, nil, parent, team)
      sentry:AddNewModifier(parent, nil, "modifier_kill", {duration = self.duration})
      sentry:AddNewModifier(parent, nil, "modifier_generic_dead_tracker_oaa", {duration = self.duration + MANUAL_GARBAGE_CLEANING_TIME})
      sentry:AddNewModifier(parent, nil, "modifier_ward_invisibility", {})
      sentry:AddNewModifier(parent, nil, "modifier_item_ward_true_sight", {
        true_sight_range = 700,
        duration = self.duration
      })
    end
  end
end

function modifier_diarrhetic_oaa:GetTexture()
  return "item_ward_observer"
end
