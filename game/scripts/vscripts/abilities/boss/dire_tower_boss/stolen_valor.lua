stolen_valor = class(AbilityBaseClass)

LinkLuaModifier("modifier_stolen_valor", "abilities/boss/dire_tower_boss/stolen_valor.lua", LUA_MODIFIER_MOTION_NONE)

function stolen_valor:GetIntrinsicModifierName()
  return "modifier_stolen_valor"
end

function stolen_valor:ShouldUseResources()
  return true
end

function stolen_valor:IsStealable()
  return false
end

function stolen_valor:ProcMagicStick()
  return false
end

---------------------------------------------------------------------------------------------------

modifier_stolen_valor = class(ModifierBaseClass)

function modifier_stolen_valor:IsHidden()
  return true
end

function modifier_stolen_valor:IsDebuff()
  return false
end

function modifier_stolen_valor:IsPurgable()
  return false
end

function modifier_stolen_valor:RemoveOnDeath()
  return true
end

function modifier_stolen_valor:OnCreated()
  local parent = self:GetParent()
end

function modifier_stolen_valor:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
    function modifier_stolen_valor:OnDeath(keys)
        if keys.unit~=self:GetParent() then return end

        local unit = self:GetParent() -- Get the unit that has this modifier attached
        if unit:HasModifier("modifier_stolen_valor") then
          local summon_duration = 35
          --OBBNOTE: how to implement?
          local attacker = keys.attacker
          local vSpawnPoint = unit:GetAbsOrigin()
          attacker:EmitSound("Roshan.Bash")


          local unitName = unit:GetUnitName()
          if string.find(unitName, "npc_dota_creature_melee") == 1 then
              local hMelee = CreateUnitByName( "npc_dota_creature_melee_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
              if hMelee then
                hMelee:AddNewModifier(attacker, self, "modifier_kill", {duration = summon_duration})
                hMelee:AddNewModifier(attacker, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
                hMelee:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
                if attacker.zone then
                  attacker.zone:AddEnemyToZone( hMelee )
                end
              end
          elseif string.find(unitName, "npc_dota_creature_ranged") == 1 then
              local hRanged = CreateUnitByName( "npc_dota_creature_ranged_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
              if hRanged then
                hRanged:AddNewModifier(attacker, self, "modifier_kill", {duration = summon_duration})
                hRanged:AddNewModifier(attacker, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
                hRanged:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
                if attacker.zone then
                  attacker.zone:AddEnemyToZone( hRanged )
                end
              end
          elseif string.find(unitName, "npc_dota_creature_siege") == 1 then
              local hSiege = CreateUnitByName( "npc_dota_creature_siege_stolen_creep" , vSpawnPoint, true, attacker, attacker, attacker:GetTeamNumber() )
              if hSiege then
                hSiege:AddNewModifier(attacker, self, "modifier_kill", {duration = summon_duration})
                hSiege:AddNewModifier(attacker, self, "modifier_generic_dead_tracker_oaa", {duration = summon_duration + MANUAL_GARBAGE_CLEANING_TIME})
                hSiege:SetInitialGoalEntity( attacker:GetInitialGoalEntity() )
                if attacker.zone then
                  attacker.zone:AddEnemyToZone( hSiege )
                end
              end
          else
              print("Unknown unit type.")
          end
        end
    end
end




