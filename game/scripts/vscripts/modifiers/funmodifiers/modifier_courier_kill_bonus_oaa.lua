LinkLuaModifier("modifier_courier_kill_bonus_all_stats_oaa", "modifiers/funmodifiers/modifier_courier_kill_bonus_oaa.lua", LUA_MODIFIER_MOTION_NONE)

modifier_courier_kill_bonus_oaa = class(ModifierBaseClass)

function modifier_courier_kill_bonus_oaa:IsHidden()
  return false
end

function modifier_courier_kill_bonus_oaa:IsDebuff()
  return false
end

function modifier_courier_kill_bonus_oaa:IsPurgable()
  return false
end

function modifier_courier_kill_bonus_oaa:RemoveOnDeath()
  local parent = self:GetParent()
  if parent:IsRealHero() and not parent:IsOAABoss() then
    return false
  end
  return true
end

function modifier_courier_kill_bonus_oaa:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

if IsServer() then
  function modifier_courier_kill_bonus_oaa:OnDeath(event)
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

    -- Don't continue if the dead unit isn't a courier
    if not dead:IsCourier() then
      return
    end

    parent:AddNewModifier(parent, nil, "modifier_courier_kill_bonus_all_stats_oaa", {})
  end
end

function modifier_courier_kill_bonus_oaa:GetTexture()
  return "item_courier"
end

---------------------------------------------------------------------------------------------------

modifier_courier_kill_bonus_all_stats_oaa = class(ModifierBaseClass)

function modifier_courier_kill_bonus_all_stats_oaa:IsHidden()
  return false
end

function modifier_courier_kill_bonus_all_stats_oaa:IsDebuff()
  return false
end

function modifier_courier_kill_bonus_all_stats_oaa:IsPurgable()
  return false
end

function modifier_courier_kill_bonus_all_stats_oaa:RemoveOnDeath()
  return false
end

function modifier_courier_kill_bonus_all_stats_oaa:OnCreated()
  self.stats = 15

  if IsServer() then
    self:SetStackCount(1)
  end
end

function modifier_courier_kill_bonus_all_stats_oaa:OnRefresh()
  if IsServer() and self:GetStackCount() then
    self:IncrementStackCount()
  end
end

function modifier_courier_kill_bonus_all_stats_oaa:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
    MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
  }
end

function modifier_courier_kill_bonus_all_stats_oaa:GetModifierBonusStats_Agility()
  return self.stats * self:GetStackCount()
end

function modifier_courier_kill_bonus_all_stats_oaa:GetModifierBonusStats_Intellect()
  return self.stats * self:GetStackCount()
end

function modifier_courier_kill_bonus_all_stats_oaa:GetModifierBonusStats_Strength()
  return self.stats * self:GetStackCount()
end

function modifier_courier_kill_bonus_all_stats_oaa:GetTexture()
  return "item_courier"
end
