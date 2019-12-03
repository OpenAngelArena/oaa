-- Taken from bb template
if AbilityLevels == nil then
    DebugPrint ( 'creating new ability level requirement object.' )
    AbilityLevels = class({})
    Debug.EnabledModules["abilities:*"] = true
end

function AbilityLevels:Init ()
  FilterManager:AddFilter(FilterManager.ExecuteOrder, self, Dynamic_Wrap(self, "FilterAbilityUpgradeOrder"))
  GameEvents:OnPlayerLevelUp(partial(self.CheckAbilityLevels, self))
  GameEvents:OnPlayerLearnedAbility(partial(self.CheckAbilityLevels, self))
  CustomGameEventManager:RegisterListener("check_level_up_selection", function(_, keys)
    -- Change the player ID to an entity index
    keys.player = PlayerResource:GetPlayer(keys.PlayerID):entindex()
    self:CheckAbilityLevels(keys)
  end)
end

function AbilityLevels:CheckAbilityLevels (keys)
  local player = EntIndexToHScript(keys.player)
  local level = keys.level
  local hero
  if keys.selectedEntity then
    hero = EntIndexToHScript(keys.selectedEntity)
  else
    hero = player:GetAssignedHero()
  end
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
  local ability_name = keys.abilityname
  if ability_name then
    if string.find(ability_name, "special_bonus") then
      if hero.learned_talents_table == nil then
	     hero.learned_talents_table = {}
	  end
	  local n = #hero.learned_talents_table
	  -- Max number of learned talents is 4
	  if n<4 then
	    -- Store which talents are learned on the hero itself
	    hero.learned_talents_table[n+1] = ability_name
		print("Storing talent "..ability_name.." to the hero.")
	  end
    end
  end
  
  if level == 30 then
    Timers:CreateTimer(0.1, function()
      -- Find all talents on the hero
	  for i = 0, hero:GetAbilityCount() - 1 do
        local ability = hero:GetAbilityByIndex(i)
        if ability and ability:IsAttributeBonus() then
          if ability:GetLevel() ~= 0 then
			local ability_name = ability:GetAbilityName()
			local original_talent_flag = false
			if hero.learned_talents_table then
			  local n = #hero.learned_talents_table
			  for j = 1, n do
			    if ability_name == hero.learned_talents_table[j] then
				  print(ability_name)
				  print("This ability was learned on the hero before level 30 and not with aghs.")
				  original_talent_flag = true
				end
			  end
			end
			if not original_talent_flag then
			  -- TO DO: Check Aghs level
			  ability:SetLevel(0)
			  print(ability_name)
			  print("This ability was auto-leveled at level 30 and not with aghs.")
			end
		  else
		    print(ability:GetAbilityName())
			print("Talent is on the hero but its level is not 1")
		  end
        end
      end
    end)
  end
]]
end

function AbilityLevels:GetRequiredLevel (hero, abilityName)
  -- Ability hero level requirements
  local basicReqs = {0, 0, 0, 0, 28, 40}
  local ultimateReqs = {0, 0, 0, 37, 49}

  local invokerAbilityReqs = {0, 0, 0, 0, 0, 0, 0, 26, 28, 30, 32, 34, 36, 38}
  -- Ability hero level requirements for abilities that don't follow the default pattern
  local exceptionAbilityReqs = {invoker_quas = invokerAbilityReqs,
                                invoker_wex = invokerAbilityReqs,
                                invoker_exort = invokerAbilityReqs}

  local ability = hero:FindAbilityByName(abilityName)
  local abilityLevel = ability:GetLevel()
  local abilityType = ability:GetAbilityType()
  local reqTable = basicReqs

  if exceptionAbilityReqs[abilityName] then -- Ability doesn't follow default requirement pattern
    reqTable = exceptionAbilityReqs[abilityName]
  elseif abilityType == 1 then -- Ability is DOTA_ABILITY_TYPE_ULTIMATE
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
