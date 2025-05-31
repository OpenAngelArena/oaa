
modifier_rich_man_oaa = class(ModifierBaseClass)

function modifier_rich_man_oaa:IsHidden()
  return false
end

function modifier_rich_man_oaa:IsDebuff()
  return false
end

function modifier_rich_man_oaa:IsPurgable()
  return false
end

function modifier_rich_man_oaa:RemoveOnDeath()
  return false
end

function modifier_rich_man_oaa:OnCreated()
  if not IsServer() then
    return
  end

  self:StartIntervalThink(1)
end

function modifier_rich_man_oaa:GetGoldPerSecond()
  local creepPower = CreepPower:GetBasePowerForMinute(GameRules:GetGameTime() / 60)

  -- nice
  return creepPower[6] * 6.9 * 60
end

function modifier_rich_man_oaa:OnIntervalThink()
  local parent = self:GetParent()
  local player = parent:GetPlayerOwner()
  local interval = 10
  local goldPerMinute = self:GetGoldPerSecond()
  Gold:ModifyGold(player:GetPlayerID(), goldPerMinute * interval / 60 , false, DOTA_ModifyGold_CreepKill)

  self:SetStackCount(goldPerMinute)

  self:StartIntervalThink(interval)
end

function modifier_rich_man_oaa:GetTexture()
  return "alchemist_goblins_greed"
end

function modifier_rich_man_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end

if IsServer() then
  function modifier_rich_man_oaa:OnDeath(event)
    local parent = self:GetParent()
    local killer = event.attacker
    local dead = event.unit

    -- Check for existence of GetUnitName method to determine if dead unit isn't something weird (an item, rune etc.)
    if dead.GetUnitName == nil then
      return
    end

    -- Don't continue if the killer doesn't exist
    if not killer or killer:IsNull() then
      return
    end

    -- Don't continue if the killer doesn't belong to the parent
    if UnitVarToPlayerID(killer) ~= UnitVarToPlayerID(parent) then
      return
    end

    local player = parent:GetPlayerOwner()
    local gold_per_kill = 25
    if dead:IsRealHero() and not dead:IsTempestDouble() and not dead:IsClone() and not dead:IsSpiritBearOAA() then
      gold_per_kill = 100
    end

    Gold:AddGoldWithMessage(player:GetAssignedHero(), gold_per_kill)
  end
end

function modifier_rich_man_oaa:OnTooltip()
  return self:GetStackCount()
end
