
if BountyRunePick == nil then
  --Debug:EnableDebugging()
  DebugPrint('Creating new BountyRunePick object')
  BountyRunePick = class({})
end

function BountyRunePick:Init()
  self.moduleName = "BountyRunePick Filter"
  FilterManager:AddFilter(FilterManager.BountyRunePickup, self, Dynamic_Wrap(BountyRunePick, 'Filter'))
end

function BountyRunePick:Filter(filter_table)
  --local vanilla_gold_bounty = filter_table.gold_bounty
  local playerID = filter_table.player_id_const

  -- Game time in seconds:
  local game_time = HudTimer:GetGameTime()
  game_time = game_time - (game_time % 120)
  -- Game time in minutes:
  game_time = math.floor(game_time / 60)
  -- start at 1 minute instead of 0
  if game_time < 1 then
    --DebugPrint('Using minute 1 rune instead')
    game_time = 1.8
  end
  --DebugPrint('Game time is ' .. tostring(game_time))
  -- Hero that picked up the rune
  local hero_with_rune = PlayerResource:GetSelectedHeroEntity(playerID)
  -- Team that picked up the rune
  local allied_team
  if hero_with_rune then
    allied_team = hero_with_rune:GetTeamNumber()
  else
    print("Invalid unit picked up the bounty rune!")
  end

  local enemy_team
  if allied_team == DOTA_TEAM_GOODGUYS then
    enemy_team = DOTA_TEAM_BADGUYS
  elseif allied_team == DOTA_TEAM_BADGUYS then
    enemy_team = DOTA_TEAM_GOODGUYS
  else
    print("Invalid team picked up the bounty rune!")
    return false
  end

  -- Player team IDs iterators
  local allied_player_ids = PlayerResource:GetPlayerIDsForTeam(allied_team)
  local enemy_player_ids = PlayerResource:GetPlayerIDsForTeam(enemy_team)

  local AlliedTeamGold = 0
  local AlliedTeamXP = 0
  local EnemyTeamGold = 0
  local EnemyTeamXP = 0

  allied_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    --AlliedTeamXP = AlliedTeamXP + PlayerResource:GetTotalEarnedXP(playerid)
    if hero then
      AlliedTeamGold = AlliedTeamGold + hero:GetNetworth()
      AlliedTeamXP = AlliedTeamXP + hero:GetCurrentXP()
    end
  end)

  enemy_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    --EnemyTeamXP = EnemyTeamXP + PlayerResource:GetTotalEarnedXP(playerid)
    if hero then
      EnemyTeamGold = EnemyTeamGold + hero:GetNetworth()
      EnemyTeamXP = EnemyTeamXP + hero:GetCurrentXP()
    end
  end)

  local gold_diff = (EnemyTeamGold - AlliedTeamGold) / (EnemyTeamGold + AlliedTeamGold)
  local xp_diff = 0
  if (EnemyTeamXP + AlliedTeamXP) > 0 then
    xp_diff = (EnemyTeamXP - AlliedTeamXP) / (EnemyTeamXP + AlliedTeamXP)
  end
  local gold_difference = math.max(0, gold_diff)
  local xp_difference = math.max(0, xp_diff)

  local gold_reward = (BOUNTY_RUNE_INITIAL_TEAM_GOLD*game_time*(1 + (1 - (1 - gold_difference)*(1 - gold_difference))*game_time/12)) - (10 * (game_time)/(game_time+0.3))
  local xp_reward = (BOUNTY_RUNE_INITIAL_TEAM_XP*game_time*(1 + (1 - (1 - xp_difference)*(1 - xp_difference))*game_time/12)) - (10 * (game_time)/(game_time+0.3))
  --gold_reward = math.max(vanilla_gold_bounty, gold_reward)
  xp_reward = math.ceil(xp_reward)

  allied_player_ids:each(function (playerid)
    local hero = PlayerResource:GetSelectedHeroEntity(playerid)
    local player = PlayerResource:GetPlayer(playerid)

    if hero then
      if xp_reward > 0 then
        -- Calculate bonus xp rewards
        local bonus_xp = 0

        -- Check for XP spark
        local xp_spark = hero:FindModifierByName("modifier_spark_xp")
        if xp_spark then
          local multiplier = xp_spark.bounty_rune_bonus_xp
          if multiplier and multiplier > 1 then
            bonus_xp = bonus_xp + math.floor((multiplier-1)*xp_reward)
          end
        end

        hero:AddExperience(bonus_xp + xp_reward, DOTA_ModifyXP_Unspecified, false, true)
        SendOverheadEventMessage(player, OVERHEAD_ALERT_XP, hero, bonus_xp + xp_reward, nil)
      end
      if gold_reward > 0 then
        -- Calculate bonus gold rewards
        local bonus_gold = 0

        -- Check for Alchemist Greevil's Greed bounty rune gold multiplier
        local alchemist_ability = hero:FindAbilityByName("alchemist_goblins_greed")
        if alchemist_ability then
          local alchemist_ability_level = alchemist_ability:GetLevel()
          if alchemist_ability_level > 0 then
            local multiplier = alchemist_ability:GetLevelSpecialValueFor("bounty_multiplier", alchemist_ability_level-1)
            if multiplier and multiplier > 1 then
              bonus_gold = bonus_gold + math.floor((multiplier-1)*gold_reward)
            end
          end
        end

        -- Check for Gold spark
        local gold_spark = hero:FindModifierByName("modifier_spark_gold")
        if gold_spark then
          local multiplier = gold_spark.bounty_rune_bonus_gold
          if multiplier and multiplier > 1 then
            bonus_gold = bonus_gold + math.floor((multiplier-1)*gold_reward)
          end
        end

        -- if filter_table.gold_bounty doesn't work change 'bonus_gold` to 'bonus_gold + gold_reward'
        Gold:ModifyGold(playerid, bonus_gold, true, DOTA_ModifyGold_BountyRune)
        SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, gold_reward + bonus_gold, nil)
      end
    end
  end)

  filter_table.gold_bounty = gold_reward

  return true
end
