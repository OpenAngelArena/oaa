
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               450,  0,    12,   0.7,  17,   70}, --expected gold is  65 and XP is 240
      {"npc_dota_neutral_kobold_taskmaster",    900,  0,    24,   1.4,  27,   90},
      {"npc_dota_neutral_kobold_tunneler",      625,  0,    16,   1.4,  21,   80}
    }
  },
    -- 2 "medium camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          900,  400,  45,   2,    30,   170}, --expected gold is 68 and XP is 360
      {"npc_dota_neutral_harpy_storm",          900,  400,  45,   2,    30,   170},
      {"npc_dota_neutral_harpy_scout",          700,  0,    70,   1,    23,   105},
    }
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          900,  400,  45,   2,    30,   170}, --expected gold is 68 and XP is 360
      {"npc_dota_neutral_harpy_scout",          700,  0,    70,   1,    23,   105},
    }
  },
    -- 3 "hard camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_centaur_khan",         2200, 400,  70,   3,    66,   120}, --expected gold is 135 and XP is 300
      {"npc_dota_neutral_centaur_outrunner",    1500, 400,  50,   2,    46,   120},
      {"npc_dota_neutral_centaur_outrunner",    1500, 400,  50,   2,    46,   120},
    },
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_centaur_khan",         2200, 400,   70,   3,    66,   120},
      {"npc_dota_neutral_centaur_outrunner",    1500, 400,   50,   2,    46,   120},
    },
    {
      {"npc_dota_neutral_giant_wolf",           1000,  200,  35,   3,    30,   110},
      {"npc_dota_neutral_giant_wolf",           1000,  200,  35,   3,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           2000,  600, 100,   5,    90,   135}
    },
    {
      {"npc_dota_neutral_giant_wolf",           1000,  200,  35,   3,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           2000,  600, 100,   5,    90,   135}
    }
      {"npc_dota_neutral_black_dragon",         3000,    0, 150,   2,   135,   300},
  }
}
