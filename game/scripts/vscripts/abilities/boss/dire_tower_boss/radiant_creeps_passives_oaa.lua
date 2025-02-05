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
  if IsServer() then
    self:StartIntervalThink(0.1)
  end
end

function modifier_radiant_creeps_passives_oaa:OnIntervalThink()
  local parent = self:GetParent()
  if not self.tower or self.tower:IsNull() then
    local origin = parent:GetAbsOrigin()
    local enemies = FindUnitsInRadius(
      parent:GetTeamNumber(),
      origin,
      nil,
      FIND_UNITS_EVERYWHERE,
      DOTA_UNIT_TARGET_TEAM_ENEMY,
      DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
      DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
      FIND_CLOSEST,
      false
    )

    -- Find the closest tower
    local closest_tower
    for _, enemy in ipairs(enemies) do
      if enemy and not enemy:IsNull() then
        local enemy_name = enemy:GetUnitName()
        if enemy:IsOAABoss() and enemy_name ~= "npc_dota_boss_grendel" then
          if enemy_name == "npc_dota_creature_dire_tower_boss" then
            closest_tower = enemy
            break
          end
        end
      end
    end

    self.tower = closest_tower
    self.ordered = false

    if not self.tower or self.tower:IsNull() then
      -- Find the closest boss since there are no towers
      local closest_boss
      for _, enemy in ipairs(enemies) do
        if enemy and not enemy:IsNull() then
          local enemy_name = enemy:GetUnitName()
          if enemy:IsOAABoss() and enemy_name ~= "npc_dota_boss_grendel" then
            closest_boss = enemy
            break
          end
        end
      end

      self.tower = closest_boss

      if not self.tower or self.tower:IsNull() then
        return
      end
    end
  end

  if not self.tower:IsAlive() then
    self.tower = nil
    return
  end

  if not self.ordered or parent:IsIdle() then
    if parent:CanEntityBeSeenByMyTeam(self.tower) then
      ExecuteOrderFromTable({
        UnitIndex = parent:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
        TargetIndex = self.tower:entindex(),
        Queue = false,
      })
    else
      ExecuteOrderFromTable({
        UnitIndex = parent:entindex(),
        OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
        Position = self.tower:GetAbsOrigin(),
        Queue = false,
      })
    end
    self.ordered = true
  end
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

    local dmg_reduction = ability:GetSpecialValueFor("dmg_reduction")

    -- Block damage from bosses
    if attacker:IsOAABoss() then
      return event.damage * dmg_reduction / 100
    end

    return 0
  end
end
