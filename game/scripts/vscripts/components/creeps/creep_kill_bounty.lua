GameEvents:OnEntityFatalDamage(function (keys)
  local killedUnit = EntIndexToHScript(keys.entindex_killed)
  if not killedUnit:IsCreep() then
    return
  end
  local attacker = EntIndexToHScript(keys.entindex_attacker)
  local player = attacker:GetPlayerOwner()
  local playerID = attacker:GetPlayerOwnerID()
  local function HasCreepBountyMult(modifier)
    return modifier.DeclareFunctions and
      contains(MODIFIER_PROPERTY_BOUNTY_CREEP_MULTIPLIER, modifier:DeclareFunctions())
  end
  local function divBy100(num)
    return num / 100
  end
  local creepBountyMultiplier = iter(attacker:FindAllModifiers())
                                  :filter(HasCreepBountyMult)
                                  :map(compose(divBy100, CallMethod("GetModifierBountyCreepMultiplier")))
                                  :product()
  local newGoldBounty = math.floor(killedUnit:GetGoldBounty() * creepBountyMultiplier)
  killedUnit:SetMinimumGoldBounty(newGoldBounty)
  killedUnit:SetMaximumGoldBounty(newGoldBounty)

  -- PlayerResource:ModifyGold(playerID, goldBounty, false, DOTA_ModifyGold_CreepKill)
  -- if player then
  --   SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, killedUnit, goldBounty, player)
  -- end
end)
