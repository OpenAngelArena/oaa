
Sparks = Components:Register('Sparks', COMPONENT_STRATEGY)

function Sparks:Init()
  Debug:EnableDebugging()
  DebugPrint("Sparks:Init running!")

  LinkLuaModifier("modifier_spark_cleave", "modifiers/sparks/modifier_spark_cleave.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_gpm", "modifiers/sparks/modifier_spark_gpm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_midas", "modifiers/sparks/modifier_spark_midas.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_power", "modifiers/sparks/modifier_spark_power.lua", LUA_MODIFIER_MOTION_NONE)

  Sparks.data = {
    [DOTA_TEAM_GOODGUYS] = {
      gpm = 0,
      midas = 0,
      power = 0,
      cleave = 0
    },
    [DOTA_TEAM_BADGUYS] = {
      gpm = 0,
      midas = 0,
      power = 0,
      cleave = 0
    },
    hasSpark = {},
    cooldowns = {}
  }

  CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)
  CustomGameEventManager:RegisterListener('select_spark', partial(Sparks.OnSelectSpark, Sparks))

  Timers:CreateTimer(1, function()
    return Sparks:DecreaseCooldowns()
  end)
end

function Sparks:DecreaseCooldowns ()
  local didSomething = false

  for playerId,cooldown in pairs(Sparks.data.cooldowns) do
    if cooldown < 0 then
      cooldown = 0
      didSomething = true
    end
    if cooldown > 0 then
      cooldown = cooldown - 1
      didSomething = true
    end

    Sparks.data.cooldowns[playerId] = cooldown
  end

  if didSomething then
    CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)
  end

  return 1
end

function Sparks:OnSelectSpark (eventId, keys)
  -- Debug:EnableDebugging()
  DebugPrint(eventId)
  DebugPrintTable(keys)

  local playerId = keys.PlayerID
  local player = PlayerResource:GetPlayer(playerId)
  local spark = keys.spark

  if Sparks.data.cooldowns[playerId] and Sparks.data.cooldowns[playerId] > 0 then
    DebugPrint('Spark changing on cooldown!')
    return
  end

  if spark ~= "gpm" and spark ~= "midas" and spark ~= "power" and spark ~= "cleave" then
    DebugPrint('Invalid spark selection, what is a "' .. spark .. '"')
    return
  end
  local oldSpark = Sparks.data.hasSpark[playerId]
  if oldSpark then
    DebugPrint('They are changing their spark ' .. oldSpark .. ' to ' .. spark)
    Sparks.data[player:GetTeam()][oldSpark] = Sparks.data[player:GetTeam()][oldSpark] - 1
  end

  Sparks.data.hasSpark[playerId] = spark
  Sparks.data.cooldowns[playerId] = 60
  Sparks.data[player:GetTeam()][spark] = Sparks.data[player:GetTeam()][spark] + 1

  CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)

  Sparks:CheckSparkOnHero(playerId)
end

function Sparks:CheckSparkOnHero (playerId)
  local spark = Sparks.data.hasSpark[playerId]
  if not spark then
    Debug:EnableDebugging()
    DebugPrint('This player has not selected a spark!')
    return
  end
  local player = PlayerResource:GetPlayer(playerId)
  if not player then
    Debug:EnableDebugging()
    DebugPrint('This player has no player!')
    return
  end
  local hero = PlayerResource:GetSelectedHeroEntity(playerId)
  if not hero then
    Debug:EnableDebugging()
    DebugPrint('This player has no hero!')
    return
  end

  if hero:HasModifier(self:ModifierName(spark)) then
    return
  end
  -- purge the other modifiers

  if spark ~= "gpm" then
    hero:RemoveModifierByName(self:ModifierName("gpm"))
  end
  if spark ~= "midas" then
    hero:RemoveModifierByName(self:ModifierName("midas"))
  end
  if spark ~= "power" then
    hero:RemoveModifierByName(self:ModifierName("power"))
  end
  if spark ~= "cleave" then
    hero:RemoveModifierByName(self:ModifierName("cleave"))
  end
  local modifierName = self:ModifierName(spark)

  if hero:IsAlive() then
    hero:AddNewModifier(hero, nil, modifierName, {})
  else
    Timers:CreateTimer(0.1, function()
      if hero:IsAlive() then
        hero:AddNewModifier(hero, nil, modifierName, {})
      else
        return 0.1
      end
    end)
  end
end

function Sparks:ModifierName (spark)
  return 'modifier_spark_' .. spark
end
