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

  if game_time <= 12*60 then
    self.rewards = {
      "kobold",
      "flask",
      "enchanted_mango",
      "bottle",
    }
  elseif game_time > 12*60 and game_time <= 24*60 then
    self.rewards = {
      "kobold_soldier",
      "enchanted_mango",
      "burst_elixir",
      "bottle",
    }
  elseif game_time > 24*60 and game_time <= 36*60 then
    self.rewards = {
      "kobold_commander",
      "burst_elixir",
      "hybrid_elixir",
    }
  elseif game_time > 36*60 and game_time <= 46*60 then
    self.rewards = {
      "ghost",
      "burst_elixir",
      "hybrid_elixir",
    }
  elseif game_time > 46*60 then
    self.rewards = {
      "prowler",
      "burst_elixir",
      "hybrid_elixir",
      "sustain_elixir",
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

  random_int = RandomInt(1, #self.rewards)

  local random_reward = self.rewards[random_int]

  if random_reward == "flask" then
    self:DigOutItem("item_flask", position)
  elseif random_reward == "enchanted_mango" then
    self:DigOutItem("item_enchanted_mango", position)
  elseif random_reward == "bottle" then
    self:DigOutItem("item_infinite_bottle", position)
  elseif random_reward == "kobold" then
    CreateUnitByName("npc_dota_neutral_kobold", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
  elseif random_reward == "kobold_soldier" then
    CreateUnitByName("npc_dota_neutral_custom_kobold_soldier", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
  elseif random_reward == "kobold_commander" then
    CreateUnitByName("npc_dota_neutral_custom_kobold_foreman", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
  elseif random_reward == "ghost" then
    CreateUnitByName("npc_dota_neutral_custom_ghost", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
  elseif random_reward == "prowler" then
    CreateUnitByName("npc_dota_neutral_prowler_shaman", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
  elseif random_reward == "burst_elixir" then
    self:DigOutItem("item_elixier_burst", position)
  elseif random_reward == "hybrid_elixir" then
    self:DigOutItem("item_elixier_hybrid", position)
  elseif random_reward == "sustain_elixir" then
    self:DigOutItem("item_elixier_sustain", position)
  else
    -- This is not supposed to happen but whatever
    self:DigOutItem("item_tpscroll", position)
  end
end

function item_trusty_shovel_oaa:DigOutItem(item_name, position)
  local item = CreateItem(item_name, nil, nil)
  item:SetSellable(false)
  item:SetShareability(ITEM_FULLY_SHAREABLE)
  item:SetStacksWithOtherOwners(true)
  CreateItemOnPositionSync(position, item)
end

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

function modifier_item_trusty_shovel_oaa_passive:OnRefresh()
  local ability = self:GetAbility()
  if ability and not ability:IsNull() then
    self.hp = ability:GetSpecialValueFor("bonus_health")
  end
end

function modifier_item_trusty_shovel_oaa_passive:DeclareFunctions()
  return {
    MODIFIER_PROPERTY_HEALTH_BONUS,
  }
end

function modifier_item_trusty_shovel_oaa_passive:GetModifierHealthBonus()
  return self.hp or self:GetAbility():GetSpecialValueFor("bonus_health")
end
