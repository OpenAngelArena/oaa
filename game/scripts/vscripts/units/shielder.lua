
LinkLuaModifier( "modifier_boss_phase_controller", "modifiers/modifier_boss_phase_controller", LUA_MODIFIER_MOTION_NONE )

local ABILITY_shield = nil

local function HurtHandler (keys)
  --for k,v in pairs(keys) do print(k,v) end
  --[[
  [   VScript              ]: damagebits  0             --??
  [   VScript              ]: entindex_killed 499       --This units entity ID
  [   VScript              ]: damage  16.359998703003   --Amount of damage
  [   VScript              ]: entindex_attacker 438     --Attacker's Entity ID
  [   VScript              ]: splitscreenplayer -1      --??
  ]]
  local playerIndex = keys.entindex_attacker
  local damage = keys.damage
  local decayTime = 10
  local bossIndex = keys.entindex_killed

  -- add damage
  if not thisEntity.currentDamage then
    thisEntity.currentDamage = {}
  end
  if not thisEntity.currentDamage[playerIndex] then
    thisEntity.currentDamage[playerIndex] = damage
  else
    thisEntity.currentDamage[playerIndex] = thisEntity.currentDamage[playerIndex] + damage
  end
  Timers:CreateTimer(decayTime, function ()
    thisEntity.currentDamage[playerIndex] = thisEntity.currentDamage[playerIndex] - damage
  end)

  local maxDamage, key = -math.huge
  for k, v in pairs(thisEntity.currentDamage) do
    if v > maxDamage then
      maxDamage, key = v, k
    end
  end

  if thisEntity.currentDamage[playerIndex] == maxDamage then
    ExecuteOrderFromTable({
      UnitIndex = bossIndex,
      OrderType = DOTA_UNIT_ORDER_STOP,
      -- Position = nil
      Queue = 0
    })

    ExecuteOrderFromTable({
      UnitIndex = bossIndex,
      -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
      OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
      Position = EntIndexToHScript(playerIndex):GetAbsOrigin(),
      Queue = 1,
    })
  end
end

local function ShielderThink (thisEntity)
  thisEntity:OnHurt(HurtHandler)
end

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  thisEntity:FindAbilityByName("boss_shielder_shield")

  thisEntity:SetContextThink( "ShielderThink", partial(ShielderThink, thisEntity) , 1)
  print("Starting AI for " .. thisEntity:GetUnitName() .. " " .. thisEntity:GetEntityIndex())
  --Timers:CreateTimer(1, thisEntity:OnHurt(HurtHandler(keys)))

  ABILITY_shield = thisEntity:FindAbilityByName("boss_shielder_shield")

  local phaseController = thisEntity:AddNewModifier(thisEntity, ABILITY_shield, "modifier_boss_phase_controller", {})
  phaseController:SetPhases({ 66, 33 })
  phaseController:SetAbilities({
    "boss_shielder_shield"
  })
end
