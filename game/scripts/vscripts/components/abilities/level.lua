-- Taken from bb template
if AbilityLevels == nil then
    DebugPrint ( 'creating new ability level requirement object.' )
    AbilityLevels = class({})
    Debug.EnabledModules["abilities:*"] = true
end

function AbilityLevels:Init ()
  self.moduleName = "AbilityLevels"
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(self, "FilterAbilityUpgradeOrder"))
  GameEvents:OnPlayerLevelUp(partial(self.CheckAbilityLevels, self))
  GameEvents:OnPlayerLearnedAbility(partial(self.CheckAbilityLevels, self))
  CustomGameEventManager:RegisterListener("check_level_up_selection", function(_, keys)
    -- Change the player ID to an entity index
    self:CheckAbilityLevels(keys)
  end)
end

function AbilityLevels:CheckAbilityLevels (keys)
  -- dota_player_gained_level:
  --"player_id"
  --"level"
  --"hero_entindex"

  -- dota_player_learned_ability:
  --"PlayerID"
  --"player"
  --"abilityname"

  local playerID = keys.player_id or keys.PlayerID
  local player
  if keys.player then
    player = EntIndexToHScript(keys.player)
  else
    player = PlayerResource:GetPlayer(playerID)
  end

  local hero
  if keys.selectedEntity then
    hero = EntIndexToHScript(keys.selectedEntity)
  elseif keys.hero_entindex then
    hero = EntIndexToHScript(keys.hero_entindex)
  else
    hero = player:GetAssignedHero()
  end

  local level = keys.level
  if not level then
    level = hero:GetLevel()
  end

  local canLevelUp = {}

  for index = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(index)
    if ability and not ability:IsHidden() then
      local abilityName = ability:GetAbilityName()
      table.insert(canLevelUp, self:GetRequiredLevel(hero, abilityName))
    end
  end

  CustomGameEventManager:Send_ServerToPlayer(player, "check_level_up", {
    level = level,
    canLevelUp = canLevelUp
  })

  --[[
  self:SetTalents(hero)

  local leveled_up_ability_name = keys.abilityname
  if leveled_up_ability_name then
    local leveled_up_ability = hero:FindAbilityByName(leveled_up_ability_name)
    -- Check if ability exists, if it is a talent and if hero level is where issues start
    if leveled_up_ability and IsTalentCustom(leveled_up_ability_name) and level >= 26 then
      -- Learned ability is a talent
      local talent = leveled_up_ability
      -- Refund a skill point if a player wasted it on a talent that is not supposed to be levelled.
      if talent:GetLevel() == 0 or talent.granted_with_oaa_scepter then
        -- Talent wasn't learned despite clicking on it or the talent was granted by Aghanim Scepter
        -- dota_player_learned_ability event doesn't happen for abilities that are lvled with: ability:SetLevel(level)
        hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
      end
    end
  end
  ]]
end
--[[
function AbilityLevels:SetTalents(hero)
  local aghsPower = 0

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    if item then
      if string.sub(item:GetName(), 0, 22) == 'item_aghanims_scepter_' then
        local level = tonumber(string.sub(item:GetName(), 23))
        if level > aghsPower then
          aghsPower = level
        end
      end
    end
  end

  -- 10 - 17
  -- input is { [10] = true, [15] = true, ... }
  local tree = {
    [10] = aghsPower > 1,
    [15] = aghsPower > 2,
    [20] = aghsPower > 3,
    [25] = aghsPower > 4,
  }
  if hero:GetLevel() >= 50 then
    tree = {
      [10] = true,
      [15] = true,
      [20] = true,
      [25] = true,
    }
  end
  local function setTalentLevel (level, leftAbility, rightAbility, claim)
    if not leftAbility or not rightAbility then
      -- print('No ability for index ' .. leftIndex .. ', ' .. rightIndex)
      return
    end
    local leftLevel = leftAbility:GetLevel()
    local rightLevel = rightAbility:GetLevel()
    -- print (leftAbility:GetName() .. ' vs ' .. rightAbility:GetName())
    if leftLevel == 0 and rightLevel == 0 then
      -- the player hasn't chosen a talent yet
      return
    end
    if leftLevel ~= rightLevel then
      -- they have chosen a talent and it's the only one skilled
      if leftLevel == 0 then
        hero['talentChoice' .. level] = 'right'
      elseif rightLevel == 0 then
        hero['talentChoice' .. level] = 'left'
      end
    elseif claim then
      -- both abilities are upgraded
      -- print(" both abilities are upgraded already")
      return
    end
    -- make sure our talent selection has been made
    assert(
      hero['talentChoice' .. level] == 'left' or hero['talentChoice' .. level] == 'right',
      'Trying to update talent but talent choice was let through!'
    )

    local problematic_talents ={
      {"special_bonus_unique_hero_name", "modifier_special_bonus_unique_hero_name"},
    }

    if claim then
      if leftLevel == 0 then
        leftAbility:SetLevel(1)
        leftAbility.granted_with_oaa_scepter = true
        -- Check if this talent is on problematic list, add modifier if true
        for i = 1, #problematic_talents do
          local talent = problematic_talents[i]
          local leftAbilityName = leftAbility:GetName()
          if leftAbilityName == talent[1] then
            local talent_ability = hero:FindAbilityByName(leftAbilityName)
            if talent_ability then
              local talent_modifier = talent[2]
              hero:AddNewModifier(hero, talent_ability, talent_modifier, {})
            end
          end
        end
      end
      if rightLevel == 0 then
        rightAbility:SetLevel(1)
        rightAbility.granted_with_oaa_scepter = true
        -- Check if this talent is on problematic list, add modifier if true
        for i = 1, #problematic_talents do
          local talent = problematic_talents[i]
          local rightAbilityName = rightAbility:GetName()
          if rightAbilityName == talent[1] then
            local talent_ability = hero:FindAbilityByName(rightAbilityName)
            if talent_ability then
              local talent_modifier = talent[2]
              hero:AddNewModifier(hero, talent_ability, talent_modifier, {})
            end
          end
        end
      end
    else
      -- print ('disabling talents')
      if hero['talentChoice' .. level] == 'left' then
        if rightLevel ~= 0 then
          rightAbility:SetLevel(0)
          rightAbility.granted_with_oaa_scepter = nil
          hero:RemoveModifierByName(AbilityLevels:GetTalentModifier(rightAbility:GetName()))
        end
      else
        if leftLevel ~= 0 then
          leftAbility:SetLevel(0)
          leftAbility.granted_with_oaa_scepter = nil
          hero:RemoveModifierByName(AbilityLevels:GetTalentModifier(leftAbility:GetName()))
        end
      end
    end

    local player = PlayerResource:GetPlayer(hero:GetPlayerID());

    if (hero['talentChoice' .. level] == 'left' or hero['talentChoice' .. level] == 'right') then
      CustomGameEventManager:Send_ServerToPlayer(player, "oaa_scepter_upgrade",
      {
        IsRightSide = hero['talentChoice' .. level] == 'left',
        IsUpgrade = claim,
        Level = level
      })
    end
  end

  local abilityTable = {}
  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability and IsTalentCustom(ability) then
      abilityTable[#abilityTable + 1] = ability
    end
  end

  setTalentLevel("10", abilityTable[2], abilityTable[1], tree[10])
  setTalentLevel("15", abilityTable[4], abilityTable[3], tree[15])
  setTalentLevel("20", abilityTable[6], abilityTable[5], tree[20])
  setTalentLevel("25", abilityTable[8], abilityTable[7], tree[25])
end

function AbilityLevels:GetTalentModifier(name)
  -- Map of special_bonus names to modifier names for Talents that don't follow the pattern
  local exceptionBonuses = {
    special_bonus_spell_immunity = "modifier_special_bonus_spell_immunity",
    special_bonus_haste = "modifier_special_bonus_haste",
    special_bonus_truestrike = "modifier_special_bonus_truestrike",
    special_bonus_unique_warlock_1 = "modifier_special_bonus_unique_warlock_1",
    special_bonus_unique_warlock_2 = "modifier_special_bonus_unique_warlock_2",
    special_bonus_unique_warlock_4 = "modifier_warlock_rain_of_chaos_death_trigger",
    special_bonus_unique_undying_3 = "modifier_undying_tombstone_death_trigger",
    special_bonus_reincarnation_200 = "modifier_special_bonus_reincarnation",
    special_bonus_reincarnation_250 = "modifier_special_bonus_reincarnation",
    special_bonus_reincarnation_300 = "modifier_special_bonus_reincarnation",
  }

  if exceptionBonuses[name] then
    return exceptionBonuses[name]
  end
  -- Handle crit specially as it has a unique pattern
  if string.find(name, "_crit_") then
    return "modifier_special_bonus_crit"
  end

  -- Cut out the last underscore and everything following it
  local chopBonusName = string.match(name, "(.*)_")

  return "modifier_" .. chopBonusName
end
]]
function AbilityLevels:GetRequiredLevel (hero, abilityName)
  -- Ability hero level requirements
  local basicReqs = {0, 0, 0, 0, 28, 40}
  local ultimateReqs = {0, 0, 0, 37, 49}

  local invokerAbilityReqs = {0, 0, 0, 0, 0, 0, 0, 26, 28, 30, 32, 34, 36, 38}
  local summonWolvesReqs = {0, 0, 0, 0, 28, 34, 40, 46}
  local basicInnateAbilityReqs = {0, 0, 0, 0, 0, 28, 40}
  local ultimateInnateAbilityReqs = {0, 0, 0, 0, 37, 49}

  -- Ability hero level requirements for abilities that don't follow the default pattern
  local exceptionAbilityReqs = {
    invoker_quas = invokerAbilityReqs,
    invoker_wex = invokerAbilityReqs,
    invoker_exort = invokerAbilityReqs,
    lycan_summon_wolves = summonWolvesReqs,
  }

  local ability = hero:FindAbilityByName(abilityName)
  local abilityLevel = ability:GetLevel()
  local reqTable = basicReqs

  if exceptionAbilityReqs[abilityName] then -- Ability doesn't follow default requirement pattern
    reqTable = exceptionAbilityReqs[abilityName]
    if abilityName == "lycan_summon_wolves" and ability:GetSpecialValueFor("max_level") ~= 8 then
      reqTable = basicReqs
    end
  elseif IsInnateCustom(abilityName) then
    if IsUltimateAbilityCustom(abilityName) then
      reqTable = ultimateInnateAbilityReqs
    else
      reqTable = basicInnateAbilityReqs
    end
  elseif IsUltimateAbilityCustom(abilityName) then -- Ability is DOTA_ABILITY_TYPE_ULTIMATE
    reqTable = ultimateReqs
  end

  if abilityLevel >= #reqTable then
    return -1
  end

  return reqTable[abilityLevel+1]
end

function AbilityLevels:FilterAbilityUpgradeOrder (keys)
  -- Immediately return true if intercepted order isn't an ability upgrade order
  if keys.order_type ~= DOTA_UNIT_ORDER_TRAIN_ABILITY then
    return true
  end

  local ability = EntIndexToHScript(keys.entindex_ability)
  local abilityName = ability:GetAbilityName()
  local player = PlayerResource:GetPlayer(keys.issuer_player_id_const)
  local hero = EntIndexToHScript(keys.units["0"])
  local heroLevel = hero:GetLevel()

  local requirement = AbilityLevels:GetRequiredLevel(hero, abilityName)

  if heroLevel >= requirement then
    return true
  else
    -- Send event to client to display error message about hero level requirement
    CustomGameEventManager:Send_ServerToPlayer(player, "ability_level_error", {requiredLevel = requirement})
    -- Return false to reject ability upgrade order
    return false
  end
end
