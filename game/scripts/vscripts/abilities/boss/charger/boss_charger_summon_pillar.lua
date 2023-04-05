LinkLuaModifier("modifier_charger_pillar_passive", "abilities/boss/charger/boss_charger_summon_pillar.lua", LUA_MODIFIER_MOTION_NONE)

boss_charger_summon_pillar = class(AbilityBaseClass)

function boss_charger_summon_pillar:OnSpellStart()
  local cursorPosition = self:GetCursorPosition()
  local caster = self:GetCaster()

  local tower = CreateUnitByName("npc_dota_boss_charger_pillar", cursorPosition, true, caster, caster:GetOwner(), caster:GetTeam())

  tower:AddNewModifier(caster, self, "modifier_charger_pillar_passive", {})

  if caster.GetPlayerID then
    tower:SetControllableByPlayer(caster:GetPlayerID(), false)
  end
  tower:SetOwner(caster)

  caster:OnDeath(function()
    if IsValidEntity(tower) then
      tower:Destroy()
    end
  end)
end

---------------------------------------------------------------------------------------------------

modifier_charger_pillar_passive = class(ModifierBaseClass)

function modifier_charger_pillar_passive:IsHidden()
  return true
end

function modifier_charger_pillar_passive:IsDebuff()
  return false
end

function modifier_charger_pillar_passive:IsPurgable()
  return false
end

function modifier_charger_pillar_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
    MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
  }
end

function modifier_charger_pillar_passive:GetAbsoluteNoDamagePhysical()
  return 1
end

function modifier_charger_pillar_passive:GetAbsoluteNoDamageMagical()
  return 1
end

function modifier_charger_pillar_passive:GetAbsoluteNoDamagePure()
  return 1
end

function modifier_charger_pillar_passive:CheckState()
  return {
    [MODIFIER_STATE_INVULNERABLE] = true,
    [MODIFIER_STATE_UNSELECTABLE] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
    [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
    [MODIFIER_STATE_NO_HEALTH_BAR] = true,
    [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    [MODIFIER_STATE_OUT_OF_GAME] = true,
    --[MODIFIER_STATE_NO_TEAM_MOVE_TO] = true,
    --[MODIFIER_STATE_NO_TEAM_SELECT] = true,
    [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
    [MODIFIER_STATE_ATTACK_IMMUNE] = true,
    [MODIFIER_STATE_MAGIC_IMMUNE] = true,
  }
end
