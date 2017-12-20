
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  19}, --expected gold is 41 and XP is 47
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    20,  29}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    30,  27},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  19}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    30,  27},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  19}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    27,  24},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    27,  24}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   30,  60}, --expected gold is 55 and XP is 109
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   30,  60},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,   0.7,   11,  35},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   30,  60}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,   1.3,   32,  56},
      {"npc_dota_neutral_beardude",                 800,    0,  28,   1.3,   32,  56},
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   50,  39}, --expected gold is 82 and XP is 78
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   32,  39},
    },
    {
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   50,  39},
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   32,  39},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    12,  27},
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    12,  27},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    66,  42}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    12,  27},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    66,  42}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    12,  27},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    66,  42}
    },
    {
      {"npc_dota_neutral_satyr_tickster",           350,  160,  10,    1,    14,  15},
      {"npc_dota_neutral_satyr_soulstealer",        450,  480,  20,    1,    24,  25},
      {"npc_dota_neutral_satyr_hellcaller",         550,  480,  30,   1.5,   44,  38}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1400,    0,  50,    2,    96,  56}, --expected gold is 191 and XP is 109
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    47,  25},
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    47,  25}
    },
    {
      {"npc_dota_neutral_granite_golem",           1400,    0,  50,    2,    96,  56},
      {"npc_dota_neutral_granite_golem",           1400,    0,  40,    2,    96,  56}
    },
    {
      {"npc_dota_neutral_prowler_acolyte",          900,    0,  30,    1,    63,  36},
      {"npc_dota_neutral_prowler_shaman",          1200,    0,  60,    2,   128,  73}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",     1700,    0,  80,    3,   191, 109}
    }
  }
}
