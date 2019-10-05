GameEvents:OnEntityFatalDamage(function (keys)
  local killedUnit = EntIndexToHScript(keys.entindex_killed)
  if not killedUnit:IsCreep() then
    return
  end
  local attacker = EntIndexToHScript(keys.entindex_attacker)
  local player = attacker:GetPlayerOwner()
  local playerID = attacker:GetPlayerOwnerID()

  local function divBy100(num)
    return num / 100
  end

  local sharedBountyItems = {
    "item_travel_origin",
    "item_greater_travel_boots",
    "item_greater_travel_boots_2",
    "item_greater_travel_boots_3",
    "item_greater_travel_boots_4",
    "item_greater_travel_boots_5",
  }
  -- table of player id to share with,
  local shareTable = {}

  -- do shared creep bounty for neutrals
  if killedUnit:IsNeutralUnitType() then
    local allies = FindUnitsInRadius(
	  PlayerResource:GetTeam(playerID),
	  attacker:GetOrigin(),
	  nil,
	  CREEP_BOUNTY_SHARE_RADIUS,
	  DOTA_UNIT_TARGET_TEAM_FRIENDLY,
	  DOTA_UNIT_TARGET_HERO,
	  bit.bor(DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO),
      FIND_ANY_ORDER,
      false
    )

    -- first, locate appropriate units ( in this case, real allied heroes )
    for _, unit in pairs(allies) do
      local shareID = unit:GetPlayerOwnerID()
	  if shareID ~= playerID then
        if not shareTable[shareID] then
	      shareTable[shareID] = 0
	    end

        -- record the amount of bonus
        -- this is a really ugly hardcoded way to do this
        -- but the day valve gives us custom modifier properties
        -- is the day i know we're in the matrix
        if unit:HasInventory() then
          for _, itemName in pairs(sharedBountyItems) do
            local item = unit:FindItemInInventory(itemName)

            if item then
              local shareBonus = item:GetSpecialValueFor("assist_percent")

              -- we're only interested in using the highest bonus at this point in time
              -- ( since the only current way to stack 'em is cheating for multiple tp boots )
              if shareBonus > shareTable[shareID] then
                shareTable[shareID] = shareBonus
              end
            end
          end
        end
	  end
	end

    -- now that we know what players to give gold too, as well as their bonus
    -- do the gold givery
    for pID, bonus in pairs(shareTable) do
      local percent = CREEP_BOUNTY_SHARE_PERCENT + bonus
      -- minimum shared bounty of 1 because really now
      local bounty = math.max(1, killedUnit:GetGoldBounty() * divBy100(percent))
      local allyPlayer = PlayerResource:GetPlayer(pID)

      Gold:ModifyGold(pID, bounty, false, DOTA_ModifyGold_SharedGold)
      SendOverheadEventMessage(allyPlayer, OVERHEAD_ALERT_GOLD, killedUnit, math.floor(bounty), allyPlayer)
    end
  end

  -- old fool's gold reduction after shared bounty
  --[[
  local function HasCreepBountyMult(modifier)
    return modifier.DeclareFunctions and
      contains(MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER, modifier:DeclareFunctions())
  end
  local creepBountyMultiplier = iter(attacker:FindAllModifiers())
                                  :filter(HasCreepBountyMult)
                                  :map(compose(divBy100, CallMethod("GetModifierBountyCreepMultiplier")))
                                  :product()
  local newGoldBounty = math.floor(killedUnit:GetGoldBounty() * creepBountyMultiplier)
  killedUnit:SetMinimumGoldBounty(newGoldBounty)
  killedUnit:SetMaximumGoldBounty(newGoldBounty)
  ]]

  -- bonus gold if player has specific sparks that give percentage gold bonus bounty
  -- I am not using MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER in case Valve makes it actually work
  local creepBountyMultiplier = 1
  if attacker:HasModifier("modifier_spark_cleave") then
    creepBountyMultiplier = creepBountyMultiplier + CREEP_BOUNTY_BONUS_PERCENT_CLEAVE/100
  elseif attacker:HasModifier("modifier_spark_power") then
    creepBountyMultiplier = creepBountyMultiplier + CREEP_BOUNTY_BONUS_PERCENT_POWER/100
  end

  local oldGoldBountyMin = killedUnit:GetMinimumGoldBounty()
  local oldGoldBountyMax = killedUnit:GetMaximumGoldBounty()
  local newGoldBountyMin = oldGoldBountyMin * creepBountyMultiplier
  local newGoldBountyMax = oldGoldBountyMax * creepBountyMultiplier
  killedUnit:SetMinimumGoldBounty(newGoldBountyMin)
  killedUnit:SetMaximumGoldBounty(newGoldBountyMax)

  -- PlayerResource:ModifyGold(playerID, goldBounty, false, DOTA_ModifyGold_CreepKill)
  -- if player then
  --   SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, killedUnit, goldBounty, player)
  -- end
end)
