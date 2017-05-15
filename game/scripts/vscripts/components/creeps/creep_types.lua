
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   350,    0,  13,   0.5,   14,  70}, --expected gold is  46 and XP is 240
      {"npc_dota_neutral_kobold_tunneler",          600,    0,  15,    1,    22, 120}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        700,    0,  20,    1,    26, 140},
      {"npc_dota_neutral_kobold",                   350,    0,  13,   0.5,   14,  70}
    },
    {
      {"npc_dota_neutral_ghost",                    600,    0,  15,    1,    31, 160},
      {"npc_dota_neutral_ghost",                    600,    0,  15,    1,    31, 160}
    }
  },
    -- 2 "medium camp"
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              700,  400,  30,    2,    35,  175}, --expected gold is 65 and XP is 300
      {"npc_dota_neutral_harpy_storm",              700,  400,  30,    2,    35,  175},
      {"npc_dota_neutral_harpy_scout",              550,    0,  50,    1,    26,   75},
    },
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              700,  400,  30,    2,    35,  175}
    },
    {
      {"npc_dota_neutral_polar_fulborg_champion",   600,    0,  35,    2,    32,  150},
      {"npc_dota_neutral_tomato",                  1000,    0,  35,    2,    32,  150},
    }
  },
    -- 3 "hard camp"
  {
    {                                          --HP   MANA   DMG   ARM  GOLD   EXP
      {"npc_dota_neutral_centaur_khan",         2000, 500,   55,   3,   100,   120}, --expected gold is 168 and XP is 240
      {"npc_dota_neutral_centaur_outrunner",    1500, 300,   35,   2,    68,   120},
    },
    {                                          --HP   MANA   DMG   ARM  GOLD   EXP
      {"npc_dota_neutral_centaur_khan",         2000, 500,   55,   3,   100,   120},
      {"npc_dota_neutral_centaur_outrunner",    1500, 300,   35,   2,    68,   120},
    },
    {
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    32,    88},
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    32,    88},
      {"npc_dota_neutral_alpha_wolf",           1500, 600,   70,   5,   120,   108}
    },
    {
      {"npc_dota_neutral_giant_wolf",            800, 200,   30,   3,    32,    88},
      {"npc_dota_neutral_alpha_wolf",           1500, 600,   70,   5,   120,   108}
    },
    {
      {"npc_dota_neutral_custom_black_dragon",  2300,   0,  100,   3,   168,   240},
    }
  }
}
