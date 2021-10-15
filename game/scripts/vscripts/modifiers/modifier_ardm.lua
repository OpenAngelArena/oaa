LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

modifier_ardm = class(ModifierBaseClass)

function modifier_ardm:ReplaceHero(old_hero, new_hero_name)
  if not IsServer() then
    return
  end
  Debug:EnableDebugging()
  local playerID = old_hero:GetPlayerID()
  local gold_1 = Gold:GetGold(playerID)
  local gold_2 = PlayerResource:GetGold(playerID)
  DebugPrint("Old hero Gold v1: "..tostring(gold_1))
  DebugPrint("Old hero Gold v2: "..tostring(gold_2))
  local hero_xp_1 = old_hero:GetCurrentXP()
  --local hero_xp_2 = PlayerResource:GetTotalEarnedXP(playerID)
  --DebugPrint("Old hero XP v1: "..tostring(hero_xp_1))
  --DebugPrint("Old hero XP v2: "..tostring(hero_xp_2))
  local hero_lvl = old_hero:GetLevel()
  DebugPrint('Old hero was level ' .. hero_lvl)

  -- Calculate spent ability/skill points
  --local spent_ability_points = 0
  --for ability_index = 0, old_hero:GetAbilityCount() - 1 do
    --local ability = old_hero:GetAbilityByIndex(ability_index)
    --if ability then
      --spent_ability_points = spent_ability_points + ability:GetLevel()
    --end
  --end

  local items = {}
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = old_hero:GetItemInSlot(i)
    local item_name
    local charges
    local purchaser
    local cooldown
    if item then
      if not item:IsNeutralDrop() then
        item_name = item:GetName()
        purchaser = item:GetPurchaser()
        if purchaser == old_hero then
          purchaser = nil
        end
        cooldown = item:GetCooldownTimeRemaining()
        if item:RequiresCharges() then
          charges = item:GetCurrentCharges()
        end
      end
    end
    items[i] = {item_name, purchaser, cooldown, charges}
  end

  -- Neutral items (check every slot)
  for i = DOTA_ITEM_SLOT_1, 20 do
    local item = old_hero:GetItemInSlot(i)
    if item then
      if item:IsNeutralDrop() then
        -- Return the item to stash
        PlayerResource:AddNeutralItemToStash(playerID, old_hero:GetTeamNumber(), item)
      end
    end
  end

  -- Permanent modifiers
  if old_hero:HasModifier('modifier_legion_commander_duel_damage_boost') then
    self.duel_damage = old_hero:FindModifierByName('modifier_legion_commander_duel_damage_boost'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_custom') then
    self.duel_damage = old_hero:FindModifierByName('modifier_legion_commander_duel_damage_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_oaa_int_steal') then
    self.stolen_int = old_hero:FindModifierByName('modifier_oaa_int_steal'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap') then
    self.flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap_oaa_custom') then
    self.flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_permanent_buff') then
    self.essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_permanent_buff'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_oaa_custom') then
    self.essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_item_ultimate_scepter_consumed') or old_hero:HasModifier('modifier_item_ultimate_scepter_consumed_alchemist') then
    self.aghanim_scepter = true
  end
  if old_hero:HasShardOAA() then
    self.aghanim_shard = true
  end

  PrecacheUnitByNameAsync(new_hero_name, function()
    local new_hero = PlayerResource:ReplaceHeroWith(playerID, new_hero_name, gold_1, 0)

    -- Level Up the new hero
    for i = 1, hero_lvl - 1 do
      new_hero:HeroLevelUp(false) -- false because we don't want to see level up effects
    end

    -- Adjust experience
    --new_hero:AddExperience(hero_xp_1, DOTA_ModifyXP_Unspecified, false, true)

    -- Adjust ability points
    --new_hero:SetAbilityPoints(spent_ability_points)

    -- Remove any item that is given to the new hero for no reason
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = new_hero:GetItemInSlot(i)
      if item then
        new_hero:RemoveItem(item)
      end
    end

    -- Scepter and shard modifiers
    if self.aghanim_scepter then
      local scepter = CreateItem("item_ultimate_scepter_2", new_hero, new_hero)
      new_hero:AddItem(scepter)
    end
    if self.aghanim_shard then
      local shard = CreateItem("item_aghanims_shard", new_hero, new_hero)
      new_hero:AddItem(shard)
    end

    -- Create new items for the new hero
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = items[i]
      local item_name = item[1]
      local purchaser = item[2]
      local cooldown = item[3]
      local charges = item[4]
      if item_name then
        local new_item = CreateItem(item_name, new_hero, new_hero)
        new_hero:AddItem(new_item)
        --new_item:SetStacksWithOtherOwners(true)
        if purchaser then
          new_item:SetPurchaser(purchaser)
        else
          new_item:SetPurchaser(new_hero)
        end
        if charges then
          new_item:SetCurrentCharges(charges)
        end
        if cooldown and cooldown > 0 then
          new_item:StartCooldown(cooldown)
        end
      end
    end

    -- Create new permanent modifiers for the new hero
    if self.duel_damage then
      if not new_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_custom') then
        local duel_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_legion_commander_duel_damage_oaa_custom', {})
        duel_modifier:SetStackCount(self.duel_damage)
      end
    end

    if self.stolen_int then
      if not new_hero:HasModifier('modifier_oaa_int_steal') then
        local int_steal_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_oaa_int_steal', {})
        int_steal_modifier:SetStackCount(self.stolen_int)
      end
    end

    if self.flesh_heap then
      if not new_hero:HasModifier('modifier_pudge_flesh_heap_oaa_custom') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_pudge_flesh_heap_oaa_custom', {})
        flesh_heap_modifier:SetStackCount(self.flesh_heap)
      end
    end

    if self.essence_shift then
      if not new_hero:HasModifier('modifier_slark_essence_shift_oaa_custom') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_slark_essence_shift_oaa_custom', {})
        flesh_heap_modifier:SetStackCount(self.essence_shift)
      end
    end

    -- Add ARDM modifier to the new hero
    new_hero:AddNewModifier(new_hero, nil, 'modifier_ardm', {})

    -- Needs delay of the longeest buff or debuff
    Timers:CreateTimer(50, function()
      if old_hero then
        UTIL_Remove(old_hero)
      end
    end)

    local player = PlayerResource:GetPlayer(playerID)
    if player then
      player:SetAssignedHeroEntity(new_hero)
    end
  end)
end

function modifier_ardm:DeclareFunctions()
  return {
    MODIFIER_EVENT_ON_RESPAWN
  }
end

function modifier_ardm:OnRespawn()
  if not IsServer() then
    return
  end
  if self.hero then
    self:ReplaceHero(self:GetParent(), self.hero)
  end
end

function modifier_ardm:IsHidden()
  return true
end
function modifier_ardm:IsDebuff()
  return false
end
function modifier_ardm:IsPurgable()
  return false
end
function modifier_ardm:IsPurgeException()
  return false
end
function modifier_ardm:IsPermanent()
  return true
end
function modifier_ardm:RemoveOnDeath()
  return false
end
