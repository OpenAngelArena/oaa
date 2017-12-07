
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  20}, --expected gold is 70 and XP is 49
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    30,  30}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    44,  28},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  20}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    44,  28},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   14,  20}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    60,  25},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    60,  25}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  55}, --expected gold is 94 and XP is 98
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  55},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,    1,    32,  30},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    53,  55}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,    2,    47,  49},
      {"npc_dota_neutral_beardude",                 800,    0,  28,    2,    47,  49},
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_horse",        1200,  400,  30,    2,    90,  37}, --expected gold is 140 and XP is 74
      {"npc_dota_neutral_custom_small_horse",       800,  240,  20,    1,    50,  37},
    },
    {
      {"npc_dota_neutral_custom_big_horse",        1200,  400,  30,    2,    90,  37},
      {"npc_dota_neutral_custom_small_horse",       800,  240,  20,    1,    50,  37},
    },
    {
      {"npc_dota_neutral_custom_big_horse",        1200,  400,  30,    2,    90,  37},
      {"npc_dota_neutral_custom_small_horse",       800,  240,  20,    1,    50,  37},
    },
    {
      {"npc_dota_neutral_custom_big_horse",        1200,  400,  30,    2,    90,  37},
      {"npc_dota_neutral_custom_small_horse",       800,  240,  20,    1,    50,  37},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      640,  160,  15,    1,    30,  27},
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  27},
      {"npc_dota_neutral_custom_big_pupper",        800,  480,  35,    3,   100,  38}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  27},
      {"npc_dota_neutral_custom_big_pupper",        800,  480,  35,    3,   100,  38}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      420,  160,  15,    1,    30,  27},
      {"npc_dota_neutral_custom_big_pupper",        800,  480,  35,    3,   100,  38}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1600,    0,  50,    3,   166,  48}, --expected gold is 332 and XP is 98
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    2,    83,  26},
      {"npc_dota_neutral_rock_golem",              1200,    0,  40,    2,    83,  26}
    },
    {
      {"npc_dota_neutral_granite_golem",           1600,    0,  50,    3,   166,  48},
      {"npc_dota_neutral_granite_golem",           1600,    0,  40,    3,   166,  48}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",     1840,    0,  80,    3,   332,  98}
    }
  }
}
