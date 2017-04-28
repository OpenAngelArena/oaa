
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
CreepTypes = {
  -- 1 "easy camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",               240,  0,    10,   1,    10,   40},
      {"npc_dota_neutral_kobold",               240,  0,    10,   1,    10,   40},
      {"npc_dota_neutral_kobold_taskmaster",    400,  0,    14,   2,    16,   56},
      {"npc_dota_neutral_kobold_taskmaster",    400,  0,    14,   2,    16,   56},
      {"npc_dota_neutral_kobold_tunneler",      325,  0,    14,   2,    13,   48}
    }
  },
    -- 2 "medium camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    18,   100},
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    18,   100},
      {"npc_dota_neutral_harpy_storm",          550,  400,  33,   2,    18,   100},
      {"npc_dota_neutral_harpy_scout",          400,  0,    31,   1,    14,    60},
    }
  },
    -- 3 "hard camp"
  {
    {                                         --HP    MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_centaur_khan",         2000, 400,  62,   2,    55,   100},
      {"npc_dota_neutral_centaur_outrunner",    1000, 400,  44,   2,    40,   100},
      {"npc_dota_neutral_centaur_outrunner",    1000, 400,  44,   2,    40,   100},
    },
    {
      {"npc_dota_neutral_giant_wolf",           800,  400,  31,   4,    30,    95},
      {"npc_dota_neutral_giant_wolf",           800,  400,  31,   4,    30,    95},
      {"npc_dota_neutral_alpha_wolf",           1700, 600,  82,   8,    75,   110}
    }
      -- {"npc_dota_neutral_jungle_stalker",       1600, 400,  55,   2,    61,   40},
  }
}
