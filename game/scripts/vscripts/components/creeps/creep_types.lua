
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  20}, --expected gold is 56 and XP is 61
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    36,  32}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    40,  45},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  20}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    40,  45},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  20}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    30,  31},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    30,  31}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   45, 155}, --expected gold is 75 and XP is 272
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   45, 155},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,   0.7,   14,  79},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,   1.2,   45, 155}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,   1.3,   38, 136},
      {"npc_dota_neutral_beardude",                 800,    0,  28,   1.3,   38, 136}
    }
  },
    -- 3 "hard camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   76,  61}, --expected gold is 113 and XP 121
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   37,  60},
    },
    {
      {"npc_dota_neutral_custom_big_horse",         800,  400,  30,   1.5,   76,  61},
      {"npc_dota_neutral_custom_small_horse",       600,  240,  20,   0.8,   37,  60},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    21,  30},
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    21,  30},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    85,  81}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    21,  30},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    85,  81}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",      400,  160,  15,    1,    21,  30},
      {"npc_dota_neutral_custom_big_pupper",        600,  480,  35,    2,    85,  81}
    },
    {
      {"npc_dota_neutral_satyr_tickster",           350,  160,  10,    1,    25,  27},
      {"npc_dota_neutral_satyr_soulstealer",        450,  480,  20,    1,    38,  40},
      {"npc_dota_neutral_satyr_hellcaller",         550,  480,  30,   1.5,   51,  53}
    }
  },
   -- 4 "ancient camp"
  {
    {                                               --HP  MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_granite_golem",           1400,    0,  50,    2,   122,  75}, --expected gold is 244 and XP is 151
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    61,  38},
      {"npc_dota_neutral_rock_golem",              1000,    0,  40,    1,    61,  38}
    },
    {
      {"npc_dota_neutral_prowler_acolyte",          900,    0,  30,    1,    82,  51},
      {"npc_dota_neutral_prowler_shaman",          1200,    0,  60,    2,   162, 100}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",     1700,    0,  80,    3,   244, 151}
    }
  },
   -- 5 "solo camp"
  {
    {
       {"npc_dota_neutral_black_drake",            1500,    0,  70,    3,   131, 212}
    }
  }
}
