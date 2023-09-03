
Sparks = Components:Register('Sparks', COMPONENT_STRATEGY)

function Sparks:Init()
  --Debug:EnableDebugging()
  DebugPrint("Sparks:Init running!")

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

  GameEvents:OnHeroInGame(partial(Sparks.AddSparkOnHeroSpawn, Sparks))
  GameEvents:OnGameInProgress(partial(Sparks.CheckSparkOnAllPlayers, Sparks))
  Duels.onEnd(partial(Sparks.CheckSparkOnAllPlayers, Sparks))

  Timers:CreateTimer(1, function()
    return Sparks:DecreaseCooldowns()
  end)
end

function Sparks:AddSparkOnHeroSpawn(hero)
  if hero:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
    return
  end

  if hero:IsTempestDouble() or hero:IsClone() or hero:IsSpiritBearOAA() then
    return
  end

  -- Always add gpm spark to the spawned hero, gpm spark will remove itself if the hero is invalid
  if not hero:HasModifier("modifier_spark_gpm") then
    hero:AddNewModifier(hero, nil, "modifier_spark_gpm", {})
  end

  local playerid = hero:GetPlayerOwnerID()

  -- Check if spark is already assigned to this playerid;
  if Sparks.data.hasSpark[playerid] then
    -- During ARDM or after reconnecting spark can be assigned to the playerid but the hero itself doesn't have it
    Sparks:CheckSparkOnHeroEntity(hero, playerid)
    return
  end

  -- OnSelectSpark will do nothing for disconnected players
  Sparks:OnSelectSpark('asdf', {
    PlayerID = playerid,
    spark = "gpm",
    skipCooldown = true
  })
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
  local playerid = keys.PlayerID
  local player = PlayerResource:GetPlayer(playerid)

  -- OnSelectSpark will do nothing for disconnected players
  if not player then
    return
  end

  local spark = keys.spark

  if Sparks.data.cooldowns[playerid] and Sparks.data.cooldowns[playerid] > 0 then
    --DebugPrint('Spark changing on cooldown!')
    return
  end

  if spark ~= "gpm" and spark ~= "midas" and spark ~= "power" and spark ~= "cleave" then
    --DebugPrint('Invalid spark selection, what is a "' .. spark .. '"')
    return
  end

  -- If player chooses the first option (old gpm) it actually chooses a default spark for the hero
  if spark == "gpm" then
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    if not hero then
      return
    end
    spark = Sparks:FindDefaultSparkForHero(hero)
  end

  local oldSpark = Sparks.data.hasSpark[playerid]
  if oldSpark then
    --DebugPrint('They are changing their spark ' .. oldSpark .. ' to ' .. spark)
    Sparks.data[player:GetTeam()][oldSpark] = Sparks.data[player:GetTeam()][oldSpark] - 1
  end

  -- Assign the spark to the playerid
  Sparks.data.hasSpark[playerid] = spark

  -- Go on cooldown only if not skipped and new spark is different from the old one
  if not keys.skipCooldown and spark ~= oldSpark then
    Sparks.data.cooldowns[playerid] = 60
  end

  Sparks.data[player:GetTeam()][spark] = Sparks.data[player:GetTeam()][spark] + 1

  CustomNetTables:SetTableValue('hero_selection', 'team_sparks', Sparks.data)

  Sparks:CheckSparkOnPlayer(playerid)
end

-- Ensure that everyone has a spark
function Sparks:CheckSparkOnAllPlayers(keys)
  PlayerResource:GetAllTeamPlayerIDs():each(function(playerid)
    -- Check if spark is already assigned to this playerid; Player maybe already selected a spark
    if not Sparks.data.hasSpark[playerid] then
      -- OnSelectSpark will do nothing for disconnected players
      Sparks:OnSelectSpark("asdf", {
        PlayerID = playerid,
        spark = "gpm",
        skipCooldown = true
      })
    end

    -- CheckSparkOnPlayer works for disconnected players
    Sparks:CheckSparkOnPlayer(playerid)
  end)
end

function Sparks:CheckSparkOnPlayer(playerid)
  local hero = PlayerResource:GetSelectedHeroEntity(playerid)
  Sparks:CheckSparkOnHeroEntity(hero, playerid)
end

function Sparks:CheckSparkOnHeroEntity(hero, playerid)
  if not hero then
    Debug:EnableDebugging()
    DebugPrint("Sparks:CheckSparkOnHeroEntity - Player "..playerid.." has no hero!")
    return
  end

  -- Failsafe check if the hero has gpm spark
  if not hero:HasModifier("modifier_spark_gpm") then
    hero:AddNewModifier(hero, nil, "modifier_spark_gpm", {})
  end

  local spark = Sparks.data.hasSpark[playerid]
  if not spark then
    Debug:EnableDebugging()
    DebugPrint("Sparks:CheckSparkOnHeroEntity - Player "..playerid.." has not selected a spark!") -- this will happen for disconnected players
    spark = Sparks:FindDefaultSparkForHero(hero)
  end

  local modifierName = self:ModifierName(spark)

  -- Check if this hero already has the assigned spark
  if hero:HasModifier(modifierName) then
    return
  end

  -- Purge the other spark modifiers
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

  -- Check if the hero is alive, if not wait until it is and then add the spark modifier
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
    npc_dota_hero_abaddon = "midas",
    npc_dota_hero_abyssal_underlord = "cleave",
    npc_dota_hero_alchemist = "cleave",
    npc_dota_hero_ancient_apparition = "midas",
    npc_dota_hero_antimage = "cleave",
    npc_dota_hero_arc_warden = "cleave",
    npc_dota_hero_axe = "power",
    npc_dota_hero_bane = "midas",
    npc_dota_hero_batrider = "midas",
    npc_dota_hero_beastmaster = "power",
    npc_dota_hero_bloodseeker = "cleave",
    npc_dota_hero_bounty_hunter = "midas",
    npc_dota_hero_brewmaster = "midas",
    npc_dota_hero_bristleback = "power",
    npc_dota_hero_broodmother = "power",
    npc_dota_hero_centaur = "midas",
    npc_dota_hero_chaos_knight = "cleave",
    npc_dota_hero_chen = "power",
    npc_dota_hero_clinkz = "cleave",
    npc_dota_hero_crystal_maiden = "midas",
    npc_dota_hero_dark_seer = "power",
    npc_dota_hero_dark_willow = "cleave",
    npc_dota_hero_dawnbreaker = "power",
    npc_dota_hero_dazzle = "midas",
    npc_dota_hero_death_prophet = "midas",
    npc_dota_hero_disruptor = "midas",
    npc_dota_hero_doom_bringer = "cleave",
    npc_dota_hero_dragon_knight = "cleave",
    npc_dota_hero_drow_ranger = "cleave",
    npc_dota_hero_earth_spirit = "midas",
    npc_dota_hero_earthshaker = "midas",
    npc_dota_hero_elder_titan = "midas",
    npc_dota_hero_electrician = "midas",
    npc_dota_hero_ember_spirit = "power",
    npc_dota_hero_enchantress = "midas",
    npc_dota_hero_enigma = "power",
    npc_dota_hero_faceless_void = "cleave",
    npc_dota_hero_furion = "power",
    npc_dota_hero_grimstroke = "midas",
    npc_dota_hero_gyrocopter = "cleave",
    npc_dota_hero_hoodwink = "cleave",
    npc_dota_hero_huskar = "cleave",
    npc_dota_hero_invoker = "midas",
    npc_dota_hero_jakiro = "midas",
    npc_dota_hero_juggernaut = "cleave",
    npc_dota_hero_keeper_of_the_light = "midas",
    npc_dota_hero_kunkka = "cleave",
    npc_dota_hero_legion_commander = "cleave",
    npc_dota_hero_leshrac = "cleave",
    npc_dota_hero_lich = "midas",
    npc_dota_hero_life_stealer = "cleave",
    npc_dota_hero_lina = "midas",
    npc_dota_hero_lion = "midas",
    npc_dota_hero_lone_druid = "power",
    npc_dota_hero_luna = "cleave",
    npc_dota_hero_lycan = "power",
    npc_dota_hero_magnataur = "power",
    npc_dota_hero_marci = "power",
    npc_dota_hero_mars = "power",
    npc_dota_hero_medusa = "cleave",
    npc_dota_hero_meepo = "power",
    npc_dota_hero_mirana = "midas",
    npc_dota_hero_monkey_king = "power",
    npc_dota_hero_morphling = "cleave",
    npc_dota_hero_muerta = "cleave",
    npc_dota_hero_naga_siren = "power",
    npc_dota_hero_necrolyte = "cleave",
    npc_dota_hero_nevermore = "cleave",
    npc_dota_hero_night_stalker = "power",
    npc_dota_hero_nyx_assassin = "midas",
    npc_dota_hero_obsidian_destroyer = "cleave",
    npc_dota_hero_ogre_magi = "midas",
    npc_dota_hero_omniknight = "midas",
    npc_dota_hero_oracle = "midas",
    npc_dota_hero_pangolier = "power",
    npc_dota_hero_phantom_assassin = "cleave",
    npc_dota_hero_phantom_lancer = "power",
    npc_dota_hero_phoenix = "midas",
    npc_dota_hero_primal_beast = "cleave",
    npc_dota_hero_puck = "midas",
    npc_dota_hero_pudge = "midas",
    npc_dota_hero_pugna = "midas",
    npc_dota_hero_queenofpain = "midas",
    npc_dota_hero_rattletrap = "midas",
    npc_dota_hero_razor = "cleave",
    npc_dota_hero_riki = "cleave",
    npc_dota_hero_rubick = "midas",
    npc_dota_hero_sand_king = "power",
    npc_dota_hero_shadow_demon = "midas",
    npc_dota_hero_shadow_shaman = "midas",
    npc_dota_hero_shredder = "midas",
    npc_dota_hero_silencer = "midas",
    npc_dota_hero_skeleton_king = "power",
    npc_dota_hero_skywrath_mage = "midas",
    npc_dota_hero_slardar = "power",
    npc_dota_hero_slark = "cleave",
    npc_dota_hero_snapfire = "cleave",
    npc_dota_hero_sniper = "cleave",
    npc_dota_hero_sohei = "cleave",
    npc_dota_hero_spectre = "power",
    npc_dota_hero_spirit_breaker = "midas",
    npc_dota_hero_storm_spirit = "cleave",
    npc_dota_hero_sven = "power",
    npc_dota_hero_techies = "midas",
    npc_dota_hero_templar_assassin = "cleave",
    npc_dota_hero_terrorblade = "power",
    npc_dota_hero_tidehunter = "power",
    npc_dota_hero_tinker = "midas",
    npc_dota_hero_tiny = "cleave",
    npc_dota_hero_treant = "midas",
    npc_dota_hero_troll_warlord = "cleave",
    npc_dota_hero_tusk = "midas",
    npc_dota_hero_undying = "power",
    npc_dota_hero_ursa = "cleave",
    npc_dota_hero_vengefulspirit = "midas",
    npc_dota_hero_venomancer = "power",
    npc_dota_hero_viper = "cleave",
    npc_dota_hero_visage = "midas",
    npc_dota_hero_void_spirit = "cleave",
    npc_dota_hero_warlock = "midas",
    npc_dota_hero_weaver = "cleave",
    npc_dota_hero_windrunner = "cleave",
    npc_dota_hero_winter_wyvern = "cleave",
    npc_dota_hero_wisp = "midas",
    npc_dota_hero_witch_doctor = "midas",
    npc_dota_hero_zuus = "midas",
  }

  if (OAAOptions and OAAOptions.settings and OAAOptions.settings.small_player_pool == 1) or GetMapName() == "1v1" then
    if default_sparks[hero_name] == "midas" then
      return "cleave"
    end
  end

  if default_sparks[hero_name] ~= nil then
    return default_sparks[hero_name]
  end

  return "cleave"
end
