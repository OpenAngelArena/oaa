
Sparks = Components:Register('Sparks', COMPONENT_STRATEGY)

function Sparks:Init()
  Debug:EnableDebugging()
  DebugPrint("Sparks:Init running!")
  Sparks.linkedModifiers = {}
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
    hasSpark = {}
  }

  CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)
  CustomGameEventManager:RegisterListener('select_spark', partial(Sparks.OnSelectSpark, Sparks))
end

function Sparks:OnSelectSpark (eventId, keys)
  Debug:EnableDebugging()
  DebugPrint(eventId)
  DebugPrintTable(keys)

  local playerId = keys.PlayerID
  local player = PlayerResource:GetPlayer(playerId)
  local spark = keys.spark

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

  if not Sparks.linkedModifiers[modifierName] then
    LinkLuaModifier(modifierName, "modifiers/sparks/" .. modifierName .. ".lua", LUA_MODIFIER_MOTION_NONE)
    Sparks.linkedModifiers[modifierName] = true
  end

  hero:AddNewModifier(hero, nil, modifierName, {})
end

function Sparks:ModifierName (spark)
  return 'modifier_spark_' .. spark
end
