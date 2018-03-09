
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,    5,  30}, --expected gold is 19 and XP is 91
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,     9,  52}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    14,  65},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,    5,  30}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    14,  65},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,    5,  30}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    12,  46},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    12,  46}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   33, 118}, --expected gold is 56 and XP is 212
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   33, 118},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,   0.7,   11,  70},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   33, 118}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,   1.3,   29, 106},
      {"npc_dota_neutral_beardude",                 800,    0,  28,   1.3,   29, 106}
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   74,  76}, --expected gold is 113 and XP is 151
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   39,  75},
    },
    {
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   74,  76},
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   39,  75},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    20,  39},
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    20,  39},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    86,  99}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    20,  39},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    86,  99}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    33,  39},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    86,  99}
    },
    {
      {"npc_dota_neutral_satyr_tickster",           350,  160,  10,    1,    28,  35},
      {"npc_dota_neutral_satyr_soulstealer",        450,  480,  20,    1,    38,  51},
      {"npc_dota_neutral_satyr_hellcaller",         550,  480,  30,   1.5,   48,  65}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1400,    0,  50,    2,    94, 106}, --expected gold is 188 and XP is 212
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    47,  53},
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    47,  53}
    },
    {
      {"npc_dota_neutral_prowler_acolyte",          900,    0,  30,    1,    63,  71},
      {"npc_dota_neutral_prowler_shaman",          1200,    0,  60,    2,   125, 141}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",     1700,    0,  80,    3,   188, 212}
    }
  }
}
