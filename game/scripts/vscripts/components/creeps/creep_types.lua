
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_wolf",          600,  480,  35,   1.5,   40,  40}, -- expected gold is 100 and XP is 90
      {"npc_dota_neutral_custom_small_wolf",        400,    0,  15,   0.5,   30,  25},
      {"npc_dota_neutral_custom_small_wolf",        400,    0,  15,   0.5,   30,  25}
    },
    {
      {"npc_dota_neutral_custom_kobold_foreman",    560,  480,  16,    1,    40,  35},
      {"npc_dota_neutral_custom_kobold_soldier",    480,    0,  12,    1,    35,  30},
      {"npc_dota_neutral_custom_kobold",            280,    0,  10,   0.5,   25,  25}
    },
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_harpy_storm",       560,  400,  35,   1.2,   45,  82}, -- expected gold is 80 and XP is 143
      {"npc_dota_neutral_custom_harpy_scout",       480,    0,  40,   0.7,   40,  61}
    },
    {
      {"npc_dota_neutral_custom_mud_golem",         800,    0,  35,    1,    35,  57} -- multiply gold value by 2 and xp value by 2.5 because they split
    },
    {
      {"npc_dota_neutral_custom_blue_tomato",       800,  400,  35,   1.3,   45,  82},
      {"npc_dota_neutral_custom_blue_potato",       480,    0,  30,   1.3,   40,  61}
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_ghost",             800,  400,  40,   1.5,   75,  60}, -- expected gold is 147 and XP 120
      {"npc_dota_neutral_custom_ghost",             800,  400,  40,   1.5,   75,  60}
    },
    {
      {"npc_dota_neutral_custom_centaur_khan",      900,  400,  50,   1.5,   76,  60},
      {"npc_dota_neutral_custom_small_centaur",     500,    0,  30,    1,    37,  30},
      {"npc_dota_neutral_custom_small_centaur",     500,    0,  30,    1,    37,  30}
    },
    {
      {"npc_dota_neutral_satyr_hellcaller",         900,  480,  50,   1.5,   76,  53},
      {"npc_dota_neutral_satyr_soulstealer",        600,  480,  30,    1,    38,  40},
      {"npc_dota_neutral_satyr_trickster",          350,  480,  10,    1,    28,  27}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1400,    0,  50,    2,   100,  75}, -- expected gold is 200 and XP is 151
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    50,  38},
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    50,  38}
    },
    {
      {"npc_dota_neutral_prowler_shaman",          1700,  500,  90,    3,   200, 151}
    },
    {
      {"npc_dota_neutral_black_dragon",            1700,  500,  90,    3,   200, 151}
    }
  },
   -- 5 "solo ancient corner camp"
  {
    {
      {"npc_dota_neutral_custom_black_dragon",     1500,  500,  80,    3,   152, 156}
    }
  }
}
