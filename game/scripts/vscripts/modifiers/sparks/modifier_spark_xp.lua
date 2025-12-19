modifier_spark_xp = class(ModifierBaseClass)

function modifier_spark_xp:IsHidden()
  return false
end

function modifier_spark_xp:IsDebuff()
  return false
end

function modifier_spark_xp:IsPurgable()
  return false
end

function modifier_spark_xp:RemoveOnDeath()
  return false
end

function modifier_spark_xp:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_spark_xp:GetTexture()
  return "custom/spark_midas"
end

function modifier_spark_xp:OnCreated()
  -- Experience percentage bonuses
  self.hero_kill_bonus_xp = 0
  self.boss_kill_bonus_xp = 0
  self.bounty_rune_bonus_xp = 0 -- must be > 1 to take effect
  self.passive_bonus_xp = 0
end

modifier_spark_xp.OnRefresh = modifier_spark_xp.OnCreated

function modifier_spark_xp:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_DEATH,
  }
end

-- Handles bonus experience from boss kills
function modifier_spark_xp:OnDeath(event)
  if not IsServer() then
    return
  end

  local parent = self:GetParent()
  local target = event.unit

  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
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

  local XPBounty = target:GetDeathXP()

  -- If a boss died near the parent, give the parent extra experience
  local radius = HERO_KILL_XP_RADIUS or CREEP_BOUNTY_SHARE_RADIUS
  if (parent:GetAbsOrigin() - target:GetAbsOrigin()):Length2D() <= radius then
    local player = parent:GetPlayerOwner()
    local bonus_xp_mult = self.boss_kill_bonus_xp
    local bonus_xp = bonus_xp_mult * XPBounty

    -- bonus experience
    if bonus_xp > 0 then
      parent:AddExperience(bonus_xp, DOTA_ModifyXP_CreepKill, false, true)
      SendOverheadEventMessage(player, OVERHEAD_ALERT_XP, parent, bonus_xp, nil)
    end
  end
end
