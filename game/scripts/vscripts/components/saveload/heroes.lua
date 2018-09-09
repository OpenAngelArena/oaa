SaveLoadStateHero = SaveLoadStateHero or class({})

function SaveLoadStateHero:GetState ()
  local state = {}

  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))

    state[steamid] = {}

    if hero then
      state[steamid].items = self:GetItemState(playerID, hero)
      state[steamid].abilities = self:GetAbilityState(playerID, hero)
      state[steamid].special = self:GetSpecialState(playerID, hero)
      state[steamid].xp = hero:GetCurrentXP()

      if hero:IsAlive() then
        state[steamid].location = hero:GetAbsOrigin()
        state[steamid].hp = hero:GetHealth()
        state[steamid].mana = hero:GetMana()
      else
        local fountainTriggerZone = Entities:FindByName(nil, "fountain_" .. GetShortTeamName(hero:GetTeam()) .. "_trigger")
        if fountainTriggerZone then
          state[steamid].location = fountainTriggerZone:GetCenter()
        else -- Can't find the fountain for some reason, so just dump them in the center of the map
          state[steamid].location = GetGroundPosition(Vector(0, 0, 0), hero)
        end
      end
      state[steamid].location = { state[steamid].location.x, state[steamid].location.y, state[steamid].location.z }
    end
  end

  return state
end

function SaveLoadStateHero:LoadState (state)
  for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    local steamid = tostring(PlayerResource:GetSteamAccountID(playerID))

    if hero then
      hero:AddExperience(state[steamid].xp - hero:GetCurrentXP(), DOTA_ModifyXP_Unspecified, false, false)

      self:LoadItemState(playerID, hero, state[steamid].items)
      self:LoadAbilityState(playerID, hero, state[steamid].abilities)
      self:LoadSpecialState(playerID, hero, state[steamid].special)
      hero:SetAbsOrigin(Vector(state[steamid].location[1], state[steamid].location[2], state[steamid].location[3]))
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
        extraPoints = extraPoints + ability:GetLevel()
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
end

function SaveLoadStateHero:GetSpecialState (playerID, hero)
  local state = {}

  if hero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ) then
    state.duel_damage = hero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ):GetStackCount()
  end

  if hero:FindModifierByName('modifier_oaa_int_steal' ) then
    state.stolen_int = hero:FindModifierByName('modifier_oaa_int_steal' ):GetStackCount()
  end

  if hero:FindModifierByName('modifier_pudge_flesh_heap' ) then
    state.flesh_heap = hero:FindModifierByName('modifier_pudge_flesh_heap' ):GetStackCount()
  end

  return state
end

function SaveLoadStateHero:LoadSpecialState (playerID, hero, state)
  if state.duel_damage then
    if not hero:HasModifier('modifier_legion_commander_duel_damage_boost' ) then
      hero:AddNewModifier( hero, hero:FindAbilityByName('legion_commander_duel'), 'modifier_legion_commander_duel_damage_boost', {} )
    end
    hero:FindModifierByName('modifier_legion_commander_duel_damage_boost' ):SetStackCount(state.duel_damage)
  end

  if state.stolen_int then
    hero:FindModifierByName('modifier_oaa_int_steal' ):SetStackCount(state.stolen_int)
  end

  if state.flesh_heap then
    -- Not Working. But is should!
    if not hero:HasModifier('modifier_pudge_flesh_heap' ) then
      hero:AddNewModifier( hero, hero:FindAbilityByName('pudge_flesh_heap'), 'modifier_pudge_flesh_heap', {} )
    end
    hero:FindModifierByName('modifier_pudge_flesh_heap' ):SetStackCount(state.flesh_heap)
  end
end
