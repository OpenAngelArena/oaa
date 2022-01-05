-- These values are starting and minimum values for neutral creeps when 5vs5; values increase over time (check creep_power.lua)
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_wolf",          480,  150,  35,   1.5,   30,  40}, -- expected gold is 70 and XP is 90
      {"npc_dota_neutral_custom_small_wolf",        320,    0,  15,   0.5,   20,  25},
      {"npc_dota_neutral_custom_small_wolf",        320,    0,  15,   0.5,   20,  25}
    },
    {
      {"npc_dota_neutral_custom_kobold_foreman",    450,  150,  30,    1,    30,  35},
      {"npc_dota_neutral_custom_kobold_soldier",    380,    0,  20,    1,    25,  30},
      {"npc_dota_neutral_custom_kobold",            250,    0,  10,   0.5,   15,  25}
    },
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_harpy_storm",       650,  300,  40,   1.3,   35,  82}, -- expected gold is 60 and XP is 143
      {"npc_dota_neutral_custom_harpy_scout",       400,    0,  30,     1,   25,  61}
    },
    {
      {"npc_dota_neutral_custom_mud_golem",         650,    0,  35,    1,    30,  57} -- multiply gold value by 2 and xp value by 2.5 because they split
    },
    {
      {"npc_dota_neutral_custom_blue_tomato",       650,  300,  40,   1.3,   35,  82},
      {"npc_dota_neutral_custom_blue_potato",       400,    0,  35,   1.3,   25,  61}
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_ghost",             800,    0,  35,   1.5,   50,  60}, -- expected gold is 100 and XP 120
      {"npc_dota_neutral_custom_ghost",             800,    0,  35,   1.5,   50,  60}
    },
    {
      {"npc_dota_neutral_custom_centaur_khan",      800,  300,  50,   1.5,   50,  60},
      {"npc_dota_neutral_custom_small_centaur",     400,    0,  30,    1,    25,  30},
      {"npc_dota_neutral_custom_small_centaur",     400,    0,  30,    1,    25,  30}
    },
    {
      {"npc_dota_neutral_satyr_hellcaller",         800,  400,  50,   1.5,   50,  53},
      {"npc_dota_neutral_satyr_soulstealer",        500,  600,  30,    1,    30,  40},
      {"npc_dota_neutral_satyr_trickster",          300,  500,  10,    1,    20,  27}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1275,    0,  50,    2,   120,  140} -- expected gold is 120 and XP is 140
    },
    {
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    1,    50,  140}
    },
    {
      {"npc_dota_neutral_black_dragon",            1275,  500,  80,    3,   120, 140}
    }
  },
   -- 5 "solo ancient corner camp"
  {
    {
      {"npc_dota_neutral_custom_black_dragon",     1500,  300,  80,    3,   100, 150}
    }
  },
   -- 6 "solo ancient mid camp"
  {
    {
      {"npc_dota_mini_roshan",                     1500,  300,  80,    3,   100, 150}
    }
  },
   -- 7 Solo Prowler
  {
    {
      {"npc_dota_neutral_prowler_shaman",          1275,  400,  80,    3,   100, 150}
    }
  }
}
