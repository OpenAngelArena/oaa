
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  14}, --expected gold is 70 and XP is 37
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    30,  24}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    44,  22},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  14}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    44,  22},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  14}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    60,  19},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    60,  19}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  49}, --expected gold is 94 and XP is 86
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  49},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,    1,    32,  23},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  49}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,    2,    47,  43},
      {"npc_dota_neutral_beardude",                 800,    0,  28,    2,    47,  43},
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_horse",        1100,  400,  30,    2,    90,  31}, --expected gold is 140 and XP is 62
      {"npc_dota_neutral_custom_small_horse",       700,  240,  20,    1,    50,  31},
    },
    {
      {"npc_dota_neutral_custom_big_horse",        1100,  400,  30,    2,    90,  31},
      {"npc_dota_neutral_custom_small_horse",       700,  240,  20,    1,    50,  31},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  21},
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  21},
      {"npc_dota_neutral_custom_big_pupper",        700,  480,  35,    3,   100,  34}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  21},
      {"npc_dota_neutral_custom_big_pupper",        700,  480,  35,    3,   100,  34}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  21},
      {"npc_dota_neutral_custom_big_pupper",        700,  480,  35,    3,   100,  34}
    },
    {
      {"npc_dota_neutral_satyr_tickster",           300,  160,  10,    1,    20,  11},
      {"npc_dota_neutral_satyr_soulstealer",        400,  480,  20,    1,    40,  20},
      {"npc_dota_neutral_satyr_hellcaller",         600,  480,  30,   1.5,   80,  31}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1600,    0,  50,    3,   166,  44}, --expected gold is 332 and XP is 86
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    2,    83,  20},
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    2,    83,  20}
    },
    {
      {"npc_dota_neutral_granite_golem",           1600,    0,  50,    3,   166,  44},
      {"npc_dota_neutral_granite_golem",           1600,    0,  40,    3,   166,  44}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",     1840,    0,  80,    3,   332,  86}
    }
  }
}
