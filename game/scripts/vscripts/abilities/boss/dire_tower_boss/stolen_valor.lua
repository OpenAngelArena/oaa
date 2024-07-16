dire_tower_boss_creeps_stolen_valor = class(AbilityBaseClass)

LinkLuaModifier("modifier_dire_tower_boss_creeps_stolen_valor", "abilities/boss/dire_tower_boss/stolen_valor.lua", LUA_MODIFIER_MOTION_NONE)

function dire_tower_boss_creeps_stolen_valor:GetIntrinsicModifierName()
  return "modifier_dire_tower_boss_creeps_stolen_valor"
end

function dire_tower_boss_creeps_stolen_valor:IsStealable()
  return false
end

function dire_tower_boss_creeps_stolen_valor:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_dire_tower_boss_creeps_stolen_valor = class(ModifierBaseClass)

function modifier_dire_tower_boss_creeps_stolen_valor:IsHidden()
  return true
end

function modifier_dire_tower_boss_creeps_stolen_valor:IsDebuff()
  return false
end

function modifier_dire_tower_boss_creeps_stolen_valor:IsPurgable()
  return false
end

function modifier_dire_tower_boss_creeps_stolen_valor:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_dire_tower_boss_creeps_stolen_valor:OnDeath(event)
    local parent = self:GetParent() -- Get the unit that has this modifier attached

    if event.unit ~= parent then return end

    local ability = self:GetAbility()
    local summon_duration = ability:GetSpecialValueFor("summon_duration")

    local attacker = event.attacker
    local vSpawnPoint = parent:GetAbsOrigin()

    -- Sound
    attacker:EmitSound("Roshan.Bash")

    local unitName = parent:GetUnitName()
    if string.find(unitName, "npc_dota_creature_melee") then
      local hMelee = CreateUnitByName( "npc_dota_creature_melee_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
      if hMelee then
        hMelee:AddNewModifier(attacker, ability, "modifier_kill", {duration = summon_duration})
        hMelee:AddNewModifier(attacker, ability, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hMelee:AddNewModifier(attacker, ability, "modifier_phased", {duration = FrameTime()})
        hMelee:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
        -- TODO: -- order them to attack the tower boss
        -- if attacker.zone then
          -- attacker.zone:AddEnemyToZone( hMelee )
        -- end
      end
    elseif string.find(unitName, "npc_dota_creature_ranged") then
      local hRanged = CreateUnitByName( "npc_dota_creature_ranged_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
      if hRanged then
        hRanged:AddNewModifier(attacker, ability, "modifier_kill", {duration = summon_duration})
        hRanged:AddNewModifier(attacker, ability, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hRanged:AddNewModifier(attacker, ability, "modifier_phased", {duration = FrameTime()})
        hRanged:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
        -- if attacker.zone then
          -- attacker.zone:AddEnemyToZone( hRanged )
        -- end
      end
    elseif string.find(unitName, "npc_dota_creature_siege") then
      local hSiege = CreateUnitByName( "npc_dota_creature_siege_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
      if hSiege then
        hSiege:AddNewModifier(attacker, ability, "modifier_kill", {duration = summon_duration})
        hSiege:AddNewModifier(attacker, ability, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
        hSiege:AddNewModifier(attacker, ability, "modifier_phased", {duration = FrameTime()})
        hSiege:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
        -- if attacker.zone then
          -- attacker.zone:AddEnemyToZone( hSiege )
        -- end
      end
    else
      print("Unknown unit type.")
    end
  end
end
