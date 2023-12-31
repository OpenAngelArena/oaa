
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
  local parent = self:GetParent()
  local player = parent:GetPlayerOwner()

  self:StartIntervalThink(1)
end

function modifier_rich_man_oaa:GetGoldPerSecond()
  local creepPower = CreepPower:GetBasePowerForMinute(GameRules:GetGameTime() / 60)

  -- nice
  return creepPower[6] * 6.9 * 60
end

function modifier_rich_man_oaa:OnIntervalThink()
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local player = parent:GetPlayerOwner()
  local interval = 10
  local goldPerMinute = self:GetGoldPerSecond(interval)
  Gold:ModifyGold(player:GetPlayerID(), goldPerMinute * interval / 60 , false, DOTA_ModifyGold_CreepKill)

  self:SetStackCount(goldPerMinute)

  self:StartIntervalThink(10)
end

function modifier_rich_man_oaa:GetTexture()
  return "alchemist_goblins_greed"
end

function modifier_rich_man_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN,
    MODIFIER_PROPERTY_TOOLTIP,
  }
end


function modifier_rich_man_oaa:OnRespawn(event)
  if not IsServer() then
    return
  end
  local parent = self:GetParent()
  local player = parent:GetPlayerOwner()

  -- fuck it
  Gold:AddGoldWithMessage(player:GetAssignedHero(), 1000 + GameRules:GetGameTime() * 2)
end

function modifier_rich_man_oaa:OnTooltip()
  return self:GetStackCount()
end
