
Sparks = Components:Register('Sparks', COMPONENT_STRATEGY)

function Sparks:Init()
  --Debug:EnableDebugging()
  DebugPrint("Sparks:Init running!")

  LinkLuaModifier("modifier_spark_gpm", "modifiers/sparks/modifier_spark_gpm.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_cleave", "modifiers/sparks/modifier_spark_cleave.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_midas", "modifiers/sparks/modifier_spark_midas.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_power", "modifiers/sparks/modifier_spark_power.lua", LUA_MODIFIER_MOTION_NONE)
  LinkLuaModifier("modifier_spark_power_effect", "modifiers/sparks/modifier_spark_power.lua", LUA_MODIFIER_MOTION_NONE)
  --LinkLuaModifier("modifier_spark_xp", "modifiers/sparks/modifier_spark_xp.lua", LUA_MODIFIER_MOTION_NONE)
  --LinkLuaModifier("modifier_spark_gold", "modifiers/sparks/modifier_spark_gold.lua", LUA_MODIFIER_MOTION_NONE)

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

  GameEvents:OnHeroInGame(Sparks.SelectDefaultSpark)
  GameEvents:OnGameInProgress(Sparks.EnsureHeroSparks)
  Duels.onEnd(Sparks.EnsureHeroSparks)

  Timers:CreateTimer(1, function()
    return Sparks:DecreaseCooldowns()
  end)
end

function Sparks.EnsureHeroSparks ()
  Sparks:CheckSparkOnHeroes()
end

function Sparks.SelectDefaultSpark (hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end
  local playerId = hero:GetPlayerOwnerID()
  if Sparks.data.hasSpark[playerId] then
    return
  end
  if hero:IsTempestDouble() or hero:IsClone() then
    return
  end

  if not hero:HasModifier("modifier_spark_gpm") then
    hero:AddNewModifier(hero, nil, "modifier_spark_gpm", {})
  end

  local spark_name = Sparks:FindDefaultSparkForHero(hero)

  Sparks:OnSelectSpark('asdf', {
    PlayerID = playerId,
    spark = spark_name,
    skipCooldown = true
  })
  --Sparks:CheckSparkOnHeroEntity(hero)
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
  local playerId = keys.PlayerID
  local player = PlayerResource:GetPlayer(playerId)
  if not player then
    return
  end

  local spark = keys.spark

  if Sparks.data.cooldowns[playerId] and Sparks.data.cooldowns[playerId] > 0 then
    --DebugPrint('Spark changing on cooldown!')
    return
  end

  if spark ~= "gpm" and spark ~= "midas" and spark ~= "power" and spark ~= "cleave" then
    --DebugPrint('Invalid spark selection, what is a "' .. spark .. '"')
    return
  end

  -- If player chooses the first option (old gpm) it actually chooses a default spark for his hero
  if spark == "gpm" then
    local hero = PlayerResource:GetSelectedHeroEntity(playerId)
    spark = Sparks:FindDefaultSparkForHero(hero)
  end

  local oldSpark = Sparks.data.hasSpark[playerId]
  if oldSpark then
    --DebugPrint('They are changing their spark ' .. oldSpark .. ' to ' .. spark)
    Sparks.data[player:GetTeam()][oldSpark] = Sparks.data[player:GetTeam()][oldSpark] - 1
  end

  Sparks.data.hasSpark[playerId] = spark
  if not keys.skipCooldown then
    Sparks.data.cooldowns[playerId] = 60
  end
  Sparks.data[player:GetTeam()][spark] = Sparks.data[player:GetTeam()][spark] + 1

  CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)

  Sparks:CheckSparkOnHero(playerId)
end

function Sparks:CheckSparkOnHeroes ()
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerId)
    if not Sparks.data.hasSpark[playerId] then
      local hero = PlayerResource:GetSelectedHeroEntity(playerId)
      local spark_name = "cleave"
      if hero then
        spark_name = Sparks:FindDefaultSparkForHero(hero)
      end
      Sparks:OnSelectSpark("asdf", {
        PlayerID = playerId,
        spark = spark_name,
        skipCooldown = true
      })
    end

    Sparks:CheckSparkOnHero(playerId)
  end)
end

function Sparks:CheckSparkOnHero (playerId)
  local hero = PlayerResource:GetSelectedHeroEntity(playerId)
  return Sparks:CheckSparkOnHeroEntity(hero)
end

function Sparks:CheckSparkOnHeroEntity (hero)
  if not hero then
    Debug:EnableDebugging()
    DebugPrint('This player has no hero!')
    return
  end
  local playerId = hero:GetPlayerOwnerID()
  local spark = Sparks.data.hasSpark[playerId]
  if not spark then
    --Debug:EnableDebugging()
    --DebugPrint('This player has not selected a spark!')
    return
  end
  local player = PlayerResource:GetPlayer(playerId)
  if not player then
    Debug:EnableDebugging()
    DebugPrint('This player has no player!')
    return
  end

  if not hero:HasModifier("modifier_spark_gpm") then
    hero:AddNewModifier(hero, nil, "modifier_spark_gpm", {})
  end

  if hero:HasModifier(self:ModifierName(spark)) then
    return
  end
  -- purge the other modifiers

  --if spark ~= "gpm" then
    --hero:RemoveModifierByName(self:ModifierName("gpm"))
  --end
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
  --if spark == "gpm" then
    --return "modifier_spark_gold"
  --end
  --if spark == "midas" then
    --return "modifier_spark_xp"
  --end
  return 'modifier_spark_' .. spark
end

function Sparks:FindDefaultSparkForHero(hero)
  local hero_name = hero:GetUnitName()
  local default_sparks = {
    npc_dota_hero_ancient_apparition = "midas",
    npc_dota_hero_bane = "midas",
    npc_dota_hero_axe = "midas",
    npc_dota_hero_beastmaster = "midas",
    npc_dota_hero_chen = "midas",
    npc_dota_hero_crystal_maiden = "midas",
    npc_dota_hero_dark_seer = "midas",
    npc_dota_hero_dazzle = "midas",
    npc_dota_hero_dark_willow = "midas",
    npc_dota_hero_doom_bringer = "midas",
    npc_dota_hero_earthshaker = "midas",
    npc_dota_hero_enchantress = "midas",
    npc_dota_hero_enigma = "midas",
    npc_dota_hero_leshrac = "midas",
    npc_dota_hero_lich = "midas",
    npc_dota_hero_lina = "midas",
    npc_dota_hero_lion = "midas",
    npc_dota_hero_mirana = "midas",
    npc_dota_hero_necrolyte = "midas",
    npc_dota_hero_night_stalker = "midas",
    npc_dota_hero_omniknight = "midas",
    npc_dota_hero_puck = "midas",
    npc_dota_hero_pudge = "midas",
    npc_dota_hero_pugna = "midas",
    npc_dota_hero_rattletrap = "midas",
    npc_dota_hero_sand_king = "midas",
    npc_dota_hero_shadow_shaman = "midas",
    npc_dota_hero_slardar = "midas",
    npc_dota_hero_vengefulspirit = "midas",
    npc_dota_hero_venomancer = "midas",
    npc_dota_hero_windrunner = "midas",
    npc_dota_hero_witch_doctor = "midas",
    npc_dota_hero_zuus = "midas",
    npc_dota_hero_queenofpain = "midas",
    npc_dota_hero_jakiro = "midas",
    npc_dota_hero_batrider = "midas",
    npc_dota_hero_warlock = "midas",
    npc_dota_hero_death_prophet = "midas",
    npc_dota_hero_bounty_hunter = "midas",
    npc_dota_hero_silencer = "midas",
    npc_dota_hero_spirit_breaker = "midas",
    npc_dota_hero_invoker = "midas",
    npc_dota_hero_shadow_demon = "midas",
    npc_dota_hero_brewmaster = "midas",
    npc_dota_hero_treant = "midas",
    npc_dota_hero_ogre_magi = "midas",
    npc_dota_hero_rubick = "midas",
    npc_dota_hero_wisp = "midas",
    npc_dota_hero_disruptor = "midas",
    npc_dota_hero_undying = "midas",
    npc_dota_hero_nyx_assassin = "midas",
    npc_dota_hero_keeper_of_the_light = "midas",
    npc_dota_hero_visage = "midas",
    npc_dota_hero_centaur = "midas",
    npc_dota_hero_shredder = "midas",
    npc_dota_hero_tusk = "midas",
    npc_dota_hero_bristleback = "midas",
    npc_dota_hero_skywrath_mage = "midas",
    npc_dota_hero_elder_titan = "midas",
    npc_dota_hero_abaddon = "midas",
    npc_dota_hero_earth_spirit = "midas",
    npc_dota_hero_phoenix = "midas",
    npc_dota_hero_techies = "midas",
    npc_dota_hero_oracle = "midas",
    npc_dota_hero_winter_wyvern = "midas",
    npc_dota_hero_abyssal_underlord = "midas",
    npc_dota_hero_electrician = "midas",
    npc_dota_hero_grimstroke = "midas",
    npc_dota_hero_snapfire = "midas",
    npc_dota_hero_hoodwink = "midas",
    npc_dota_hero_dawnbreaker = "midas",
    npc_dota_hero_antimage = "cleave",
    npc_dota_hero_arc_warden = "cleave",
    npc_dota_hero_bloodseeker = "cleave",
    npc_dota_hero_dragon_knight = "cleave",
    npc_dota_hero_drow_ranger = "cleave",
    npc_dota_hero_faceless_void = "cleave",
    npc_dota_hero_furion = "cleave",
    npc_dota_hero_juggernaut = "cleave",
    npc_dota_hero_kunkka = "cleave",
    npc_dota_hero_life_stealer = "cleave",
    npc_dota_hero_morphling = "cleave",
    npc_dota_hero_nevermore = "cleave",
    npc_dota_hero_razor = "cleave",
    npc_dota_hero_riki = "cleave",
    npc_dota_hero_sniper = "cleave",
    npc_dota_hero_spectre = "cleave",
    npc_dota_hero_storm_spirit = "cleave",
    npc_dota_hero_sven = "cleave",
    npc_dota_hero_tinker = "cleave",
    npc_dota_hero_tiny = "cleave",
    npc_dota_hero_viper = "cleave",
    npc_dota_hero_weaver = "cleave",
    npc_dota_hero_broodmother = "cleave",
    npc_dota_hero_skeleton_king = "cleave",
    npc_dota_hero_huskar = "cleave",
    npc_dota_hero_alchemist = "cleave",
    npc_dota_hero_ursa = "cleave",
    npc_dota_hero_obsidian_destroyer = "cleave",
    npc_dota_hero_lycan = "cleave",
    npc_dota_hero_lone_druid = "power",
    npc_dota_hero_chaos_knight = "cleave",
    npc_dota_hero_phantom_assassin = "cleave",
    npc_dota_hero_gyrocopter = "cleave",
    npc_dota_hero_luna = "cleave",
    npc_dota_hero_templar_assassin = "cleave",
    npc_dota_hero_meepo = "cleave",
    npc_dota_hero_monkey_king = "cleave",
    npc_dota_hero_magnataur = "cleave",
    npc_dota_hero_slark = "cleave",
    npc_dota_hero_medusa = "cleave",
    npc_dota_hero_troll_warlord = "cleave",
    npc_dota_hero_ember_spirit = "cleave",
    npc_dota_hero_legion_commander = "cleave",
    npc_dota_hero_sohei = "cleave",
    npc_dota_hero_void_spirit = "cleave",
    npc_dota_hero_clinkz = "power",
    npc_dota_hero_mars = "power",
    npc_dota_hero_pangolier = "power",
    npc_dota_hero_tidehunter = "power",
    npc_dota_hero_phantom_lancer = "power",
    npc_dota_hero_naga_siren = "power",
    npc_dota_hero_terrorblade = "power",
  }

  if OAAOptions and OAAOptions.settings then
    if OAAOptions.settings.small_player_pool == 1 then
      if default_sparks[hero_name] == "midas" then
        return "cleave"
      end
    end
  end

  if default_sparks[hero_name] ~= nil then
    return default_sparks[hero_name]
  end

  return "cleave"
end
