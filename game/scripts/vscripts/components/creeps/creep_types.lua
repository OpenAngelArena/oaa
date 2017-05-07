
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                          --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               300,    0,  10,   0.5,   13,  54}, --expected gold is  65 and XP is 240
      {"npc_dota_neutral_kobold",               300,    0,  10,   0.5,   13,  54},
      {"npc_dota_neutral_kobold_taskmaster",    600,    0,  18,    1,    22,  70},
      {"npc_dota_neutral_kobold_tunneler",      450,    0,  14,    1,    17,  62}
    },
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_polar_furbolg_champion",   450,    0,  18,    1,    22,  70},
      {"npc_dota_neutral_tomato",                   900,    0,  14,    1,    17,  62}
    }
  },
    -- 2 "medium camp"
  {
    {                                          --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          600,  400,  30,    2,    24,  140}, --expected gold is 68 and XP is 360
      {"npc_dota_neutral_harpy_storm",          600,  400,  30,    2,    24,  140},
      {"npc_dota_neutral_harpy_scout",          450,    0,  40,    1,    20,   80},
    },
    {                                          --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_ghost",                600,    0,  35,   2,    34,   180},
      {"npc_dota_neutral_ghost",                600,    0,  35,   2,    34,   180},
    }
  },
    -- 3 "hard camp"
  {
    {                                          --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_centaur_khan",         1700, 400,   50,   3,    66,   120}, --expected gold is 135 and XP is 300
      {"npc_dota_neutral_centaur_outrunner",    1200, 400,   30,   2,    46,   120},
      {"npc_dota_neutral_centaur_outrunner",    1200, 400,   30,   2,    46,   120},
    },
    {                                          --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_centaur_khan",         1700, 400,   50,   3,    66,   120},
      {"npc_dota_neutral_centaur_outrunner",    1200, 400,   30,   2,    46,   120},
    },
    {
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    30,   110},
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           1500, 600,   70,   5,    90,   135}
    },
    {
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           1500, 600,   70,   5,    90,   135}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",  2300,   0,  100,   3,   135,   300},
    }
  }
}
