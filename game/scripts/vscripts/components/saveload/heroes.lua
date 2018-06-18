SaveLoadStateHero = SaveLoadStateHero or class({})

function SaveLoadStateHero:GetState ()
  local state = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    state[playerID] = {}

    if hero then
      state[playerID].items = self:GetItemState(playerID, hero)
      state[playerID].abilities = self:GetAbilityState(playerID, hero)
      state[playerID].xp = hero:GetCurrentXP()

      if hero:IsAlive() then
        state[playerID].location = hero:GetAbsOrigin()
        state[playerID].hp = hero:GetHealth()
        state[playerID].mana = hero:GetMana()
      else
        local fountainTriggerZone = Entities:FindByName(nil, "fountain_" .. GetShortTeamName(hero:GetTeam()) .. "_trigger")
        if fountainTriggerZone then
          state[playerID].location = fountainTriggerZone:GetCenter()
        else -- Can't find the fountain for some reason, so just dump them in the center of the map
          state[playerID].location = GetGroundPosition(Vector(0, 0, 0), hero)
        end
      end
      state[playerID].location = { state[playerID].location.x, state[playerID].location.y, state[playerID].location.z }
    end
  end

  return state
end

function SaveLoadStateHero:LoadState (state)
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)

    if hero then
      hero:AddExperience(state[playerID].xp, DOTA_ModifyXP_Unspecified, false, false)

      self:LoadItemState(playerID, hero, state[playerID].items)
      self:LoadAbilityState(playerID, hero, state[playerID].abilities)
      hero:SetAbsOrigin(Vector(state[playerID].location[1], state[playerID].location[2], state[playerID].location[3]))
    end
  end
end

function SaveLoadStateHero:GetItemState (playerID, hero)
  local state = {}

  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    local slotName = 'slot' .. i
    if item ~= nil then
      state[slotName] = {
        name = item:GetName(),
        cooldown = item:GetCooldownTimeRemaining()
      }
      if item.GetCurrentCharges then
        state[slotName]['charges'] = item:GetCurrentCharges()
      end
    end
  end

  return state
end

function SaveLoadStateHero:LoadItemState (playerID, hero, state)
  local dummies = {}

  for i = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    local slotName = 'slot' .. i

    if item ~= nil then
      hero:TakeItem(item)
      if not item:IsNull() then
        item:Destroy()
      end
    end
    if not state[slotName] then
      local newItem = hero:AddItemByName('item_core_info')
      table.insert(dummies, newItem)
    else
      DebugPrint('Giving hero this item ' .. state[slotName].name)
      local newItem = hero:AddItemByName(state[slotName].name)
      if newItem and newItem.SetCurrentCharges and state[slotName].charges then
        newItem:SetCurrentCharges(state[slotName].charges)
      end
    end
  end

  for _,item in ipairs(dummies) do
    item:Destroy()
  end

  return state
end

function SaveLoadStateHero:GetAbilityState (playerID, hero)
  local state = {}
  local extraPoints = 0

  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability then
      if ability:IsAttributeBonus() then
        state[ability:GetAbilityName()] = {
          cooldown = 0,
          level = 0,
        }
        extraPoints = extraPoints + 1
      else
        state[ability:GetAbilityName()] = {
          cooldown = ability:GetCooldownTimeRemaining(),
          level = ability:GetLevel()
        }
      end
    end
  end
  state.abilityPoints = hero:GetAbilityPoints() + extraPoints

  return state
end


function SaveLoadStateHero:LoadAbilityState (playerID, hero, state)
  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability then
      local name = ability:GetAbilityName()

      ability:SetLevel(state[name].level)

      if state[name].cooldown > 0 then
        ability:EndCooldown()
        ability:StartCooldown(state[name].cooldown)
      end
    end
  end

  hero:SetAbilityPoints(state.abilityPoints)

  return state
end
