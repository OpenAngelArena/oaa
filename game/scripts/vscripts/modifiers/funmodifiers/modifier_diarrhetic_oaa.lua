
modifier_diarrhetic_oaa = class(ModifierBaseClass)

function modifier_diarrhetic_oaa:IsHidden()
  return false
end

function modifier_diarrhetic_oaa:IsDebuff()
  return false
end

function modifier_diarrhetic_oaa:IsPurgable()
  return false
end

function modifier_diarrhetic_oaa:RemoveOnDeath()
  return false
end

function modifier_diarrhetic_oaa:OnCreated()
  local interval = 15
  self.check_for_ward_radius = POOP_WARD_RADIUS
  self.duration = 4 * interval
  self.base_dmg = 100
  self.max_hp_dmg = 20

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

    local enemies = FindUnitsInRadius(
      team,
      position,
      nil,
      500,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      bit.bor(DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_BASIC),
      DOTA_UNIT_TARGET_FLAG_NONE,
      FIND_ANY_ORDER,
      false
    )

    local damage_table = {
      attacker = parent,
      damage_type = DAMAGE_TYPE_MAGICAL,
      damage_flags = DOTA_DAMAGE_FLAG_NONE,
    }

    for _, enemy in pairs(enemies) do
      if enemy and not enemy:IsNull() then
        damage_table.victim = enemy
        damage_table.damage = self.base_dmg + self.max_hp_dmg * enemy:GetMaxHealth() * 0.01
        ApplyDamage(damage_table)
      end
    end
  end
end

function modifier_diarrhetic_oaa:GetTexture()
  return "item_ward_observer"
end
