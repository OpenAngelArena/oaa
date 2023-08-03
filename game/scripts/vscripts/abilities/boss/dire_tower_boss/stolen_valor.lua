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
        local unit = self:GetParent() -- Get the unit that has this modifier attached
        local attacker = keys.attacker -- Get the unit that killed the unit
        if attacker:IsPlayer() then
          local hSiege = CreateUnitByName( "npc_dota_creature_siege_wave1_creep", attacker:GetAbsOrigin(), true, attacker, attacker, attacker:GetTeamNumber() )
        else
            local owner = attacker:GetOwner()
            if owner and owner:IsPlayer() then
              local hSiege = CreateUnitByName( "npc_dota_creature_siege_wave1_creep", owner:GetAbsOrigin(), true, owner, owner, owner:GetTeamNumber() )
            end
        end
    end
end




