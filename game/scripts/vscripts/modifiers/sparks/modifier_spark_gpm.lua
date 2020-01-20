modifier_spark_gpm = class(ModifierBaseClass)

function modifier_spark_gpm:OnCreated()
  self:StartIntervalThink(1)
end

modifier_spark_gpm.OnRefresh = modifier_spark_gpm.OnCreated

function modifier_spark_gpm:GetSparkLevel()
  local gameTime = HudTimer:GetGameTime()

  if not SPARK_LEVEL_1_TIME then
    return 1
  end

  if gameTime > SPARK_LEVEL_5_TIME then
    return 5
  elseif gameTime > SPARK_LEVEL_4_TIME then
    return 4
  elseif gameTime > SPARK_LEVEL_3_TIME then
    return 3
  elseif gameTime > SPARK_LEVEL_2_TIME then
    return 2
  end

  return 1
end

function modifier_spark_gpm:GetTexture()
  return "custom/spark_gpm"
end

if IsServer() then
  function modifier_spark_gpm:OnIntervalThink()
    if not PlayerResource then
      -- sometimes for no reason the player resource isn't there, usually only at the start of games in tools mode
      return
    end
    local caster = self:GetParent()
    local gpmChart = {500, 1800, 3200, 5500, 10000}
    local gpm = gpmChart[self:GetSparkLevel()]
    -- Don't give gold on illusions, Tempest Doubles, or Meepo clones, or during duels
    if caster:IsIllusion() or caster:IsTempestDouble() or caster:IsClone() or not Gold:IsGoldGenActive() then
      return
    end
    Gold:ModifyGold(caster:GetPlayerOwnerID(), gpm / 60, true, DOTA_ModifyGold_GameTick)

    self:SetStackCount(gpm)
  end
end

function modifier_spark_gpm:IsHidden()
  return false
end

function modifier_spark_gpm:IsDebuff()
  return false
end

function modifier_spark_gpm:IsPurgable()
  return false
end

function modifier_spark_gpm:RemoveOnDeath()
  return false
end

function modifier_spark_gpm:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_TOOLTIP
  }
end

function modifier_spark_gpm:OnTooltip()
  return self:GetStackCount()
end
