radiant_creeps_passives_oaa = class(AbilityBaseClass)

LinkLuaModifier("modifier_radiant_creeps_passives_oaa", "abilities/boss/dire_tower_boss/radiant_creeps_passives_oaa.lua", LUA_MODIFIER_MOTION_NONE)

function radiant_creeps_passives_oaa:GetIntrinsicModifierName()
  return "modifier_radiant_creeps_passives_oaa"
end

function radiant_creeps_passives_oaa:IsStealable()
  return false
end

function radiant_creeps_passives_oaa:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_radiant_creeps_passives_oaa = class(ModifierBaseClass)

function modifier_radiant_creeps_passives_oaa:IsHidden()
  return true
end

function modifier_radiant_creeps_passives_oaa:IsDebuff()
  return false
end

function modifier_radiant_creeps_passives_oaa:IsPurgable()
  return false
end

function modifier_radiant_creeps_passives_oaa:OnCreated()
  local parent = self:GetParent()
  local origin = parent:GetAbsOrigin()
  local enemies = FindUnitsInRadius(
    parent:GetTeamNumber(),
    origin,
    nil,
    FIND_UNITS_EVERYWHERE,
    DOTA_UNIT_TARGET_TEAM_ENEMY,
    DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
    DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
    FIND_ANY_ORDER,
    false
  )

  -- Find the closest tower or boss
  local closest_boss
  local closest_distance = 20000
  for _, enemy in pairs(enemies) do
    if enemy and not enemy:IsNull() then
      if enemy:IsOAABoss() then
        local distance = (origin - enemy:GetAbsOrigin()):Length2D()
        if distance < closest_distance then
          closest_distance = distance
          closest_boss = enemy
        end
      end
    end
  end

  self.tower = closest_boss

  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_radiant_creeps_passives_oaa:OnIntervalThink()
  local parent = self:GetParent()

  local tower = self.tower

  if not tower or tower:IsNull() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  if not tower:IsAlive() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  if parent:CanEntityBeSeenByMyTeam(tower) then
    ExecuteOrderFromTable({
      UnitIndex = parent:entindex(),
      OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
      TargetIndex = tower:entindex(),
      Queue = false,
    })
  else
    ExecuteOrderFromTable({
      UnitIndex = parent:entindex(),
      OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
      Position = tower:GetAbsOrigin(),
      Queue = false,
    })
  end

  -- Stop thinking after issuing an order
  self:StartIntervalThink(-1)
end

function modifier_radiant_creeps_passives_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
  }
end

if IsServer() then
  function modifier_radiant_creeps_passives_oaa:GetModifierTotal_ConstantBlock(event)
    local ability = self:GetAbility()
    if not ability or ability:IsNull() then
      return 0
    end

    local attacker = event.attacker
    if not attacker or attacker:IsNull() then
      return 0
    end

    if attacker.IsBaseNPC == nil then
      return 0
    end

    if not attacker:IsBaseNPC() then
      return 0
    end

    local dmg_reduction = 80

    -- Block damage from bosses
    if attacker:IsOAABoss() then
      return event.damage * dmg_reduction / 100
    end

    return 0
  end
end
