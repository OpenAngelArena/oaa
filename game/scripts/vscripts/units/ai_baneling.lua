local Baneling = class({})

function Spawn (entityKeyValues) --luacheck: ignore Spawn
  local newBaneling = Baneling()
  newBaneling:Init(thisEntity)
end

function Baneling:Init(entity)
  -- thisEntity
  self.entity = entity

  self.boom =  self.entity:FindAbilityByName("boss_spiders_spider_cold_combustion")

  Timers:CreateTimer(1, function()
    return self:Think()
  end)
end

function Baneling:Think()
  if self.entity:IsNull() or not self.entity:IsAlive() then
    return
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
  local flags = DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS
  local enemies = FindUnitsInRadius( self.entity:GetTeamNumber(), self.entity:GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, flags, 0, false )
  local locations = {}
  local myLocation = self.entity:GetAbsOrigin()
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

  print(tostring(bestLocation) .. " has the best unit count of " .. bestCount)
  local hpPercent = self.entity:GetHealth() / self.entity:GetMaxHealth()
  if bestCount <= (countEnemies(myLocation) * hpPercent) then
    print('Blasting off now!')
    return true
  end
  return bestLocation
end
