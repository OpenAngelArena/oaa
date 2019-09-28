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
  return "custom/travel_origin"
end

function modifier_spark_midas:OnCreated()
  if IsServer() then
    self:StartIntervalThink(1)
    self.stack_count = 0
    -- Midas Spark variables
    self.max_charges = 400
    self.charges_needed_for_kill = 100
    self.bonus_gold = {400, 1500, 2500, 4500, 7500} -- max allowed values: {800, 3000, 5000, 9000, 15000} - which is slightly less than gpm spark
    self.bonus_xp = {0, 0, 0, 0, 0}
  end
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

function modifier_spark_midas:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
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

      -- remove 100 charges
      self.stack_count = self.stack_count - self.charges_needed_for_kill
      self:SetStackCount(self.stack_count)

      local function getSparkLevel()
        local gameTime = GameRules:GetGameTime()

        if gameTime > INITIAL_CAPTURE_POINT_DELAY + 3*CAPTURE_INTERVAL then
          -- after 4th cap
          return 5
        elseif gameTime > INITIAL_CAPTURE_POINT_DELAY + 2*CAPTURE_INTERVAL then
          -- after third cap
          return 4
        elseif gameTime > INITIAL_CAPTURE_POINT_DELAY + CAPTURE_INTERVAL then
          -- after second cap
          return 3
        elseif gameTime > INITIAL_CAPTURE_POINT_DELAY then
          -- after first cap
          return 2
        end

        return 1
      end

      local bonus_gold = self.bonus_gold[getSparkLevel()]
      local bonus_xp = self.bonus_xp[getSparkLevel()]

      -- bonus gold
      PlayerResource:ModifyGold(player:GetPlayerID(), bonus_gold, false, DOTA_ModifyGold_CreepKill)
      SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, parent, bonus_gold, player)

      -- bonus exp
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
    end
	end
end


