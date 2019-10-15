mud_golem_shard_split_oaa = class(AbilityBaseClass)

function mud_golem_shard_split_oaa:OnOwnerDied()
  local caster = self:GetCaster() or self:GetOwner()

  -- Don't do anything if caster is affected by Break or if the caster is an illusion
  if caster:PassivesDisabled() or caster:IsIllusion() then
    return
  end

  -- Get all needed values from the caster before its deleted from C++
  local playerID
  local caster_is_a_hero = false
  local caster_team = caster:GetTeam()
  if caster:IsRealHero() then
    playerID = caster:GetPlayerID()
    caster_is_a_hero = true
  else
    playerID = caster:GetPlayerOwnerID()
  end
  local caster_owner = caster:GetOwner()
  local caster_fv = caster:GetForwardVector()
  local caster_location = caster:GetOrigin()
  local caster_dmg_max = caster:GetBaseDamageMax()
  local caster_dmg_min = caster:GetBaseDamageMin()
  local caster_max_hp = caster:GetMaxHealth()
  local caster_gold_max_bounty = caster:GetMaximumGoldBounty()
  local caster_gold_min_bounty = caster:GetMinimumGoldBounty()
  local caster_xp_bounty = caster:GetDeathXP()

  -- Particle
  --local particle = ParticleManager:CreateParticle("particles/creature_splitter/splitter_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

  local unit_name

  if caster_is_a_hero then
    -- Doom, Morphling, Rubick when he casts spell steal on Doom/Morphling
    unit_name = "npc_dota_neutral_mud_golem_split_doom"
  else
    unit_name = "npc_dota_neutral_custom_mud_golem_split"
  end

  local duration = self:GetSpecialValueFor("shard_duration")
  local spawn_radius = self:GetSpecialValueFor("spawn_radius") or 250
  local number_of_shards = self:GetSpecialValueFor("number_of_splits")
  local shard_hp_percentage = self:GetSpecialValueFor("shard_hp_percentage")
  local shard_dmg_percentage = self:GetSpecialValueFor("shard_dmg_percentage")
  local shard_gold_percentage = self:GetSpecialValueFor("shard_gold_percentage")
  local shard_xp_percentage = self:GetSpecialValueFor("shard_xp_percentage")

  -- If the number of shards or shard's hp is 0 or less then don't continue
  if number_of_shards <= 0 or shard_hp_percentage <= 0 then
    return
  end

  for i = 1, number_of_shards do
    local position = caster_location + RandomVector(1):Normalized() * RandomFloat(50, spawn_radius)
    local shard = CreateUnitByName(unit_name, position, true, caster, caster_owner, caster_team)
    if caster_team ~= DOTA_TEAM_NEUTRALS then
      shard:SetControllableByPlayer(playerID, false)
    end
    if caster_is_a_hero then
      shard:SetOwner(caster_owner)
    end

    -- Set the facing of the shards to be the same as the caster
    shard:SetForwardVector(caster_fv)

    -- LIFETIME DURATION
    shard:AddNewModifier(shard, self, "modifier_kill", {duration = duration})

    -- DAMAGE
    shard:SetBaseDamageMax(caster_dmg_max*shard_dmg_percentage/100)
    shard:SetBaseDamageMin(caster_dmg_min*shard_dmg_percentage/100)

    -- HEALTH
    shard:SetBaseMaxHealth(caster_max_hp*shard_hp_percentage/100)
    shard:SetMaxHealth(caster_max_hp*shard_hp_percentage/100)
    shard:SetHealth(caster_max_hp*shard_hp_percentage/100)

    if not caster_is_a_hero then
      -- BOUNTY
      shard:SetMinimumGoldBounty(caster_gold_min_bounty*shard_gold_percentage/100)
      shard:SetMaximumGoldBounty(caster_gold_max_bounty*shard_gold_percentage/100)
      shard:SetDeathXP(caster_xp_bounty*shard_xp_percentage/100)
    end
  end
end
