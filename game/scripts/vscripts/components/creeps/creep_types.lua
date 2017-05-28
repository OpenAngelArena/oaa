
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  40}, --expected gold is  46 and XP is 98
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    25,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    27,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  40}
    },
    {
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  40},
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    25,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    27,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   16,  40}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    31,  60},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    31,  60}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    35,   71}, --expected gold is 65 and XP is 123
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    35,   71},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,    1,    26,   30},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,    35,   71}
    },
    {
      {"npc_dota_neutral_polar_fulborg_champion",   480,    0,  28,    2,    32,   63},
      {"npc_dota_neutral_tomato",                   800,    0,  28,    2,    32,   63},
    }
  },
    -- 3 "hard camp"
  {
    {                                          --HP   MANA   DMG   ARM  GOLD   EXP
      {"npc_dota_neutral_centaur_khan",         1600, 400,   44,   3,   100,    49}, --expected gold is 168 and XP is 98
      {"npc_dota_neutral_centaur_outrunner",    1200, 240,   28,   2,    68,    49},
    },
    {
      {"npc_dota_neutral_centaur_khan",         1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_centaur_outrunner",    1200, 240,   28,   2,    68,    49},
    },
    {
      {"npc_dota_neutral_centaur_khan",         1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_centaur_outrunner",    1200, 240,   28,   2,    68,    49},
    },
    {
      {"npc_dota_neutral_centaur_khan",         1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_centaur_outrunner",    1200, 240,   28,   2,    68,    49},
    },
    {
      {"npc_dota_neutral_giant_wolf",            640, 160,   24,   3,    36,    36},
      {"npc_dota_neutral_giant_wolf",            640, 160,   24,   3,    36,    36},
      {"npc_dota_neutral_alpha_wolf",           1200, 480,   56,   5,   120,    50}
    },
    {
      {"npc_dota_neutral_giant_wolf",            640, 160,   24,   3,    36,    36},
      {"npc_dota_neutral_alpha_wolf",           1200, 480,   56,   5,   120,    50}
    },
    {
      {"npc_dota_neutral_giant_wolf",            640, 160,   24,   3,    36,    36},
      {"npc_dota_neutral_alpha_wolf",           1200, 480,   56,   5,   120,    50}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",  1840,   0,   80,   3,   168,    98},
    }
  }
}
