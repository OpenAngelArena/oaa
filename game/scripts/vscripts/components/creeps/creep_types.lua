
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   48,  40}, --expected gold is 138 and XP is 98
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    75,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    81,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   48,  40}
    },
    {
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   48,  40},
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    75,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    81,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   48,  40}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    93,  60},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    93,  60}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   105,   71}, --expected gold is 195 and XP is 123
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   105,   71},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,    1,    78,   30},
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   140,   71}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,    2,    96,   63},
      {"npc_dota_neutral_blueberry",                800,    0,  28,    2,    96,   63},
    }
  },
    -- 3 "hard camp"
  {
    {                                          --HP   MANA   DMG   ARM  GOLD   EXP
      {"npc_dota_neutral_custom_big_horse",     1600, 400,   44,   3,   300,    49}, --expected gold is 504 and XP is 98
      {"npc_dota_neutral_custom_small_horse",   1200, 240,   28,   2,   204,    49},
    },
    {
      {"npc_dota_neutral_custom_big_horse",     1600, 400,   44,   3,   300,    49},
      {"npc_dota_neutral_custom_small_horse",   1200, 240,   28,   2,   204,    49},
    },
    {
      {"npc_dota_neutral_custom_big_horse",     1600, 400,   44,   3,   300,    49},
      {"npc_dota_neutral_custom_small_horse",   1200, 240,   28,   2,   204,    49},
    },
    {
      {"npc_dota_neutral_custom_big_horse",     1600, 400,   44,   3,   300,    49},
      {"npc_dota_neutral_custom_small_horse",   1200, 240,   28,   2,   204,    49},
    },
    {
      {"npc_dota_neutral_custom_small_pupper",   640, 160,   24,   3,   108,    36},
      {"npc_dota_neutral_custom_small_pupper",   640, 160,   24,   3,   108,    36},
      {"npc_dota_neutral_custom_big_pupper",    1200, 480,   56,   5,   360,    50}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",   640, 160,   24,   3,   108,    36},
      {"npc_dota_neutral_custom_big_pupper",    1200, 480,   56,   5,   360,    50}
    },
    {
      {"npc_dota_neutral_custom_small_pupper",   640, 160,   24,   3,   108,    36},
      {"npc_dota_neutral_custom_big_pupper",    1200, 480,   56,   5,   360,    50}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",  1840,   0,   80,   3,   504,    98},
    }
  }
}
