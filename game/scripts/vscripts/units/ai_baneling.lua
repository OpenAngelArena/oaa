local Baneling = class({})

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  if not thisEntity or not IsServer() then
    return
  end

  local newBaneling = Baneling()
  newBaneling:Init(thisEntity)
end

function Baneling:Init(entity)
  -- thisEntity
  self.entity = entity

  self.boom = self.entity:FindAbilityByName("spider_cold_combustion")

  Timers:CreateTimer(1, function()
    return self:Think()
  end)
end

function Baneling:Think()
  if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME or self.entity:IsNull() or not IsValidEntity(self.entity) or not self.entity:IsAlive() then
    return
  end

  if GameRules:IsGamePaused() then
    return 1
  end

  local targetLocation = self:FindBestBlastLocation()
  if not targetLocation then
    return 1
  end
  if targetLocation == true then
    ExecuteOrderFromTable({
      UnitIndex = self.entity:entindex(),
      OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
      AbilityIndex = self.boom:entindex()
    })
    return 1 -- incase we get interrupted
  end
  ExecuteOrderFromTable({
    UnitIndex = self.entity:entindex(),
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = targetLocation
  })

  return (targetLocation - self.entity:GetAbsOrigin()):Length2D() / 600
end

function Baneling:FindBestBlastLocation()
  local entity = self.entity
  local entity_location = entity:GetAbsOrigin()
  local flags = bit.bor(DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, DOTA_UNIT_TARGET_FLAG_NO_INVIS)
  local enemies = FindUnitsInRadius(entity:GetTeamNumber(), entity_location, nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, 0, false)
  local locations = {}

  local radius = 350
  for _,hero in ipairs(enemies) do
    local location = hero:GetAbsOrigin()
    locations[#locations + 1] = location
  end
  local function countEnemies (target)
    local count = 0
    for _,location in ipairs(locations) do
      if (target - location):Length2D() < radius then
        count = count + 1
      end
    end
    return count
  end

  local bestLocation = locations[1]
  local bestCount = 1

  for _,location in ipairs(locations) do
    for _,crossLocation in ipairs(locations) do
      local difference = (location - crossLocation)
      if difference:Length2D() < (radius * 2) then
        -- they're close enough...
        local testLocation = crossLocation + difference/2
        local enemyCount = countEnemies(testLocation)
        if enemyCount > bestCount then
          bestCount = enemyCount
          bestLocation = testLocation
        end
      end
    end
  end
  --if bestLocation then
    --print(tostring(bestLocation) .. " has the best unit count of " .. bestCount)
  --end
  local hpPercent = entity:GetHealth() / entity:GetMaxHealth()
  if bestCount <= (countEnemies(entity_location) * hpPercent) then
    --print('Blasting off now!')
    return true
  end
  return bestLocation
end
