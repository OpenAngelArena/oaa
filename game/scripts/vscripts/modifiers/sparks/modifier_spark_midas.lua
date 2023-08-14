modifier_spark_midas = class(ModifierBaseClass)

function modifier_spark_midas:IsHidden()
	return false
end

function modifier_spark_midas:IsDebuff()
	return false
end

function modifier_spark_midas:IsPurgable()
	return false
end

function modifier_spark_midas:RemoveOnDeath()
  return false
end

function modifier_spark_midas:GetAttributes()
  return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_spark_midas:GetTexture()
  return "custom/spark_midas"
end

function modifier_spark_midas:OnCreated()
  if IsServer() then
    self:StartIntervalThink(0.5)
    self.stack_count = 0
  end

  -- Midas Spark variables
  self.max_charges = 400
  self.charges_needed_for_kill = 100
  self.bonus_gold = 0 -- {375, 750, 1500, 3000, 4500, 7500, 15000} -- gpmChart = {500, 1000, 2000, 4000, 6000, 10000, 20000} * 3/4
  self.bonus_xp = 125
  self.passive_bonus_xp = 1/4
end

function modifier_spark_midas:OnIntervalThink()
  if not IsServer() then
    return
  end

  local parent = self:GetParent()

  -- disable everything here for illusions or during duels / pre 0:00
  if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsClone() or parent:IsSpiritBearOAA() or not Gold:IsGoldGenActive() then
    return
  end

  if self.stack_count < self.max_charges then
    self.stack_count = self.stack_count + 1
    self:SetStackCount(self.stack_count)
  end
end

function modifier_spark_midas:GetSparkLevel()
  local gameTime
  if IsServer() then
    gameTime = HudTimer:GetGameTime() - (self.stack_count / 2)
  else
    gameTime = GameRules:GetDOTATime(false, false) - (self:GetStackCount() / 2)
  end

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

function modifier_spark_midas:DeclareFunctions()
	return {
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

if IsServer() then
  function modifier_spark_midas:OnAttackLanded(event)
    local parent = self:GetParent()
    local attacker = event.attacker
    local target = event.target

    -- Check if attacker exists
    if not attacker or attacker:IsNull() then
      return
    end

    if attacker ~= parent then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- Check if attacked unit exists
    if not target or target:IsNull() then
      return
    end

    -- Check for existence of GetUnitName method to determine if target is a unit or an item
    -- items don't have this method; if the target is an item, don't continue
    if target.GetUnitName == nil then
      return
    end

    -- Don't affect buildings and wards
    if target:IsTower() or target:IsBuilding() or target:IsOther() then
      return
    end

    -- Instant kill should work only on neutrals (not bosses)
    -- and never in duels and number of charges is equal or above charges_needed_for_kill trigger naturalize eating
    if target:IsNeutralCreep(true) and Gold:IsGoldGenActive() and self.stack_count >= self.charges_needed_for_kill then
      local player = parent:GetPlayerOwner()

      -- remove charges_needed_for_kill charges
      self.stack_count = self.stack_count - self.charges_needed_for_kill
      self:SetStackCount(self.stack_count)

      local bonus_gold = self.bonus_gold --self.bonus_gold[self:GetSparkLevel()]
      local bonus_xp = self.bonus_xp

      -- bonus gold
      if bonus_gold > 0 then
        Gold:ModifyGold(player:GetPlayerID(), bonus_gold, false, DOTA_ModifyGold_CreepKill)
        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, parent, bonus_gold, player)
      end

      -- bonus experience
      if bonus_xp > 0 then
        local XPBounty = target:GetDeathXP()
        bonus_xp = bonus_xp * XPBounty / 100
        parent:AddExperience(bonus_xp, DOTA_ModifyXP_CreepKill, false, true)
        SendOverheadEventMessage(player, OVERHEAD_ALERT_XP, parent, bonus_xp, player)
      end

      -- particle
      local part = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_leech_seed_damage_glow.vpcf", PATTACH_POINT_FOLLOW, target)
      ParticleManager:ReleaseParticleIndex(part)

      -- sound
      parent:EmitSound("Hero_Treant.LeechSeed.Cast")

      -- kill the target
      target:Kill(nil, parent)
    end
  end
end

function modifier_spark_midas:OnTooltip()
  return self.bonus_xp --self.bonus_gold[self:GetSparkLevel()]
end
