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

  local caster = self:GetParent()

  -- Don't give gold on illusions, Tempest Doubles, or Meepo clones, or during duels
  if caster:IsIllusion() or caster:IsTempestDouble() or caster:IsClone() or not Gold:IsGoldGenActive() then
    return
  end

  local gpm = self:CalculateGPM()
  Gold:ModifyGold(caster:GetPlayerOwnerID(), math.ceil(gpm / 60), true, DOTA_ModifyGold_GameTick)

  --self:SetStackCount(gpm)
end

-- Formula for GPM scaling
function modifier_spark_gpm:CalculateGPM()
  local gpmChart = {500, 1000, 2000, 4000, 6000, 10000, 20000}
  local gpm = gpmChart[self:GetSparkLevel()]

  return math.floor(gpm)
end

function modifier_spark_gpm:IsHidden()
  return not IsInToolsMode()
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
