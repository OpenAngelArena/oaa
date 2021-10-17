LinkLuaModifier("modifier_ardm", "modifiers/modifier_ardm.lua", LUA_MODIFIER_MOTION_NONE )

modifier_ardm = class(ModifierBaseClass)

function modifier_ardm:ReplaceHero(old_hero, new_hero_name)
  if not IsServer() then
    return
  end
  Debug:EnableDebugging()
  if not new_hero_name or not old_hero then
    DebugPrint("Old hero is "..tostring(old_hero))
    DebugPrint("New hero is "..tostring(new_hero_name))
    return
  end

  local playerID = old_hero:GetPlayerID()
  local old_hero_gold = 0
  if Gold then
    old_hero_gold = Gold:GetGold(playerID)
  else
    old_hero_gold = PlayerResource:GetGold(playerID)
  end

  local old_hero_xp = old_hero:GetCurrentXP() -- PlayerResource:GetTotalEarnedXP(playerID)
  local hero_lvl = old_hero:GetLevel()

  -- Calculate spent ability/skill points - not needed
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
  local duel_damage
  local stolen_int
  local flesh_heap
  local essence_shift
  local aghanim_scepter
  local aghanim_shard

  if old_hero:HasModifier('modifier_legion_commander_duel_damage_boost') then
    duel_damage = old_hero:FindModifierByName('modifier_legion_commander_duel_damage_boost'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_custom') then
    duel_damage = old_hero:FindModifierByName('modifier_legion_commander_duel_damage_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_oaa_int_steal') then
    stolen_int = old_hero:FindModifierByName('modifier_oaa_int_steal'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap') then
    flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap_oaa_custom') then
    flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_permanent_buff') then
    essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_permanent_buff'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_oaa_custom') then
    essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_oaa_custom'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_item_ultimate_scepter_consumed') or old_hero:HasModifier('modifier_item_ultimate_scepter_consumed_alchemist') then
    aghanim_scepter = true
  end
  if old_hero:HasShardOAA() then
    aghanim_shard = true
  end

  --PrecacheUnitByNameAsync(new_hero_name, function()
  local new_hero = PlayerResource:ReplaceHeroWith(playerID, new_hero_name, old_hero_gold, 0)

  Timers:CreateTimer(0.03, function()

    -- Level Up the new hero
    for i = 1, hero_lvl - 1 do
      new_hero:HeroLevelUp(false) -- false because we don't want to see level up effects
    end

    -- Adjust experience
    local current_xp = new_hero:GetCurrentXP()
    new_hero:AddExperience(math.abs(old_hero_xp - current_xp), DOTA_ModifyXP_Unspecified, false, true)

    -- Adjust ability points - not needed
    --new_hero:SetAbilityPoints(spent_ability_points)

    -- Remove any item that is given to the new hero for no reason
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = new_hero:GetItemInSlot(i)
      if item then
        new_hero:RemoveItem(item)
      end
    end

    -- Scepter and shard modifiers
    if aghanim_scepter then
      local scepter = CreateItem("item_ultimate_scepter_2", new_hero, new_hero)
      new_hero:AddItem(scepter)
    end
    if aghanim_shard then
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
        -- Set purchaser
        if purchaser then
          new_item:SetPurchaser(purchaser)
        else
          new_item:SetPurchaser(new_hero)
        end
        -- Set charges
        if charges then
          new_item:SetCurrentCharges(charges)
        end
        -- Set cooldowns
        if cooldown and cooldown > 0 then
          new_item:StartCooldown(cooldown)
        end
      end
    end

    -- Create new permanent modifiers for the new hero
    if duel_damage then
      if not new_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_custom') then
        local duel_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_legion_commander_duel_damage_oaa_custom', {})
        duel_modifier:SetStackCount(duel_damage)
      end
    end

    if stolen_int then
      if not new_hero:HasModifier('modifier_oaa_int_steal') then
        local int_steal_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_oaa_int_steal', {})
        int_steal_modifier:SetStackCount(stolen_int)
      end
    end

    if flesh_heap then
      if not new_hero:HasModifier('modifier_pudge_flesh_heap_oaa_custom') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_pudge_flesh_heap_oaa_custom', {})
        flesh_heap_modifier:SetStackCount(flesh_heap)
      end
    end

    if essence_shift then
      if not new_hero:HasModifier('modifier_slark_essence_shift_oaa_custom') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_slark_essence_shift_oaa_custom', {})
        flesh_heap_modifier:SetStackCount(essence_shift)
      end
    end

    -- Add ARDM modifier to the new hero
    new_hero:AddNewModifier(new_hero, nil, 'modifier_ardm', {})

    -- Remove the old hero
    UTIL_Remove(old_hero)

    -- Important for Wanderer Sticky Napalm
    local player = PlayerResource:GetPlayer(playerID)
    if player then
      if player:GetAssignedHero() ~= new_hero then
        player:SetAssignedHeroEntity(new_hero)
      end
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
