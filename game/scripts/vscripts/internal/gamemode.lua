-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:_InitGameMode()
  if GameMode._reentrantCheck then
    return
  end

  -- Setup rules
  GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
  GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
  GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
  GameRules:SetCustomGameSetupTimeout( CUSTOM_GAME_SETUP_TIME )
  -- SetHeroSelectionTime is ignored because "EnablePickRules"   "1" on addoninfo
  GameRules:SetHeroSelectionTime(CAPTAINS_MODE_TOTAL + 1)
  GameRules:SetHeroSelectPenaltyTime(10)
  GameRules:SetStrategyTime(35)
  GameRules:SetShowcaseTime(0)
  GameRules:SetPostGameTime( POST_GAME_TIME )
  GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
  if USE_CUSTOM_HERO_LEVELS then
    GameRules:SetUseCustomHeroXPValues(true)
    -- Start custom XP system
	end

  GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
  GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
  GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
  GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )
  GameRules:SetPreGameTime( PREGAME_TIME )

  GameRules:SetFirstBloodActive( ENABLE_FIRST_BLOOD )
  GameRules:SetHideKillMessageHeaders( HIDE_KILL_BANNERS )

  GameRules:SetCustomGameEndDelay( GAME_END_DELAY )
  GameRules:SetCustomVictoryMessageDuration( VICTORY_MESSAGE_DURATION )
  GameRules:SetStartingGold( STARTING_GOLD )

  if SKIP_TEAM_SETUP then
    GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
    GameRules:LockCustomGameSetupTeamAssignment( true )
    GameRules:EnableCustomGameSetupAutoLaunch( true )
  else
    GameRules:SetCustomGameSetupAutoLaunchDelay( AUTO_LAUNCH_DELAY )
    GameRules:LockCustomGameSetupTeamAssignment( LOCK_TEAM_SETUP )
    GameRules:EnableCustomGameSetupAutoLaunch( ENABLE_AUTO_LAUNCH )
  end

  -- This is multiteam configuration stuff
  if USE_AUTOMATIC_PLAYERS_PER_TEAM then
    local num = math.floor(10 / MAX_NUMBER_OF_TEAMS)
    local count = 0
    for team, number in pairs(TEAM_COLORS) do
      if count >= MAX_NUMBER_OF_TEAMS then
        GameRules:SetCustomGameTeamMaxPlayers(team, 0)
      else
        GameRules:SetCustomGameTeamMaxPlayers(team, num)
      end
      count = count + 1
    end
  else
    local count = 0
    for team, number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
      if count >= MAX_NUMBER_OF_TEAMS then
        GameRules:SetCustomGameTeamMaxPlayers(team, 0)
      else
        GameRules:SetCustomGameTeamMaxPlayers(team, number)
      end
      count = count + 1
    end
  end

  if USE_CUSTOM_TEAM_COLORS then
    for team, color in pairs(TEAM_COLORS) do
      SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
    end
  end
  DebugPrint('[BAREBONES] GameRules set')

  --InitLogFile( "log/barebones.txt","")

  -- Event Hooks
  ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
  ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, '_OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, '_OnConnectFull'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
  ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
  ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, '_OnGameRulesStateChange'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, '_OnNPCSpawned'), self)
  ListenToGameEvent('player_reconnected', Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)
  ListenToGameEvent('dota_item_combined', Dynamic_Wrap(GameMode, 'OnItemCombined'), self)
  ListenToGameEvent('dota_hero_swap', Dynamic_Wrap(GameMode, 'OnHeroSwapped'), self)

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '^0+','')
  math.randomseed(tonumber(timeTxt))

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')
  GameMode._reentrantCheck = true
  GameMode:InitGameMode()
  GameMode._reentrantCheck = false
end

CAPTURED_GAME_MODE_ALREADY = false

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:_CaptureGameMode()
  if not CAPTURED_GAME_MODE_ALREADY then
    CAPTURED_GAME_MODE_ALREADY = true
    -- Set GameMode parameters
    local mode = GameRules:GetGameModeEntity()
    mode:SetDraftingBanningTimeOverride(0)
    mode:SetDraftingHeroPickSelectTimeOverride(CAPTAINS_MODE_TOTAL + 1)
    mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
    mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
    mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
    mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
    mode:SetBuybackEnabled( BUYBACK_ENABLED )
    mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
    mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
    mode:SetUseCustomHeroLevels(USE_CUSTOM_XP_VALUES)
    mode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)

    mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
    mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

    mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
    mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )

    mode:SetAlwaysShowPlayerInventory( SHOW_ONLY_PLAYER_INVENTORY )
    mode:SetAnnouncerDisabled( DISABLE_ANNOUNCER )
    --if FORCE_PICKED_HERO then
      --mode:SetCustomGameForceHero( FORCE_PICKED_HERO )
    --end

    mode:SetFountainConstantManaRegen( FOUNTAIN_CONSTANT_MANA_REGEN )
    mode:SetFountainPercentageHealthRegen( FOUNTAIN_PERCENTAGE_HEALTH_REGEN )
    mode:SetFountainPercentageManaRegen( FOUNTAIN_PERCENTAGE_MANA_REGEN )
    mode:SetLoseGoldOnDeath( LOSE_GOLD_ON_DEATH )
    -- mode:SetMaximumAttackSpeed( MAXIMUM_ATTACK_SPEED )
    -- mode:SetMinimumAttackSpeed( MINIMUM_ATTACK_SPEED )
    mode:SetStashPurchasingDisabled ( DISABLE_STASH_PURCHASING )

    if USE_DEFAULT_RUNE_SYSTEM then
      mode:SetUseDefaultDOTARuneSpawnLogic(USE_DEFAULT_RUNE_SYSTEM)
    --else
      -- RuneSpawnFilter is broken
      --for rune, spawn in pairs(ENABLED_RUNES) do
        --mode:SetRuneEnabled(rune, spawn) -- this doesn't work for Arcane runes
      --end
      --mode:SetBountyRuneSpawnInterval(x) -- causes all runes to spawn at 0 and 2 and every x minutes no matter what x number is
      --mode:SetPowerRuneSpawnInterval(x) -- causes all runes to spawn at 0 and 2 and every x minutes no matter what x number is
      --GameRules:SetRuneSpawnTime(x) -- does literally nothing no matter what x number is
    end

    mode:SetUnseenFogOfWarEnabled( USE_UNSEEN_FOG_OF_WAR )
    mode:SetDaynightCycleDisabled( DISABLE_DAY_NIGHT_CYCLE )
    mode:SetKillingSpreeAnnouncerDisabled( DISABLE_KILLING_SPREE_ANNOUNCER )
    mode:SetStickyItemDisabled(false)
    mode:SetForceRightClickAttackDisabled(true)
    mode:SetCustomBackpackSwapCooldown(3.0)
    mode:SetDefaultStickyItem("item_aghanims_shard")
    --mode:DisableHudFlip(true)
    mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP, 20) -- Health per strength
    --mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_ALL_DAMAGE, 0.6) -- Damage per attribute for universal heroes

    self:OnFirstPlayerLoaded()
  end
end
