
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

  -- Neutral items and TP scroll (check every slot)
  for i = DOTA_ITEM_SLOT_1, 20 do
    local item = old_hero:GetItemInSlot(i)
    if item then
      if item:IsNeutralDrop() then
        -- Return the item to stash (order)
        local order_table = {
          UnitIndex = old_hero:GetEntityIndex(),
          OrderType = DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN,
          --TargetIndex = EntityIndex,
          AbilityIndex = item:GetEntityIndex(),
          --Position = Vector(0,0,0),
          Queue = false,
        }
        ExecuteOrderFromTable(order_table)
        -- Return the item to stash - crashes
        --PlayerResource:AddNeutralItemToStash(playerID, old_hero:GetTeamNumber(), item)
      elseif item:GetName() == "item_tpscroll" and i == DOTA_ITEM_TP_SCROLL then
        items[DOTA_ITEM_TP_SCROLL][1] = "item_tpscroll"
        items[DOTA_ITEM_TP_SCROLL][3] = item:GetCooldownTimeRemaining()
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
  if old_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_ardm') then
    duel_damage = old_hero:FindModifierByName('modifier_legion_commander_duel_damage_oaa_ardm'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_oaa_int_steal') then
    stolen_int = old_hero:FindModifierByName('modifier_oaa_int_steal'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_silencer_int_steal_oaa_ardm') then
    stolen_int = old_hero:FindModifierByName('modifier_silencer_int_steal_oaa_ardm'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap') then
    flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_pudge_flesh_heap_oaa_ardm') then
    flesh_heap = old_hero:FindModifierByName('modifier_pudge_flesh_heap_oaa_ardm'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_permanent_buff') then
    essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_permanent_buff'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_slark_essence_shift_oaa_ardm') then
    essence_shift = old_hero:FindModifierByName('modifier_slark_essence_shift_oaa_ardm'):GetStackCount()
  end
  if old_hero:HasModifier('modifier_item_ultimate_scepter_consumed') or old_hero:HasModifier('modifier_item_ultimate_scepter_consumed_alchemist') then
    aghanim_scepter = true
  end
  if old_hero:HasShardOAA() then
    aghanim_shard = true
  end

  -- Find which spark hero has
  local spark
  if old_hero:HasModifier('modifier_spark_cleave') then
    spark = "modifier_spark_cleave"
  end
  if old_hero:HasModifier('modifier_spark_midas') then
    spark = "modifier_spark_midas"
  end
  if old_hero:HasModifier('modifier_spark_power') then
    spark = "modifier_spark_power"
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

    -- Prevent TP scroll starting on cooldown
    local tp_scroll = new_hero:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
    if tp_scroll then
      if tp_scroll:GetName() == "item_tpscroll" then
        tp_scroll:EndCooldown()
        if items[DOTA_ITEM_TP_SCROLL] then
          tp_scroll:StartCooldown(items[DOTA_ITEM_TP_SCROLL][3] or 1)
        end
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
      if not new_hero:HasModifier('modifier_legion_commander_duel_damage_oaa_ardm') then
        local duel_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_legion_commander_duel_damage_oaa_ardm', {})
        duel_modifier:SetStackCount(duel_damage)
      end
    end

    if stolen_int then
      if not new_hero:HasModifier('modifier_silencer_int_steal_oaa_ardm') then
        local int_steal_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_silencer_int_steal_oaa_ardm', {})
        int_steal_modifier:SetStackCount(stolen_int)
      end
    end

    if flesh_heap then
      if not new_hero:HasModifier('modifier_pudge_flesh_heap_oaa_ardm') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_pudge_flesh_heap_oaa_ardm', {})
        flesh_heap_modifier:SetStackCount(flesh_heap)
      end
    end

    if essence_shift then
      if not new_hero:HasModifier('modifier_slark_essence_shift_oaa_ardm') then
        local flesh_heap_modifier = new_hero:AddNewModifier(new_hero, nil, 'modifier_slark_essence_shift_oaa_ardm', {})
        flesh_heap_modifier:SetStackCount(essence_shift)
      end
    end

    -- Other hidden permanent modifiers
    if not new_hero:HasModifier("modifier_spark_gpm") then
      new_hero:AddNewModifier(new_hero, nil, "modifier_spark_gpm", {})
    end
    if spark then
      if not new_hero:HasModifier(spark) then
        new_hero:AddNewModifier(new_hero, nil, spark, {})
      end
    end
    -- Adding modifier_oaa_passive_gpm is probably not needed because Gold.hasPassiveGPM table adds an element for every new hero spawn

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
