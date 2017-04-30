
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               300,  0,    10,   1,    13,   54}, --expected gold is  65 and XP is 240
      {"npc_dota_neutral_kobold",               300,  0,    10,   1,    13,   54},
      {"npc_dota_neutral_kobold_taskmaster",    600,  0,    18,   2,    22,   70},
      {"npc_dota_neutral_kobold_tunneler",      425,  0,    14,   2,    17,   62}
    }
  },
    -- 2 "medium camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          750,  400,  40,   2,    24,   140}, --expected gold is 68 and XP is 360
      {"npc_dota_neutral_harpy_storm",          750,  400,  40,   2,    24,   140},
      {"npc_dota_neutral_harpy_scout",          550,  0,    50,   1,    20,    80},
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
      {"npc_dota_neutral_centaur_khan",         2200, 400,  70,   3,    66,   120},
      {"npc_dota_neutral_centaur_outrunner",    1500, 400,  50,   2,    46,   120},
    },
    {
      {"npc_dota_neutral_giant_wolf",           900,  200,  35,   4,    30,   110},
      {"npc_dota_neutral_giant_wolf",           900,  200,  35,   4,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           1800, 600,  100,   8,    90,   135}
    },
    {
      {"npc_dota_neutral_giant_wolf",           900,  200,  35,   4,    30,   110},
      {"npc_dota_neutral_alpha_wolf",           1800, 600,  100,   8,    90,   135}
    }
      -- {"npc_dota_neutral_jungle_stalker",       1600, 400,  55,   2,    61,   40},
  }
}
