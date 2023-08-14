LinkLuaModifier("modifier_item_trusty_shovel_oaa_passive", "items/neutral/trusty_shovel.lua", LUA_MODIFIER_MOTION_NONE)

item_trusty_shovel_oaa = class(ItemBaseClass)

function item_trusty_shovel_oaa:GetIntrinsicModifierName()
  return "modifier_item_trusty_shovel_oaa_passive"
end

function item_trusty_shovel_oaa:OnSpellStart()
  local caster = self:GetCaster()
  local position = self:GetCursorPosition()

  local game_time = 0 -- game time in seconds
  if HudTimer then
    game_time = HudTimer:GetGameTime()
  else
    game_time = GameRules:GetGameTime()
  end

  -- Non bounty rune rewards
  if self.rewards == nil then
    self.rewards = {}
  end

  if game_time <= 10*60 then
    self.rewards = {
      "kobold_soldier",
      "flask",
      "enchanted_mango",
      "bottle",
      "water",
      "famango",
    }
  elseif game_time > 10*60 and game_time <= 20*60 then
    self.rewards = {
      "kobold_commander",
      "burst_elixir",
      "famango",
    }
  elseif game_time > 20*60 and game_time <= 30*60 then
    self.rewards = {
      "harpy",
      "burst_elixir",
      "sustain_elixir",
      "great_famango",
    }
  elseif game_time > 30*60 and game_time <= 40*60 then
    self.rewards = {
      "ghost",
      "burst_elixir",
      "sustain_elixir",
      "hybrid_elixir",
      "great_famango",
    }
  elseif game_time > 40*60 then
    self.rewards = {
      "prowler",
      "burst_elixir",
      "hybrid_elixir",
      "sustain_elixir",
      "greater_famango",
      "cheese",
    }
  end

  -- Particle
  self.pfx = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_dig.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(self.pfx, 0, position)

  -- Sound
  caster:EmitSound("SeasonalConsumable.TI9.Shovel.Dig")
end

function item_trusty_shovel_oaa:OnChannelFinish(bInterrupted)
  local caster = self:GetCaster()
  local position = self:GetCursorPosition()

  -- Remove particle, doesn't matter if channel is successful or not
  if self.pfx then
    ParticleManager:DestroyParticle(self.pfx, false)
    ParticleManager:ReleaseParticleIndex(self.pfx)
  end

  -- Stop sound, doesn't matter if channel is successful or not
  caster:StopSound("SeasonalConsumable.TI9.Shovel.Dig")

  -- If channel was cancelled or interrupted, don't continue
  if bInterrupted then
    return
  end

  -- Reveal the reward particle
  local particle = ParticleManager:CreateParticle("particles/econ/events/ti9/shovel_revealed_generic.vpcf", PATTACH_WORLDORIGIN, caster)
  ParticleManager:SetParticleControl(particle, 0, position)
  ParticleManager:ReleaseParticleIndex(particle)

  local bounty_rune_chance = self:GetSpecialValueFor("bounty_rune_drop_chance")
  local random_int = RandomInt(1, 100)
  if random_int <= bounty_rune_chance then
    CreateRune(position, DOTA_RUNE_BOUNTY)
    return
  end

  local rewards = {}
  for _, v in pairs(self.rewards) do
    if v and v ~= self.last_reward then
      table.insert(rewards, v)
    end
  end

  local function GetRandomTableElement(t)
    -- iterate over whole table to get all keys
    local keyset = {}
    for k in pairs(t) do
      table.insert(keyset, k)
    end
    -- now you can reliably return a random key
    return t[keyset[RandomInt(1, #keyset)]]
  end

  local random_reward = GetRandomTableElement(rewards)

  if random_reward == "flask" then
    self:DigOutItem("item_flask", position)
  elseif random_reward == "enchanted_mango" then
    self:DigOutItem("item_enchanted_mango", position)
  elseif random_reward == "bottle" then
    self:DigOutItem("item_infinite_bottle", position)
  elseif random_reward == "famango" then
    self:DigOutItem("item_famango", position)
  elseif random_reward == "great_famango" then
    self:DigOutItem("item_great_famango", position)
  elseif random_reward == "greater_famango" then
    self:DigOutItem("item_greater_famango", position)
  elseif random_reward == "cheese" then
    self:DigOutItem("item_cheese", position)
  elseif random_reward == "kobold" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_custom_kobold", position, caster)
  elseif random_reward == "kobold_soldier" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_custom_kobold_soldier", position, caster)
  elseif random_reward == "kobold_commander" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_custom_kobold_foreman", position, caster)
  elseif random_reward == "harpy" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_custom_harpy_storm", position, caster)
  elseif random_reward == "ghost" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_custom_ghost", position, caster)
  elseif random_reward == "prowler" then
    self:SpawnNeutralUnitAtPosition("npc_dota_neutral_prowler_shaman", position, caster)
  elseif random_reward == "burst_elixir" then
    self:DigOutItem("item_elixier_burst", position)
  elseif random_reward == "hybrid_elixir" then
    self:DigOutItem("item_elixier_hybrid", position)
  elseif random_reward == "sustain_elixir" then
    self:DigOutItem("item_elixier_sustain", position)
  elseif random_reward == "water" then
    CreateRune(position, DOTA_RUNE_WATER)
  else
    -- This is not supposed to happen but whatever
    self:DigOutItem("item_tpscroll", position)
  end

  self.last_reward = random_reward
end

function item_trusty_shovel_oaa:DigOutItem(item_name, location)
  local item = CreateItem(item_name, nil, nil)
  item:SetSellable(false)
  item:SetShareability(ITEM_FULLY_SHAREABLE)
  item:SetStacksWithOtherOwners(true)
  CreateItemOnPositionSync(location, item)
end

function item_trusty_shovel_oaa:SpawnNeutralUnitAtPosition(unit_name, location, caster)
  local unit = CreateUnitByName(unit_name, location, true, caster, caster:GetOwner(), caster:GetTeam())
  local game_time = 0 -- game time in seconds
  if HudTimer then
    game_time = HudTimer:GetGameTime()
  else
    game_time = GameRules:GetGameTime()
  end
  local minute = math.ceil(game_time/60)
  if CreepCamps then
    local unit_properties = CreepCamps:GetCreepProperties(unit)
    local new_properties = CreepCamps:AdjustCreepPropertiesByPowerLevel(unit_properties, minute)
    new_properties = CreepCamps:UpgradeCreepProperties(new_properties, unit_properties, 1/12) -- it's intentionally like this because the creep is controllable
    CreepCamps:SetCreepPropertiesOnHandle(unit, new_properties)
  end
  unit:SetControllableByPlayer(caster:GetPlayerID(), false)
  unit:SetOwner(caster)
end

-- function item_trusty_shovel_oaa:GetCreepProperties(creepHandle)
  -- local creepProperties = {}

  -- creepProperties[1] = creepHandle:GetMaxHealth()
  -- creepProperties[2] = (creepHandle:GetBaseDamageMin() + creepHandle:GetBaseDamageMax()) / 2
  -- creepProperties[3] = creepHandle:GetPhysicalArmorBaseValue()
  -- creepProperties[4] = (creepHandle:GetMinimumGoldBounty() + creepHandle:GetMaximumGoldBounty()) / 2
  -- creepProperties[5] = creepHandle:GetDeathXP()

  -- return creepProperties
-- end

-- function item_trusty_shovel_oaa:UpgradeCreepProperties(propertiesOne, propertiesTwo, scale)
  -- local upgradedCreepProperties = {}

  -- -- Never downgrade stats
  -- upgradedCreepProperties[1] = math.max(propertiesOne[1], propertiesTwo[1] * scale)
  -- upgradedCreepProperties[2] = math.max(propertiesOne[2], propertiesTwo[2] * scale)
  -- upgradedCreepProperties[3] = math.max(propertiesOne[3], propertiesTwo[3] * scale)

  -- -- Sum up bounties
  -- upgradedCreepProperties[4] = propertiesOne[4] + propertiesTwo[4] * scale
  -- upgradedCreepProperties[5] = propertiesOne[5] + propertiesTwo[5] * scale

  -- return upgradedCreepProperties
-- end

-- function item_trusty_shovel_oaa:SetCreepPropertiesOnHandle(creepHandle, creepProperties)

  -- --HEALTH
  -- local intendedMaxHealth = creepProperties[1]
  -- local currentHealthPercent = creepHandle:GetHealth() / creepHandle:GetMaxHealth()
  -- local missingHealth = creepHandle:GetMaxHealth() - creepHandle:GetHealth()
  -- local targetHealth = math.max(1, currentHealthPercent * intendedMaxHealth, intendedMaxHealth - missingHealth)

  -- creepHandle:SetBaseMaxHealth(math.ceil(intendedMaxHealth))
  -- creepHandle:SetMaxHealth(math.ceil(intendedMaxHealth))
  -- creepHandle:SetHealth(math.ceil(targetHealth))

  -- --DAMAGE
  -- creepHandle:SetBaseDamageMin(math.ceil(creepProperties[2]))
  -- creepHandle:SetBaseDamageMax(math.ceil(creepProperties[2]))

  -- --ARMOR
  -- creepHandle:SetPhysicalArmorBaseValue(creepProperties[3])

  -- --GOLD BOUNTY
  -- creepHandle:SetMinimumGoldBounty(math.ceil(creepProperties[4]))
  -- creepHandle:SetMaximumGoldBounty(math.ceil(creepProperties[4]))

  -- --EXP BOUNTY
  -- creepHandle:SetDeathXP(math.floor(creepProperties[5]))
-- end

---------------------------------------------------------------------------------------------------

modifier_item_trusty_shovel_oaa_passive = class(ModifierBaseClass)

function modifier_item_trusty_shovel_oaa_passive:IsHidden()
  return true
end

function modifier_item_trusty_shovel_oaa_passive:IsDebuff()
  return false
end

function modifier_item_trusty_shovel_oaa_passive:IsPurgable()
  return false
end

function modifier_item_trusty_shovel_oaa_passive:OnCreated()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
  end
end

modifier_item_trusty_shovel_oaa_passive.OnRefresh = modifier_item_trusty_shovel_oaa_passive.OnCreated

function modifier_item_trusty_shovel_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
  }
end

function modifier_item_trusty_shovel_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end
