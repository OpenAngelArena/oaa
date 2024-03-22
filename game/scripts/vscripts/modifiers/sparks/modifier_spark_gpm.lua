modifier_spark_gpm = class(ModifierBaseClass)

function modifier_spark_gpm:OnCreated()
  self:StartIntervalThink(1)
end

modifier_spark_gpm.OnRefresh = modifier_spark_gpm.OnCreated

function modifier_spark_gpm:GetSparkLevel()
  local gameTime = HudTimer:GetGameTime()

  local SPARK_LEVEL_2_TIME = 300                -- 5 minutes
  local SPARK_LEVEL_3_TIME = 600                -- 10 minutes
  local SPARK_LEVEL_4_TIME = 900                -- 15 minutes
  local SPARK_LEVEL_5_TIME = 1500               -- 25 minutes
  local SPARK_LEVEL_6_TIME = 2100               -- 35 minutes
  local SPARK_LEVEL_7_TIME = 2700               -- 45 minutes

  if gameTime > SPARK_LEVEL_7_TIME then
    return 7
  elseif gameTime > SPARK_LEVEL_6_TIME then
    return 6
  elseif gameTime > SPARK_LEVEL_5_TIME then
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

function modifier_spark_gpm:OnIntervalThink()
  if not IsServer() then
    return
  end

  if not HudTimer or not Gold then
    return
  end

  local parent = self:GetParent()

  -- This modifier is not supposed to exist on illusions, Tempest Doubles, Meepo clones or Spirit Bears
  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() then
    self:StartIntervalThink(-1)
    self:Destroy()
    return
  end

  -- Don't give gold during duels
  if not Gold:IsGoldGenActive() then
    return
  end

  local gpm = self:CalculateGPM()
  Gold:ModifyGold(parent:GetPlayerOwnerID(), math.ceil(gpm / 60), true, DOTA_ModifyGold_GameTick)

  --self:SetStackCount(gpm)
end

-- Formula for GPM scaling
function modifier_spark_gpm:CalculateGPM()
  local gpmChart = {500, 1000, 2000, 4000, 6000, 10000, 20000}
  local gpm = gpmChart[self:GetSparkLevel()]
  if HeroSelection and HeroSelection.is10v10 then
    gpm = gpm * 1.5
  end
  return math.floor(gpm)
end

function modifier_spark_gpm:IsHidden()
  return true
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

function modifier_spark_gpm:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

-- function modifier_spark_gpm:DeclareFunctions()
  -- return {
    -- MODIFIER_PROPERTY_TOOLTIP
  -- }
-- end

-- function modifier_spark_gpm:OnTooltip()
  -- return self:GetStackCount()
-- end
