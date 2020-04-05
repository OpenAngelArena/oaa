
function Spawn( entityKeyValues )
  if not IsServer() then
    return
  end

  if thisEntity == nil then
    return
  end

  thisEntity:SetContextThink( "CoreGuyThink", CoreGuyThink, 1 )
end

function CoreGuyThink ()
  if GameRules:IsGamePaused() == true or GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME or thisEntity:IsAlive() == false then
    return 1
  end

  if not thisEntity.bInitialized then
    thisEntity.vInitialSpawnPos = thisEntity:GetOrigin()
    thisEntity.bInitialized = true
    thisEntity.ability = thisEntity:FindAbilityByName("core_guy_score_limit") or thisEntity:FindAbilityByName("core_guy_points")
    thisEntity.ability:StartCooldown(thisEntity.ability:GetCooldownTime())
    thisEntity.corePoints = 0
  end

  if thisEntity:GetAbsOrigin() ~= thisEntity.vInitialSpawnPos then
    thisEntity:SetAbsOrigin(thisEntity.vInitialSpawnPos)
  end

  for itemIndex = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = thisEntity:GetItemInSlot(itemIndex)
    if item then
      local itemName = item:GetName()
      print(string.sub(itemName, 0, 17))
      if string.sub(itemName, 0, 17) ~= "item_upgrade_core" then
        thisEntity:DropItemAtPositionImmediate(item, thisEntity:GetAbsOrigin())
      else
        -- consume core and reap the mana
        local corePoints = 1
        if itemName == "item_upgrade_core_2" then
          corePoints = 2
        elseif itemName == "item_upgrade_core_3" then
          corePoints = 4
        elseif itemName == "item_upgrade_core_4" then
          corePoints = 8
        end
        item:Destroy()
        thisEntity.corePoints = thisEntity.corePoints + corePoints
      end
    end
  end

  local cooldown = thisEntity.ability:GetCooldownTimeRemaining()
  if cooldown > 0 and thisEntity.corePoints > 0 then
    print("before: " .. cooldown)
    cooldown = cooldown - (thisEntity.corePoints * 20)
    print("after: " .. cooldown)
    thisEntity.ability:EndCooldown()
    if cooldown > 0 then
      thisEntity.ability:StartCooldown(cooldown)
      thisEntity.corePoints = 0
    else
      thisEntity.corePoints = math.ceil(0 - cooldown) / 20
    end
  end

  return 1
end
