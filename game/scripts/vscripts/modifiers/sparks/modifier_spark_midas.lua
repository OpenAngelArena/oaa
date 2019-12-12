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

function modifier_spark_midas:GetTexture()
  return "custom/spark_midas"
end

function modifier_spark_midas:OnCreated()
  local parent = self:GetParent()

  if IsServer() then
    self:StartIntervalThink(0.5)
    self.stack_count = 0
  end

  -- We count kills made by midas spark and store them on the parent (hero that has a spark),
  -- because he can change the spark at any time
  if parent.midas_spark_kill_counter == nil then
    parent.midas_spark_kill_counter = 0
  end

  -- Midas Spark variables
  self.max_charges = 400
  self.charges_needed_for_kill = 100
  self.bonus_xp = {0, 0, 0, 0, 0}
  self.init_gold = 250
  self.gold_increment = 100
  -- Bonus gold on 6th usage: 750 (approx. at 5 minutes)
  -- Bonus gold on 18th usage: 1950 (approx. at 15 minutes)
  -- After using Midas Spark 17 times, 18th usage will give 1950 gold (250+100*17=1950).
end

if IsServer() then
  function modifier_spark_midas:OnIntervalThink()
    local parent = self:GetParent()

    -- disable everything here for illusions or during duels / pre 0:00
    if parent:IsIllusion() or not Gold:IsGoldGenActive() then
      return
    end

    if self.stack_count < self.max_charges then
      self.stack_count = self.stack_count + 1
      self:SetStackCount(self.stack_count)
    end
  end
end

function modifier_spark_midas:GetSparkLevel()
  local gameTime
  if IsServer() then
    gameTime = HudTimer:GetGameTime()
  else
    gameTime = GameRules:GetDOTATime(false, false)
  end

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

function modifier_spark_midas:DeclareFunctions()
	return {
    MODIFIER_PROPERTY_TOOLTIP,
    MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

if IsServer() then
  function modifier_spark_midas:OnAttackLanded(event)
    local parent = self:GetParent()
    local target = event.target

    if parent ~= event.attacker then
      return
    end

    if parent:IsIllusion() then
      return
    end

    -- To prevent crashes:
    if not target then
      return
    end

    if target:IsNull() then
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

      local spark_level = self:GetSparkLevel()

      -- Gold variables
      local bonus_gold_on_first_kill = self.init_gold
      local counter = parent.midas_spark_kill_counter
      local gold_increment_per_kill = self.gold_increment

      local bonus_gold = bonus_gold_on_first_kill + counter*gold_increment_per_kill
      local bonus_xp = self.bonus_xp[spark_level]

      -- bonus gold
      PlayerResource:ModifyGold(player:GetPlayerID(), bonus_gold, false, DOTA_ModifyGold_CreepKill)
      SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, parent, bonus_gold, player)

      -- bonus experience
      if bonus_xp > 0 then
        parent:AddExperience(bonus_xp, DOTA_ModifyXP_CreepKill, false, true)
      end

      -- particle
      local part = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_leech_seed_damage_glow.vpcf", PATTACH_POINT_FOLLOW, target)
      ParticleManager:ReleaseParticleIndex(part)

      -- sound
      parent:EmitSound("Hero_Treant.LeechSeed.Cast")

      -- kill the target
      target:Kill(nil, parent)

      -- Increment kill counter
      parent.midas_spark_kill_counter = parent.midas_spark_kill_counter + 1
    end
	end
end

function modifier_spark_midas:OnTooltip()
  local parent = self:GetParent()
  local counter = parent.midas_spark_kill_counter -- its not increasing on the client ...

  if not counter then
    counter = 0
  end

  return self.init_gold + counter*self.gold_increment
end
