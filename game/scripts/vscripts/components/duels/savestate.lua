-- This module contains functions for saving and restoring the state of heroes
local SafeTeleportAll = require("components/duels/teleport").SafeTeleportAll

LinkLuaModifier('modifier_offside', 'modifiers/modifier_offside.lua', LUA_MODIFIER_MOTION_NONE)

local export = {}

local function RefreshAbilityFilter(ability)
  return ability:GetAbilityType() ~= 1
end

local function PurgeDuelHighgroundBuffs(hero)
  local modifierList = {
    "modifier_rune_haste",
    "modifier_rune_doubledamage",
    "modifier_rune_invis",
    "modifier_rune_hill_tripledamage",
  }
  iter(modifierList):each(partial(hero.RemoveModifierByName, hero))
end

local function ResetState(hero)
  if hero:HasModifier("modifier_skeleton_king_reincarnation_scepter_active") then
    hero:RemoveModifierByName("modifier_skeleton_king_reincarnation_scepter_active")
  end
  if hero:HasModifier("modifier_offside") then
    hero:RemoveModifierByName("modifier_offside")
  end
  if hero:HasModifier("modifier_is_in_offside") then
    hero:RemoveModifierByName("modifier_is_in_offside")
  end

  if not hero:IsAlive() then
    hero:RespawnHero(false,false)
  end

  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  -- Reset cooldown for abilities
  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability ~= nil and RefreshAbilityFilter(ability) then
      ability:EndCooldown()
      ability:RefreshCharges()
    end
  end

  -- Reset cooldown for items
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    if item  then
      item:EndCooldown()
    end
  end
end

local function SaveState(hero)
  local state = {
    location = hero:GetAbsOrigin(),
    abilities = {},
    items = {},
    modifiers = {},
    offsidesStacks = 0,
    hp = hero:GetHealth(),
    mana = hero:GetMana(),
    assignable = true -- basically just for clearer code
  }

  -- If hero is dead during start of the duel, make his saved location his foutain area
  if not hero:IsAlive() then
    local fountainTriggerZone = Entities:FindByName(nil, "fountain_" .. GetShortTeamName(hero:GetTeam()) .. "_trigger")
    if fountainTriggerZone then
      state.location = fountainTriggerZone:GetCenter()
    else -- Can't find the fountain for some reason, so just dump them in the center of the map
      state.location = GetGroundPosition(Vector(0, 0, 0), hero)
    end
  else
    -- hero is alive, lets check for offsides protection aura
    local modifier = hero:FindModifierByName("modifier_offside")
    if modifier then
      state.offsidesStacks = modifier:GetStackCount()
    end
  end

  for abilityIndex = 0, hero:GetAbilityCount() - 1 do
    local ability = hero:GetAbilityByIndex(abilityIndex)
    if ability and RefreshAbilityFilter(ability) then
      state.abilities[ability:GetAbilityName()] = {
        cooldown = ability:GetCooldownTimeRemaining()
      }
    end
  end

  for itemIndex = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(itemIndex)
    if item then
      state.items[item] = {
        cooldown = item:GetCooldownTimeRemaining()
      }
    end
  end

  return state
end

local function RestoreState(hero, state)
  SafeTeleportAll(hero, state.location, 150)

  hero:SetHealth(math.max(1, state.hp))
  hero:SetMana(state.mana)

  -- Restore ability cooldowns
  for name, abilityState in pairs(state.abilities) do
    local ability = hero:FindAbilityByName(name)
    if ability then
      ability:EndCooldown()
      ability:StartCooldown(abilityState.cooldown)
    end
  end

  -- Restore item cooldowns
  for item, itemState in pairs(state.items) do
    if IsValidEntity(item) then
      item:EndCooldown()
      item:StartCooldown(itemState.cooldown)
    end
  end

  -- Restore offside stacks if hero had any
  if state.offsidesStacks > 0 then
    local modifier = hero:AddNewModifier(hero, nil, "modifier_offside", {})
    modifier:SetStackCount(state.offsidesStacks)
  end
end

local function TestSaveAndLoadState(keys)
  local hero = PlayerResource:GetSelectedHeroEntity(keys.playerid)
  local state = SaveState(hero)
  Timers:CreateTimer(3, function ()
    RestoreState(hero,state)
  end)
end

ChatCommand:LinkDevCommand("-test_state", TestSaveAndLoadState, nil)
export.PurgeDuelHighgroundBuffs = PurgeDuelHighgroundBuffs
export.SaveState = SaveState
export.ResetState = ResetState
export.RestoreState = RestoreState

return export
