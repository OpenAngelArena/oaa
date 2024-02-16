modifier_spark_gold = class(ModifierBaseClass)

function modifier_spark_gold:IsHidden()
  return false
end

function modifier_spark_gold:IsDebuff()
  return false
end

function modifier_spark_gold:IsPurgable()
  return false
end

function modifier_spark_gold:RemoveOnDeath()
  return false
end

function modifier_spark_gold:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_spark_gold:GetTexture()
  return "custom/spark_gpm"
end

function modifier_spark_gold:OnCreated()
  -- Gold percentage bonuses
  self.hero_kill_bonus_gold = 0
  self.bounty_rune_bonus_gold = 0 -- must be > 1 to take effect
  -- Gold flat bonuses
  self.boss_kill_bonus_gold = 0
end

modifier_spark_gold.OnRefresh = modifier_spark_gold.OnCreated

function modifier_spark_gold:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

-- Handles bonus gold from boss kills
function modifier_spark_gold:OnDeath(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local target = event.unit

  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() or not Gold:IsGoldGenActive() then
    return
  end

  if not target then
    return
  end

  -- Check for existence of GetUnitName method to determine if dead entity is a unit or an item
  -- items don't have this method; if the target is an item, don't continue
  if target.GetUnitName == nil then
    return
  end

  -- If the dead entity is not a boss, don't continue
  if not target:IsOAABoss() then
    return
  end

  local boss_tier = target.BossTier or 1

  -- If a boss died near the parent, give the parent extra gold
  local radius = CREEP_BOUNTY_SHARE_RADIUS
  if (parent:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() <= radius then
    local player = parent:GetPlayerOwner()
    local bonus_gold_per_tier = self.boss_kill_bonus_gold
    local bonus_gold = bonus_gold_per_tier * boss_tier

    -- bonus gold
    if Gold and bonus_gold > 0 then
      Gold:ModifyGold(player:GetPlayerID(), bonus_gold, false, DOTA_ModifyGold_CreepKill)
      SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, parent, bonus_gold, player)
    end
  end
end
